module Vivi
  class ApplicationController < ActionController::Base
    
    helper_method :find_all_albums, :find_featured_albums, :find_person_albums, 
                  :find_all_stars, :find_person_stars,
                  :find_person_docs, :find_random_docs,
                  :create_docs_from_zip, :find_all_helptips, :find_all_rights
                  
    helper :all # include all helpers, all the time

    # See ActionController::RequestForgeryProtection for details
    # Uncomment the :secret if you're not using the cookie session store
    protect_from_forgery # :secret => '08785730c78233aa22c1d4e204eed56c'

    # See ActionController::Base for details 
    # Uncomment this to filter the contents of submitted sensitive data parameters
    # from your application log (in this case, all fields with names like "password"). 
    # filter_parameter_logging :password

    private

    def find_all_albums
      @all_albums = Album.order("created_at DESC").includes(:docs)
      @all_albums.sort! { |a,b| a.name.downcase <=> b.name.downcase } unless !@all_albums
    end

    def find_featured_albums
      @featured_albums = Album.where(:promoted => true).order("created_at DESC").includes(:docs).limit(3)
    end 

    def find_person_albums(person_id, limit=50)
      @person_albums = Album.select('DISTINCT albums.*').where(:created_by => person_id).order("created_at DESC").limit(limit)      
    end

    def find_random_docs
      @random_docs = Doc.select('DISTINCT docs.*').order("RAND()").limit(60)      
    end

    def find_person_docs(person_id, limit=300)
      @person_docs = Doc.select('DISTINCT docs.*').where(:created_by => person_id).order("created_at DESC").includes(:metadata,:creators).includes(:taggings,:tag).limit(limit)      
    end

    def find_all_stars   
      @all_stars = Doc.select('DISTINCT docs.*').joins(:stars).order("stars.created_at DESC").includes(:metadata,:creators).includes(:taggings,:tag) 
    end

    def find_person_stars(person_id, limit=50)
      @person_stars = Doc.select('DISTINCT docs.*').joins(:stars).order("stars.created_at DESC").where('stars.user_id = ?', person_id).includes(:metadata,:creators).includes(:taggings,:tag).limit(limit)         
    end

    def find_all_helptips
      @all_helptips = Helptip.find(:all) ? Helptip.find(:all) : nil
      @all_helptips = @all_helptips.inject({}) do |h, helptip|
          h.update helptip.name => helptip.tip
      end   
    end 

    def find_all_rights
      @all_rights = Right.find(:all) ? Right.find(:all) : nil
    end

    def create_docs_from_zip(assets_zip, assets_title, album_id)
       tmpdir = File.join(RAILS_ROOT, "tmp", "zip-#{Process.pid.to_s}.#{rand(99999)}")     
       Zip::ZipFile.open(assets_zip.path) do |ar| 
         ar.each_with_index do |zf,i|
           next if zf.name =~ /__MACOSX/ or zf.name =~ /\.DS_Store/
           if zf.directory?
             dir = File.join(tmpdir,zf.name)
             FileUtils.mkdir_p(dir)
           else
             fullpath = File.join(tmpdir,zf.name)
             dirname = File.dirname(fullpath)
             FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
             zf.extract(fullpath)
             d = File.new(fullpath)
             doc = Doc.new(:asset=>d)
             doc.created_by = @current_user.ir_id 
             doc.build_metadata 
             doc.uuid = UUIDTools::UUID.random_create.to_str

             doc.title = zf.name 
             if doc.save && album_id 
              @albuming = Albuming.new(:doc_id => doc.id, :album_id => album_id, :position => Albuming.next_position(album_id), :submitted_by => @current_user.ir_id, :submitted_at => Time.now).save
             end                               
             d.close  
             FileUtils.remove_file(fullpath) 
           end
         end
        end # end Zip::ZipFile.open
       FileUtils.remove_file(assets_zip.path)
       FileUtils.remove_entry_secure(tmpdir,true)   
     end

  end
end
