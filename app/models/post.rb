class Post < ApplicationRecord
	belongs_to :user
	has_many :comments, dependent: :destroy

	has_many :attachments, as: :element, :dependent => :destroy
	accepts_nested_attributes_for :attachments

	acts_as_votable # les users peuvent liker des posts

	before_validation :check_user_exists

	# Supprime toute mémorisation d'un lien ou d'un identifiant youtube dans le post
	def remove_preview
		self.preview_url = nil
		self.preview_title = nil
		self.preview_description = nil
		self.preview_image_url = nil
		self.youtube_id = nil
		self.save
	end

	# Incrémente le vote pour l'utiliateur donné
	def increment_vote(user)
		# Recherche d'un vote existant
	    vote = self.find_votes_for(voter: user)
	    if vote.blank?
	      # Si c'est le premier vote, création d'un vote "1"
	      self.vote_by(voter: user, vote_weight: 1)
	    else
	      # Si c'est le second vote (ou plus), on incrémente le weight du vote existant
	      next_score = vote.first.vote_weight + 1
	      self.vote_by(voter: user, vote_weight: next_score)
	    end
	end

	# Donne le nombre de votes total posotifs
	def total_upvotes
		self.get_upvotes.sum(:vote_weight)
	end

	private

	def check_user_exists
		return User.exists?(self.user_id)
	end
end
