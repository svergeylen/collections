class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :edit, :update, :destroy]

  # Uniquement les root tags
  def index
    @title  = "Collector"
    session[:active_tags] = []
    @root_tags = Tag.where(root_tag: true).order(name: :asc)

    # Recherche de dossiers potentiellement orphelins (suppression de leur parent ou erreur database)
		all_tags = Tag.where(root_tag: false).map(&:id)
		all_tags_with_parent = Ownertag.where(owner_type: "Tag").map(&:tag_id)
		orphan_ids = all_tags - all_tags_with_parent
		@orphans = Tag.find(orphan_ids)

  end

  # Affichage d'un seul tag, de ses tags enfants ou des items qu'il contient
  def show
    
    @tag = Tag.find(params[:id])

    if @tag 
      # Ajout du tag actif dans la liste sans faire de doublon
      if session[:active_tags].nil?
        session[:active_tags] = [ @tag.id ]
      else
        session[:active_tags] = session[:active_tags] + [ @tag.id ] unless session[:active_tags].include?(@tag.id)
      end

      @active_tags = Tag.find(session[:active_tags])

      @children = @tag.children

      # Si le tag a des enfants, il faut afficher les tags enfants (navigation)
      # Si le tag n'a plus d'enfant, on peut afficher les items.
      if @children.empty?

        @items = Item.having_tags(session[:active_tags])

        # Choix de la vue 
        if params[:view].present?
          @view = params[:view]
        else
          if @tag.default_view.blank?
            @view = "list"
          else
            @view = @tag.default_view
          end 
        end

      end

      # Formulaire d'ajout d'item en bas de page
      @new_item = Item.new

    # Breadcrumbs : Si un chemin de tags est donné en parametre, l'utiliser et le mémoriser
    # Permet de forcer la navigation vers un Tag avec un chemin particulier
    # if params[:bc].present?
    #   bc = params[:bc].split(",")
    #   set_session_breadcrumbs(bc)
    # else
    #   # On n'a pas de breadcrumbs imposées
    #   bc = get_session_breadcrumbs
    #   if bc.empty?
    #     # On initialise les breadcrumbs au tag en cours
    #     set_session_breadcrumbs([ @tag.id.to_s ])
    #   else 
    #     # On complète la liste des breadcrumbs avec le tag courant (sauf si identique = page refresh )
    #     bc << @tag.id if !bc.include? @tag.id
    #     set_session_breadcrumbs(bc)
    #   end
    # end    

    end  #if @tag
  end

  def new
    @tag = Tag.new
    
    # Cherche des tags à proposer pour populer le champ parent_tags
    # proposal = Tag.where(id: get_session_breadcrumbs).where(optional: false).map(&:id)
    # On propose uniquement le premier parent pour éviter la confusion...
    # sinon, on se retrouve avec l'item à tous les niveaux de la hiérarchie (c'est nul)
    @tag.parent_tag_ids = [ params[:parent_tag].to_s ]
  end

  def create
    @tag = Tag.new(tag_params)
    
    if @tag.save
      @tag.update_parent_tags(params[:tag][:parent_tags])
			if @tag.root_tag?
				redirect_to tags_path, notice: "Tag créé"
			else
				redirect_to @tag, notice: 'Tag créé' 
			end
    else
      render :new 
      # ICI BUG : lorsqu'il y a une erreur de validation, on perd la valeur de @tag.parent_tag_ids ???
    end
  end

  def edit
    @tag = Tag.find(params[:id])
  end

  def update
    @tag = Tag.find(params[:id])
    @tag.update_parent_tags(params[:tag][:parent_tags])
    
    if @tag.update(tag_params)
      redirect_to @tag, notice: 'Dossier modifié'
    else
      render :edit
    end
  end

  def destroy
    # BUG : Il faut prévoir le déplacement des tags enfants qui deviennent orphelins vers root_tag=true
    if @tag.destroy
      redirect_to tags_path, notice: "Tag supprimé"
    else
      redirect_to tags_path, alert: "Ce Tag ne peut pas être supprimé"
    end
  end


  private
  
  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :root_tag, :fixture, :optional, :letter, :default_view, :view_alphabet)
  end

end
