module Vivi
  require 'open-uri'

  class Doc < ActiveRecord::Base
    has_one :metadata, :dependent => :destroy

    has_many :albumings, :dependent => :destroy
    has_many :albums, :through => :albumings, :uniq => true

    #has_many :comments, :as => :commentable, :dependent => :destroy, :order => 'created_at ASC'

    #belongs_to :right

    accepts_nested_attributes_for :metadata, :allow_destroy => :false, 
      :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } } 

    #acts_as_taggable_on :tags

    # Paperclip attachment, styles and post-processing are content-type specific   
    attr_accessor :asset_url
    @@default_url = "/images/pending/:style.png"

    has_attached_file :asset, 
              :path => ":rails_root/public/system/:attachment/:id/:style/:normalized_asset_file_name.:extension",
              :url => "/system/:attachment/:id/:style/:normalized_asset_file_name.:extension",
              :styles => lambda { |a| a = a.instance
                 if a.video?
                   styles = {:preview => { :geometry =>  "160x100", :format => "jpg" },
                             :square => { :geometry => "120x120", :format => "jpg" },
                             :bigger_square => { :geometry => "230x230", :format => "jpg" },
                             :poster => { :geometry => "624x416", :format => "jpg" }, 
                             :transcoded => { :geometry =>  "624x416", :format => "mp4" }                      
                            }
                 elsif a.audio?
                   styles = {:transcoded => { :format => "mp3" }
                            }
                 elsif a.image?
                   styles = {:preview => ["160", :jpg],
                             :square => ["120x120#", :jpg], 
                             :gray_square => ["120x120#", :jpg], 
                             :bigger_square => ["230x230#", :jpg],
                             :medium => ["600x600>", :jpg],
                             :large => ["1200x1200>", :jpg] 
                            }
                 elsif a.pdf?
                   styles = {:preview => ["160", :jpg],
                             :square => ["120x120#", :jpg],  
                             :bigger_square => ["230x230#", :jpg], 
                             :medium => ["600x600>", :jpg],
                             :large => ["1200x1200>", :jpg]
                            }
                 else 
                   styles = {}
                 end
                 styles 
               }, # end styles lambda
               :processors => lambda { |a|
                 if a.video?
                    [ :video_transcoder ]
                 elsif a.audio?
                   [ :audio_transcoder ]
                 elsif a.image?
                   [ :thumbnail ]
                 else
                   [ :thumbnail ]
                 end
               },
               :convert_options => { :all => '-quality 95', :gray_square => '-colorspace Gray -strip' }

    # Secure assignment
    attr_protected :asset_file_name, :asset_content_type, :asset_file_size

    # Validations
    #validates_presence_of :title
    validates_attachment_presence :asset
    validates_attachment_size :asset, :less_than => 200.megabytes

    before_validation :download_remote_asset, :if => :asset_url_provided?

    validates_presence_of :asset_remote_url, :if => :asset_url_provided?, :message => 'is invalid or inaccessible'

    # Interrupt processing after asset upload  
    before_post_process do |doc|
     false if doc.processing?
    end

    # Create to entry in Delayed Job queue  
    after_create { |doc| doc.send_later(:perform) } 
    #after_create do |doc|
       #Delayed::Job.enqueue DocJob.new(doc.id)
    #end

    # Force asynchonous asset processing
    def perform
      self.processing = false
      self.asset.reprocess!
      self.save                                         
      self.calc_res
    end

    def reprocess
      self.asset.reprocess!
      self.save
      self.calc_res
    end

    def url(style = :original)  
      if (self.asset && processing? && style != :original) or !File.exist?(self.asset.path(style))
        return asset.send(:interpolate, @@default_url, "pending_#{style}")
      end
      asset.url(style)
    end

    def fast_media(t='medium',ext='jpg')
      "(...)/vivi/assets/#{id}/#{t}/#{id}.#{ext}"
    end

    def calc_res 
      res = ''
      if File.exist?(self.asset.path(:original))
        if self.image?      
          image = Magick::Image.ping(self.asset.path(:original))[0]

          width = image.columns
          height = image.rows 
          dpi  = image.density.split('x').first.to_i

          self.update_attribute(:asset_resolution,"#{width}x#{height}")
          self.update_attribute(:asset_dpi, dpi)
        elsif self.video? 
          begin      
            video = RVideo::Inspector.new(:file => self.asset.path(:original))
            self.update_attribute(:asset_resolution,"#{video.width}x#{video.height}") 
          rescue
            puts "Unable to determine video resolution for #{self.id}"
          end
        end
      end  
    end

    def best_res  
      dimensions = self.asset_resolution.split("x")
      w = dimensions.first.to_i                      
      h = dimensions.last.to_i

      min_w = 600
      min_h = 600

      best = :original
      if w < min_w and h < min_h 
        valid = %w(jpeg png gif).any? {|str| self.asset.content_type.downcase.include? str}
        if valid
          best = :original  
        end
      else
        if w >= h 
          best = :medium
        elsif h < w*2
          best = :large
        else
          best = :original
        end
      end

      best
    end  

    def best_dim (dim,best = '100%')  
      dimensions = self.asset_resolution.split("x")
      w = dimensions.first.to_i                      
      h = dimensions.first.to_i                      

      min_w = 600
      min_h = 600
      if w>0 and h>0
        if dim == 'width'
          if w < min_w
            best = w 
          end  
        elsif dim == 'height'
          if h < min_h
            best = h 
          end
        end
      end    
      best
    end

    def loupe     
     if self.image?
       valid = %w(jpeg png gif).any? {|str| self.asset.content_type.downcase.include? str}
       if valid
         return :original
       else
         :large
       end
     end 
    end


    def normalized_asset_file_name
      "#{self.id}" 
    end

    def video?
        [ 'application/x-mp4',
          'application/x-mov',
          'video/mpeg',
          'video/quicktime',
          'video/x-la-asf',
          'video/x-ms-asf',
          'video/x-ms-wmv',
          'video/x-msvideo',
          'video/x-sgi-movie',
          'video/x-flv',
          'video/x-mpeg',
          'video/x-m4v',
          'video/avi',
          'video/x-dv',
          'video/mpg',
          'application/octet-stream video/quicktime',
          'flv-application/octet-stream',
          'video/3gpp',
          'video/3gpp2',
          'video/3gpp-tt',
          'video/BMPEG',
          'video/BT656',
          'video/CelB',
          'video/DV',
          'video/H261',
          'video/H263',
          'video/H263-1998',
          'video/H263-2000',
          'video/H264',
          'video/JPEG',
          'video/MJ2',
          'video/MP1S',
          'video/MP2P',
          'video/MP2T',
          'video/mp4',
          'video/MP4V-ES',
          'video/MPV',
          'video/mpeg4',
          'video/mpeg4-generic',
          'video/nv',
          'video/ogg',
          'video/parityfec',
          'video/pointer',
          'video/raw',
          'video/rtx' ].include?(asset.content_type)
      end

      def image?
        [ 'image/cgm',
          'image/fif',
          'image/gif',
          'image/ief',
          'image/ifs',
          'image/jpeg',
          'image/pjpeg',
          'image/pict',   
          'image/png',    
          'image/tiff',
          'image/vnd',
          'image/wavelet',
          'image/bmp',
          'image/svg+xml',
          'image/x-cmu-raster',
          'image/x-portable-anymap',
          'image/x-portable-bitmap',
          'image/x-portable-graymap',
          'image/x-portable-pixmap',
          'image/x-rgb',
          'image/x-quicktime',
          'image/x-xbitmap',
          'image/x-xpixmap',
          'image/x-xwindowdump' ].include?(asset.content_type)
      end

      def audio?
        [ 'application/x-mp3',
          'application/x-wav',
          'audio/32kadpcm',
          'audio/basic',
          'audio/g.722.1',
          'audio/l16',
          'audio/midi',
          'audio/mp4',
          'audio/mp4a-latm',
          'audio/mpa-robust',
          'audio/mpeg',
          'audio/parityfec',
          'audio/prs.sid',
          'audio/telephone-event',
          'audio/tone',
          'audio/vnd.cisco.nse',
          'audio/vnd.cns.anp1',
          'audio/vnd.cns.inf1',
          'audio/vnd.digital-winds',
          'audio/vnd.everad.plj',
          'audio/vnd.lucent.voice',
          'audio/vnd.nortel.vbk',
          'audio/vnd.nuera.ecelp4800',
          'audio/vnd.nuera.ecelp7470',
          'audio/vnd.nuera.ecelp9600',
          'audio/vnd.octel.sbc',
          'audio/vnd.qcelp',
          'audio/vnd.rhetorex.32kadpcm',
          'audio/vnd.vmx.cvsd',
          'audio/x-aiff',
          'audio/x-mpegurl',
          'audio/x-m4a',
          'audio/x-pn-realaudio',
          'audio/x-pn-realaudio-plugin',
          'audio/x-realaudio',
          'audio/x-wav'].include?(asset.content_type)
      end  

      def pdf?
        [ 'application/x-pdf',
          'application/pdf'
        ].include?(asset.content_type)
      end

      def text?
        [ 'application/x-rtf',
          'application/x-pages',
          'application/x-doc',
          'application/msword',
          'application/octet-stream',
          'text/plain'
        ].include?(asset.content_type)
      end


      def calc_height(style = :preview)
        if @calcHeight
          @calcHeight
        else
          begin
            if File.exist?(self.asset.path(style))
              image = Magick::Image.ping(self.asset.path(style))[0]
              @calcHeight = { 'height' => image.rows }
            else
              @calcHeight = { 'height' => 100 }
            end
          rescue
            return @calcHeight = { 'height' => 100 }
          end
        end
      end

      #def all_tags 
        # Fetches all tags associated with this doc, regardless of the user who created the tag or the tag context
      #  all_tags = Tag.find_by_sql ["SELECT t.name,t.id,tg.tagger_id,tg.taggable_type,tg.id as tagging_id from tags t INNER JOIN taggings tg ON tg.tag_id=t.id WHERE tg.taggable_type='Doc' AND tg.taggable_id = ?", self.id]
      #end  

      def all_albums_searchable
        # Fetches all albums associated with this doc
        ids = Albuming.select("DISTINCT album_id").where(:doc_id => self.id).collect(&:album_id)                               
        all_albums_searchable = Album.where("id IN (?)", ids) 
      end

      
    private
      def asset_url_provided?
        !self.asset_url.blank?
      end
      def download_remote_asset
        self.asset = do_download_remote_asset
        self.asset_remote_url = asset_url
      end
      def do_download_remote_asset
        io = open(URI.parse(asset_url))
        def io.original_filename; base_uri.path.split('/').last; end
        io.original_filename.blank? ? nil : io
      rescue # catch url errors with validations instead of exceptions (Errno::ENOENT, OpenURI::HTTPError, etc...)
      end
 end 
end
