class ItemsController < ApplicationController
  before_action :set_item, only: [:show, :edit, :update, :destroy, :upvote, :plus, :minus]

  # Liste des items pour gestion banque de données
  def index
    per_page = 40
    case params[:mode]
      when "Orphelins"
        item_ids_having_tags = Ownertag.all.group(:owner_id).where(owner_type: 'Item').pluck(:owner_id)
        @items = Item.where.not(id: item_ids_having_tags).order(:name).paginate(page: params[:page], per_page: per_page)
      else
        @items = Item.includes(:tags).order(name: :asc).paginate(page: params[:page], per_page: per_page)
    end
  end

  # GET /items/1
  # GET /items/1.json
  def show
    # Test download
    #  require 'open-uri'
    #  game_name = @item.name.downcase
    #  filename = "/home/stephane/www/collector/tmp/page.html"
    #  download = open('https://www.trictrac.net/jeu-de-societe/'+game_name)
    #  IO.copy_stream(download, filename)

    # # # Tests parsing
    #  @html_doc = File.open(filename) { |f| Nokogiri::HTML(f, &:noblanks) }
    #  @image_src = @html_doc.at_css("#img-game").attributes["src"]
    #  @content = @html_doc.at_css("#content-column")

    # Ajout d'information pour la création d'un item du même type....
    next_number = (@item.number + 1) if @item.number.present?
    proposed_tag_ids = @item.tags.pluck(:id)
    item_type = @item.item_type
    @new_item_options = {number: next_number, item_type: item_type, tag_ids: proposed_tag_ids}

  end

  # GET /items/new
  def new
    @item = Item.new
    @item.number = params[:number] if (params[:number].present?)

    @item_types = Item.item_types.collect { |t| [t[1], t[0]] } # @item_types[:item] renvoie "Item (générique)"

    # Recheche du meilleur item_type possible, en fonction de params ou des tags actifs
    @item.item_type = params[:item_type] if params[:item_type].present?
    
    
    # On affiche le formulaire qui dépend de l'item_type (si le type est donné en paramètre)
    case params[:item_type]
    when "bd"
      new_or_edit_bd
      
      # Sélection des tags proposés par params[:tag_ids] pour chauque champ de formulaire
      proposed_tags = Tag.includes(:parent_tags).where(id: params[:tag_ids])
      @item.tag_series     = proposed_tags.select{ |t| t.parent_tags.include?(Tag.find_by(name: "Séries")) }.pluck(:name).join(",")
      @item.tag_auteurs    = proposed_tags.select{ |t| t.parent_tags.include?(Tag.find_by(name: "Auteurs")) }.pluck(:name).join(",")
      @item.tag_rangements = proposed_tags.select{ |t| t.parent_tags.include?(Tag.find_by(name: "Rangements")) }.pluck(:name).join(",")

      render "items/new_bd"
    # On affiche le formulaire d'items par défaut
    else
      @tag_list = Tag.order(name: :asc).pluck(:name)
      @item.tag_names = Tag.where(id: session[:active_tags]).pluck(:name).join(", ")
      render "items/new"
    end
  end


  # GET /items/1/edit
  def edit
    @item_types = Item.item_types.collect { |t| [t[1], t[0]] }
    # On change le type d'item si c'est forcé dans l'URL (via modification du champ <select> )
    @item.item_type = params[:item_type] if params[:item_type].present?
    # Quantité
    @quantity = @item.quantity_for(current_user.id)

    # On affiche le formulaire correspondant au type d'item (éventuellement modifié ci-dessus)
    case @item.item_type
      when "bd"
        new_or_edit_bd
        render "items/edit_bd"
      else
        @tag_list = Tag.order(name: :asc).pluck(:name)
        render "items/edit"
    end
  end

  # POST /items
  # POST /items.json
  def create
    @item = Item.new(item_params)
    @item.adder_id = current_user.id

    if @item.save
      # Si l'utilisateur coche l'option "ajouter à ma collection", on ajoute cet élément directement.
      if params[:add_to_collection].present?
        current_user.add_to_collection(@item.id)
      end
      # Enregistre les pièces jointes (photos)
      save_attachments
      # Crée un job pour l'affichage ultérieur sur La Une
      Job.create(action: "add_item", element_id: @item.id, element_type: "Item", user_id: current_user.id)      

			redirect_to last_tag_path, notice: 'Elément ajouté'
    else
      @item_types = Item.item_types
			render :new 
    end
  end

  # PATCH/PUT /items/1
  # PATCH/PUT /items/1.json
  def update
    @item.adder_id = current_user.id if @item.adder_id.blank? # défensif

    if @item.update(item_params)
      save_attachments

      redirect_to @item, notice: 'Elément mis à jour'
    else
      @item_types = Item.item_types.collect { |t| [t[1], t[0]] }
      render :edit 
    end
  end


  # Gestion des quantités (Composant React ItemQuantity)
  def quantity
    @item = Item.find(params[:id])
    @iu = @item.update_quantity(params[:delta], current_user.id)
    render partial: "items/quantity.json.jbuilder", locals: {item: @item}
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    @item.destroy
    redirect_back fallback_location: welcome_collector_path, notice: 'Elément supprimé'
  end

  # Gestion des actions réalisées sur une liste d'items.
  # params contient la liste des item_id qu'il faut modifier
  def actions 
    if params[:item_ids].nil?
      redirect_to tag_path(params[:tag_id], view: params[:view]), alert: 'Veuillez sélectionner des éléments'
    else

      # On ajoute les items sélectionnés dans la collection de l'utilisateur courant
      if params[:add_to_collection].present?
        params[:item_ids].each do |item_id|
          current_user.add_to_collection(item_id, 1)
        end
        redirect_to tag_path(params[:tag_id], view: params[:view]), notice: 'Eléments ajoutés à ma collection'
      end

      # On enlève les items sélectionnés des possessions de l'utilisateur courant
      if params[:remove_from_collection].present?
        params[:item_ids].each do |item_id|
          current_user.add_to_collection(item_id, -1)
        end
        redirect_to tag_path(params[:tag_id], view: params[:view]), notice: 'Eléments enlevés de ma collection'
      end

      # On enlève les items sélectionnés des possessions de l'utilisateur courant
      if params[:destroy].present?
        Item.where(id: params[:item_ids]).destroy_all
        redirect_to tag_path(params[:tag_id], view: params[:view]), notice: 'Eléments supprimés du Collector'
      end

      # On écrase le rangement des items donnés vers le(s) nouveaux rangement(s) donné(s)
      if params[:move].present?
        result = true
        params[:item_ids].each do |item_id|
          i = Item.find(item_id)
          result = i.update_tags_with_parent(params[:rangements].split(","), "Rangements") && result
        end
        if result
          redirect_to tag_path(params[:tag_id], view: params[:view]), notice: 'Rangement modifié pour les items sélectionnés'
        else
          redirect_to tag_path(params[:tag_id], view: params[:view]), alert: 'Erreur lors de la modification du rangement'
        end
      end

      # On ajoute le(s) tag(s) donné(s) aux items sélectionnés
      if params[:add_tag].present?
        params[:item_ids].each do |item_id|
          i = Item.find(item_id)
          result = i.add_tags(params[:tag_names].split(","))
        end
        redirect_to tag_path(params[:tag_id], view: params[:view]), notice: 'Tag(s) ajouté(s) aux items sélectionnés'
      end

      # On supprimer un même tag des items sélectionnés
      if params[:remove_tag].present?
        params[:item_ids].each do |item_id|
          i = Item.find(item_id)
          result = i.remove_tags(params[:tag_names].split(","))
        end
        redirect_to tag_path(params[:tag_id], view: params[:view]), notice: 'Tag(s) retirés(s) des items sélectionnés'
      end

    end # if item_ids.empty?
  end

  # Supprimer un attachment de l'item
  def delete_attachment
    @item = Item.find(params[:id])
    if @item.attachments.exists?(params[:attachment_id])
      @item.attachments.find(params[:attachment_id]).destroy
      redirect_to edit_item_path(@item), notice: 'Pièce jointe supprimée' 
    else
      redirect_to edit_item_path(@item), alert: 'Erreur lors de la suppression de la pièce jointe' 
    end
  end


  private
    # Sauvegarde les attachments s'il y en a
    def save_attachments
      # Paperclip multiple upload of attachments on Item
      if params[:item][:attachments]
        params[:item][:attachments].each { |attach|
          @item.attachments.create(image: attach, user_id: current_user.id)
        }
      end
    end

    # Méthodes utilisées par les 2 formulaires spécifiques aux BD : new + edit
    def new_or_edit_bd
      tag_series = Tag.find_or_create_by(name: "Séries")
      @series_list = tag_series.children.pluck(:name)

      tag_auteurs = Tag.find_or_create_by(name: "Auteurs")
      @auteurs_list = tag_auteurs.children.pluck(:name)

      tag_rangement = Tag.find_or_create_by(name: "Rangements")
      @rangements_list = tag_rangement.children.pluck(:name)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params[:id])
      rescue ActiveRecord::RecordNotFound
      redirect_to items_path, alert: "Cet item n'existe plus dans la banque de données"
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def item_params
      params.require(:item).permit(:number, :name, :item_type, :description, :attachments, :tag_names, :tag_series, :tag_auteurs, :tag_rangements)
    end
end
