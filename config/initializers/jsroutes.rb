

JsRoutes.setup do |config|
	# Nouvelle route : 	rake tmp:cache:clear
	# 					rails s
	config.include = [
		/^upvote_item$/
	]

end
