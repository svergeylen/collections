module ApplicationHelper

	# Affiche le nom de la dernière catégorie choisie (current)
	def link_to_current_category
		cat = Category.find(session[:category])
		return link_to(cat.name, category_path(cat) )
	end

	# Renvoie une date courte en français
	def format_date(mydate) 
		
		case mydate.strftime("%m")
			when "01"
				mois = "janvier"
			when "02"
				mois = "février"
			when "03"
				mois = "mars"
			when "04"
				mois = "avril"
			when "05"
				mois = "mai"
			when "06"
				mois = "juin"
			when "07"
				mois = "juillet"
			when "08"
				mois = "août"
			when "09"
				mois = "septembre"
			when "10"
				mois = "octobre"
			when "11"
				mois = "novembre"
			when "12"
				mois = "décembre"
			else
				mois = "inconnu"
			end

		return mydate.strftime("%d") + " " + mois.capitalize + " " + mydate.strftime("%y")
	end


end
