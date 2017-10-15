class UsersController < ApplicationController
	def show
  		@user = User.find(params[:id])
  		@months_quantity = 6
  		@items = @user.items.where(created_at: (Date.current-@months_quantity.months)..Date.current).order(created_at: :desc)
	end

	# Supprmier l'image de profil
	def delete_profile_picture
		logger.debug current_user.id
		logger.debug params[:id]
		if (current_user.id == params[:id].to_i) 
			logger.debug "egaux"
			current_user.avatar = nil
			current_user.save
			redirect_to current_user, notice: "Image de profil supprimée"
		else 
			logger.debug "different"
			redirect_to current_user, error: "Vous ne pouvez pas supprimer l'avatar d'un autre utilisateur"
		end

	end
end
