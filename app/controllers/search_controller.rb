class SearchController < ApplicationController

	# recherche le terme donnée dans les séries et items
  def keyword
	@keyword = params[:keyword]
	@series = Series.search(params[:keyword], params[:category_id]).limit(50)

	# Poursuite de la recherche dans les items
	@items = Item.search(params[:keyword]).limit(50)

	 respond_to do |format|
         format.html
         format.json { render json: { keyword: @keyword, category_id: params[:category_id], series: @series}  }
     end
  end

end
