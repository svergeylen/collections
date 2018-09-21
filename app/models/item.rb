class Item < ApplicationRecord
	enum rails_view: [ :general, :bd]

	has_many :ownertags,    dependent:  :destroy, as: :owner
	has_many :tags,         through:    :ownertags
	accepts_nested_attributes_for :tags

	has_many :itemusers
	has_many :users,        through:    :itemusers
	belongs_to :adder,      class_name: "User"

	has_many :attachments,  as:         :element,   dependent: :destroy
	accepts_nested_attributes_for :attachments

	acts_as_votable # les users peuvent mettre des likes sur les items
	
	validates :name, presence: true
	validates :adder_id, presence: true

	# Temporaire pour la migration de l'ancien site.
	# Ajout d'un lien vers l'ancienne table items_tags pour lire les auteurs des BD !
	has_and_belongs_to_many :old_tags, source: :items_tags, class_name: 'Tag'

	# --------------------- TAGS ---------------------------------------------------------------------------

	attr_writer :tag_names
	before_save :save_tags

	# Donne la liste de tags de l'item au format string séparé par une virgule
	def tag_names
		@tag_names || tags.pluck(:name).join(", ")
	end

	# Before_save : Sauvegarde les tags donnés dans une liste de string séparée par des virgule en objets Tag
	def save_tags
		if @tag_names
			tags = []
			@tag_names.split(",").each do |name| 
				name = name.strip
				next if name==""
				tags << Tag.where(name: name).first_or_create!
			end
			self.tags = tags
		end
	end

	# Renvoie les tags de l'item après avoir soustrait les active tags
	def different_tags(active_tag_ids)
		ids = self.tag_ids - active_tag_ids
		return Tag.find(ids)
	end

	# Renvoie les Items correspondants à l'array de tag_ids donné
	def self.having_tags(ar_tags)
  	# On sélectionne dans les tags donnés uniquement ceux qui doivent filtrer les items
  	applicable_tag_ids = Tag.where(id: ar_tags).where(filter_items: true).pluck(:id)
  	# On sélectionne les items qui correspondent à ces tags filtrants en comptant si chaque item est repris autant de fois que le nombre de tags filtrants donné
  	# Si il y a deux tags filtrants donnés, il faut que ownertags contiennent 2 lignes pour cet item (une ligne pour chaque tag différent)
  	ownertags = Ownertag.where(tag_id: applicable_tag_ids, owner_type: "Item").group(:owner_id).count.select{|owner_id, value| value >= applicable_tag_ids.size }
  	# On charge les items correspondants aux lignes trouvées dans ownertags
  	Item.where(id: ownertags.keys)  	
	end

	# Renvoie seulement les tags d'un item pour un parent spécifique donné
	def tags_with_parent(parent_tag)
		# TODO Performance moyenne : boucle sur chaque tag avec un sous requete... a améliorer
		return self.tags.select { |t| t.parent_tags.include?(parent_tag) }
	end

	# Met à jour les tags de l'item, mais uniquement les tags qui sont dans le parent donné
	def update_tags_with_parent(array_tag_names, parent_tag)
		# On crée deux listes de string contenant les tags à comparer
		current_tag_names   = self.tags_with_parent(parent_tag).map(&:name)
		
		new_tag_names = array_tag_names.present? ? array_tag_names.map{ |el| el.strip } : []
		
		# On réalise la différence entre les tags existants et nouveaux --> à ajouter à l'item
		names_to_create = new_tag_names - current_tag_names
		created_tags = parent_tag.create_children(names_to_create)
		logger.debug ("---created_tags -->" + created_tags.inspect)
		self.tags << created_tags
		
		# On réalise la différence entre les tags existants et ceux retirés dans la liste --> à supprimer de l'item
		names_to_destroy = current_tag_names - new_tag_names
		logger.debug (" current_tag_names --->"+current_tag_names.inspect)
		logger.debug (" new_tag_names --->"+new_tag_names.inspect)
		logger.debug (" names_to_destroy --->"+names_to_destroy.inspect)
		self.tags.destroy(Tag.where(name: names_to_destroy))
		# names_to_destroy automatiquement désassociés de l'item via le destroy

	end


	# ------------------ POSSESSION de l'ITEM ----------------------------------------------------------------

	# Renvoie true si l'utilisateur possède cet item
	def is_owned_by?(user_id)
		return self.itemusers.collect(&:user_id).include?(user_id)
	end

	# Renvoie le Itemuser de l'utilisateur donné
	def iu(user_id)
		return self.itemusers.where(user_id: user_id).limit(1).first
	end

	# Renvoie le nombre d'items identiques possédés par l'utilisateur donné
	def quantity_for(user_id)
		iu = self.iu(user_id)
		if iu.present?
			return iu.quantity
		else
			return 0
		end
	end

	# Modifie la quantité posédée par l'utilisateur donné
	def update_quantity(value, user_id)
		delta = value.to_i
		iu = self.iu(user_id)
    if iu.present?
      iu.quantity = [ (iu.quantity + delta), 0].max
      iu.save
    else
    	# Si l'utilisateur n'a pas l'item ET que l'on veut diminuer la quantité... autant ne rien faire
    	if (delta > 0)
      		iu = Itemuser.create!(item_id: self.id, user_id: user_id, quantity: delta)
      	end
    end
    return iu
	end


	# --------------------  CHAMPS de l'ITEM -------------------------------------------------------------

	# Renvoie le string du numéro de l'item (integer ou float suivant les cas)
	def friendly_number
		if self.number.present?
			if (self.number.round(0) == self.number)
				ret = self.number.round(0).to_s
			else
				ret = self.number.to_s
			end
		end
		return ret
	end


	# --------------------------- RECHERCHE -------------------------------------------------------------

	# Recherche les items contenant le mot clé donné
	def self.search(keyword)
		if keyword.present?
		  where('name LIKE ?', "%#{keyword}%").order(name: :asc)
		else
		  all
		end
	end
end
