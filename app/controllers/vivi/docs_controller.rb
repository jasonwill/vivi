module Vivi
  class DocsController < ApplicationController
    before_filter :find_doc,  :only => [:show, :edit, :update, :destroy, :download, :embed]
    before_filter :find_all_albums, :only => [:show, :edit, :index]
    before_filter :find_open_avail_albums, :only => [:show]
    before_filter :find_all_helptips, :only => [:show, :edit, :new]
    before_filter :find_all_rights, :only => [:show, :edit, :new]

    layout 'application'
    #before_filter do |controller|
    #  if controller.action_name == 'embed'
    #    layout 'embed'
    #  elsif controller.action_name == 'explore'
    #    layout 'home'
    #  else  
    #    layout 'docs'
    #  end
    #end

    def index                          
      #sort_init 'created_at'
      #sort_update

      #if params[:sort_key]
      #  list_sort_clause = sort_clause
      #else
      #  list_sort_clause = 'docs.created_at DESC'
      #end

      @media_view = 'wall'

      if params[:person_id]
        if params[:v]
          @media_view = params[:v] != '' ? params[:v] : 'wall'
          session[:media_view] = @media_view
        else
          @media_view = session[:media_view] ? session[:media_view] : 'wall'
          session[:media_view] = @media_view
        end
      end

      #per_page = @media_view=='wall' ? 130 : 15

      if params[:person_id] # Your Docs   
        @docs = Doc.where(:created_by => params[:person_id]).includes(:metadata,:creators).includes(:taggings,:tag).order('docs.created_at DESC')
      else       
        @docs = Doc.order('created_at DESC')
       
        #@docs = Doc.includes(:metadata,:creators).includes(:taggings,:tag).order('docs.created_at DESC')
        #logger.debug(shared_current_user.inspect)
        #@docs = shared_current_user.admin? ? @docs : @docs.where("metadatas.publish_status!='private'")
      end  

      @person = (params[:person_id] ? User.find(params[:person_id]) : nil)

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @all_docs }
      end
    end

    def explore
      @docs = Doc.find(:all, :select => 'DISTINCT docs.*', :joins => :metadata, :conditions => ["metadatas.publish_status != 'private'"], :order => "RAND()", :limit => 60)

      respond_to do |format|
        format.html
        format.xml  { render :xml => @docs }
      end

    end 

    def show
      @doc.build_metadata if @doc.metadata.nil?
      @doc.metadata.creators.build if @doc.metadata.creators.empty?

      if !(@doc.created_by.nil? or  @doc.created_by == 0)  
        creator = User.find(@doc.created_by)
        @created_by_name = find_username_by_id(@doc.created_by)
      end

      #@next_in_queue = Doc.all(:select => "id", :conditions => ["approved is false"], :order => "submitted_at DESC", :limit => 1).collect(&:id)

      @doc_albums = @doc.albums.sort! { |a,b| b.created_at <=> a.created_at } unless !@doc.albums
      @user_star_id = User.find_by_id(shared_current_user.ir_id).stars.find_by_starrable_id(@doc.id) 

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @doc }
      end

    end

    def new
      @doc = Doc.new

      @doc.build_metadata if @doc.metadata.nil? 
      @doc.metadata.creators.build if @doc.metadata.creatorings.empty?

      #Check to see if method is being called from a remote embedded form
      @remote = params[:remote]

      if @remote 
        @doc.ext_ref = params[:ext_ref].present? ? params[:ext_ref] : ''
        @doc.ext_source_name = params[:ext_src].present? ? params[:ext_src] : ''
        @doc.title = params[:title].present? ? params[:title] : ''
        @doc.metadata.publish_status = params[:publish].present? ? params[:publish] : ''
      end

      @pre_tag = params[:tag].present? ? params[:tag] : ''


      respond_to do |format|
        format.html { render :layout => 'external' if @remote}
        format.xml  { render :xml => @doc }
      end

    end

    def edit
      @doc.build_metadata if @doc.metadata.nil? 
      if !@doc.metadata.creatorings.empty?
        if (@doc.metadata.creatorings.first.creator_id.nil? or @doc.metadata.creatorings.first.creator_id == 0)
          @doc.metadata.creatorings.first.destroy
        end
      end
      @doc.metadata.creators.build if @doc.metadata.creatorings.empty?

      @remote = params[:remote]

      respond_to do |format|
        format.html { render :layout => 'external' if @remote}
        format.xml  { render :xml => @doc }
      end

    end

    def create   
      if (params[:doc]['assets_zip'].present?)
        respond_to do |format|
          if (create_docs_from_zip(params[:doc]['assets_zip'],params[:doc]['title'],nil))
            flash[:notice] = 'Docs were successfully created.'
            format.html { redirect_to docs_path() }
            format.xml  { render :xml => @all_docs }     
          else
            # need to add somewhere to go in case of exception
          end
        end
      else  
        @doc = Doc.new(params[:doc])
        @doc.created_by = shared_current_user.ir_id
        @doc.build_metadata if @doc.metadata.nil?
        @doc.uuid = UUIDTools::UUID.random_create.to_str

        respond_to do |format|
          if @doc.save 
            if album_id = params[:add_to_album_id_single]
              if !album_id.empty?
                @album = Album.find(album_id) 
                @albuming = Albuming.new(:doc_id => @doc.id, :album_id => album_id, :position => Albuming.next_position(album_id), :submitted_by => shared_current_user.ir_id, :submitted_at => Time.now).save
              end
            end  
            flash[:notice] = 'Doc was successfully created.'
            format.html { redirect_to edit_doc_path(@doc, :remote => params[:remote]) }
            format.xml  { render :xml => @doc, :status => :created, :location => @doc }
          else
            format.html { render :action => "new" }
            format.xml  { render :xml => @doc.errors, :status => :unprocessable_entity }
          end
        end
      end
    end


    def update  
      tags = Tagging.merge_existing(@doc.all_tags,params[:doc_tags],params[:doc_tags_input],params[:preex_doc_tags],shared_current_user,'doc',@doc.id)
      @profile.tag(@doc, :with => tags, :on => :tags)

      if params[:doc]['metadata_attributes']
        if params[:doc]['metadata_attributes']['creators_attributes'] and !params[:doc]['metadata_attributes']['creators_attributes']['0']['id'].empty?
          creator_id = params[:doc]['metadata_attributes']['creators_attributes']['0']['id']
          if @doc.metadata.creatorings
            @doc.metadata.creatorings.destroy_all
          end 
          Creatoring.new(:metadata_id => params[:doc]['metadata_attributes']['id'], :creator_id => creator_id, :position => 1).save
          if creator = Creator.find(creator_id) 
            creator.update_attributes(params[:doc]['metadata_attributes']['creators_attributes']['0'])
          end
          params[:doc]['metadata_attributes'].delete_if{ |k,v| k == "creators_attributes" }
        end
      end    

      #@doc.calc_star_rating
      respond_to do |format|    
        if @doc.update_attributes(params[:doc])
          if @doc.uuid.empty?
            uuid = UUIDTools::UUID.random_create.to_str
  	        @doc.update_attribute(:uuid, uuid)
          end 
          flash[:notice] = 'Doc was successfully updated.'
          if params[:remote]
            format.html { redirect_to edit_doc_path(@doc,:remote=>true) }
          else   
            format.html { redirect_to doc_path(@doc) }
            format.xml  { head :ok }
          end
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @doc.errors, :status => :unprocessable_entity }
        end
      end
    end

    def destroy
      @doc.destroy
      flash[:notice] = 'Doc was successfully deleted.'    
      respond_to do |format|
        format.html { redirect_to(person_docs_path(shared_current_user.ir_id)) }
        format.xml  { head :ok }
      end
    end

    def reprocess 
      @doc = Doc.find(params[:doc_id])
      @doc.reprocess
      respond_to do |format|
        flash[:notice] = 'Doc media reprocessed.'    
        format.html { redirect_to edit_doc_path(@doc) }
        format.xml  { head :ok }
      end
    end

    def download
      response.headers["X-Sendfile"] = @doc.asset.path(:original)
      response.headers['Content-Type'] = @doc.asset_content_type
      response.headers['Content-Length'] ||= @doc.asset_file_size
      response.headers['Content-Disposition'] = "attachment; filename=#{@doc.asset_file_name}"
      #send_file(@doc.asset.path(:original))
      render :nothing => true
    end

    def embed 
      @size = 'std'
      if params[:s].present?
        if params[:s] == 'bigger'
          @size = 'bigger' 
        end
      end
    end

    def spreadsheet 

    end

    def feed
      @docs = []
      if params[:doc_id].present?
        @docs << Doc.find(params[:doc_id], :include => [:metadata], :conditions => ["metadatas.publish_status = 'public'"])
      else
         order = 'created_at DESC'
          if params[:o].present?
            if params[:o] == 'rand'
              order = 'RAND()'
            end
          end   

          limit = params[:limit].present? ? params[:limit] : 100

          content_type = params[:ct].present? ? "AND asset_content_type like '%#{params[:ct]}%'" : ''

          if params[:t].present?
            multiples = false
            # parse the tag argument: (*) and
            if params[:t].include? "*" 
              tag_list = ActsAsTaggableOn::TagList.from(params[:t].split('*'))  
              @tags = ActsAsTaggableOn::Tag.named_any(tag_list)
              if @tags.count > 1 # more than one tag does actually exist 
                multiples = true
              elsif @tags.count == 1 # only one tag actually exists of the may being passed in
                @tag = @tags.first
              end
            else 
              @tag = params[:t]   
            end

            if multiples # a known flaw: if you request a three tag match, two of which are legitimate in will still bring back the results matching those two tags ignoring the invlaid third tag
              @docs = Doc.select_tagged_with(@tags,limit,order)
              if order == 'created_at DESC'
                @docs.sort! { |a,b| a.created_at <=> b.created_at } unless !@docs
              end
            else 
              order = order == 'RAND()' ? order : "d.#{order}"
              @docs = Doc.find_by_sql ["SELECT d.* from docs d INNER JOIN metadatas m ON d.id=m.doc_id INNER JOIN taggings tg ON tg.taggable_id=d.id INNER JOIN tags t ON tg.tag_id=t.id WHERE t.name= ? AND m.publish_status = 'public' #{content_type} ORDER BY #{order} LIMIT #{limit}", @tag]
            end 
          else 
            @docs = Doc.find(:all, :order => order, :limit => limit, :include => [:metadata], :conditions => ["metadatas.publish_status = 'public' #{content_type}"])      
          end  
      end
      respond_to do |format|l
        format.atom
      end
    end

    private 
     def find_doc
      @doc = Doc.where(:id => params[:id]).includes(:metadata,:creators).includes(:taggings,:tag).includes(:albumings,:album).first
     end

     def find_all_docs
       @all_docs = Doc.order("created_at DESC").includes(:metadata,:creators).includes(:taggings,:tag).includes(:albumings,:album)
       @all_docs.sort! { |a,b| a.created_at <=> b.created_at } unless !@all_docs
     end

     def find_my_avail_albums
       # find all album_ids in albumings association that have this doc_id
       ids = Albuming.all(:select =>"DISTINCT album_id", :conditions => ["doc_id = :doc_id AND submitted_by = :submitter_id ", {:doc_id => @doc.id, :submitter_id => shared_current_user.ir_id}]).collect(&:album_id)
       if ids.empty?
        @my_avail_albums = Album.find(:all, :conditions => ["created_by = :creator_id AND status = 'publish'", {:creator_id => shared_current_user.ir_id}])
       else
       # exclude those from the select
      @my_avail_albums = Album.find(:all, :conditions => ["id NOT IN (:ids) AND created_by = :creator_id AND status = 'publish'", {:ids  => ids, :creator_id => shared_current_user.ir_id}]) ? Album.find(:all, :conditions => ["id NOT IN (:ids) AND created_by = :creator_id AND status = 'publish'", {:ids  => ids, :creator_id => shared_current_user.ir_id}]) : nil
       end
      @my_avail_albums.sort! { |a,b| a.name.downcase <=> b.name.downcase } unless !@my_avail_albums
     end

     def find_open_avail_albums
        # find all album_ids in albumings association that have this doc_id
        ids = Albuming.all(:select =>"DISTINCT album_id", :conditions => ["doc_id = :doc_id", {:doc_id => @doc.id}]).collect(&:album_id)
        if ids.empty?
         @open_avail_albums = Album.find(:all, :conditions => ["submission_priv = 'open' AND view_priv = 'public' AND created_by != :creator_id AND status = 'publish'", {:creator_id => shared_current_user.ir_id}])
        else
        # exclude those from the select
       @open_avail_albums = Album.find(:all, :conditions => ["id NOT IN (:ids) AND submission_priv = 'open' AND view_priv = 'public' AND created_by != :creator_id AND status = 'publish'", {:ids  => ids, :creator_id => shared_current_user.ir_id}]) ? Album.find(:all, :conditions => ["id NOT IN (:ids) AND submission_priv = 'open' AND view_priv = 'public' AND created_by != :creator_id AND status = 'publish'", {:ids  => ids, :creator_id => shared_current_user.ir_id}]) : nil
        end
       @open_avail_albums.sort! { |a,b| a.name.downcase <=> b.name.downcase } unless !@open_avail_albums
    end 
  end

end
