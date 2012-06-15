require "rvideo"
module Vivi
  module Paperclip

    class VideoTranscoder < Processor

      attr_accessor :options, :geometry, :whiny

      def initialize file, options = {}, attachment = nil
        logger = RAILS_DEFAULT_LOGGER 
      
        super
        @current_format = File.extname(@file.path)
        @basename = File.basename(@file.path, @current_format)
      
        @options = options
        @format = options[:format]
        unless options[:geometry].nil? || (@geometry = Geometry.parse(options[:geometry])).nil?
          unless @geometry.square? 
            begin      
              max_width = @geometry.width
              video = RVideo::Inspector.new(:file => @file.path)
              logger.error("RESOLUTION: #{video.resolution}")
              if video.width > max_width
                @geometry.height = ((max_width.to_f/video.width.to_f) * video.height).to_i
              elsif video.width < max_width  
                @geometry.width = video.width.to_i
                @geometry.height = video.height.to_i
              end
              @geometry.width = (@geometry.width / 2.0).floor * 2.0
              @geometry.height = (@geometry.height / 2.0).floor * 2.0
              @geometry.modifier = ''
            rescue
              puts "Unable to determine video geometry for #{@basename}"
            end
          end
        end
        @whiny = options[:whiny].nil? ? true : options[:whiny]
      end
    
      def make
        dst = Tempfile.new([@basename, @format].compact.join("."))
        dst.binmode

        RVideo::Transcoder.logger = RAILS_DEFAULT_LOGGER
        logger = RAILS_DEFAULT_LOGGER 
       
        # Screenshot grabbing
        if @format == 'jpg'
          # Calculate time offset
          inspector = RVideo::Inspector.new :file => file.path
          offset = inspector.duration/2000
        
          recipe = %Q[-itsoffset -#{offset} -i "#{File.expand_path(file.path)}" -y -vcodec mjpeg -vframes 1 -an -f rawvideo ]
          recipe << "-s #{@geometry.to_s} " unless @geometry.nil?
          recipe << %Q["#{File.expand_path(dst.path)}"]
        
          begin
            success = Paperclip.run('ffmpeg', recipe)
          rescue PaperclipCommandLineError
            raise PaperclipError, "Unable to process thumbnail for file #{@basename} to #{@format} using the recipe: #{recipe}" if whiny
          end
        
        end

        # Video transcoder :: .mp4
        if @format == 'mp4'
          # Initalize transcoder
          transcoder = RVideo::Transcoder.new
        
          # Recipe for ffmpeg video transcoding
          recipe = "ffmpeg -y -i $input_file$  -acodec libfaac -ab 96k -ar 22050 -vcodec libx264 -vpre hq -vpre baseline -coder 0 -level 13 -crf 24 -threads 0 -s $vid_size$ -f mp4 $output_file$"

          begin
            transcoder.execute(recipe, {:input_file => file.path, :output_file => dst.path, :vid_size => @geometry.to_s})
          rescue
            puts "Unable to transcode file #{@basename} to #{@format} using the recipe: #{recipe}" if whiny
          end
        end
      
        # Video transcoder :: .ogv
        if @format == 'ogv'
          recipe = %Q[ "#{File.expand_path(file.path)}" -x #{@geometry.width.to_s} -y #{@geometry.height.to_s} -v 8 -o "#{File.expand_path(dst.path)}"]
          begin
            success = Paperclip.run('ffmpeg2theora', recipe)
          rescue PaperclipCommandLineError
            raise PaperclipError, "Unable to transcode file #{@basename} to #{@format} using the recipe: #{recipe}" if whiny
          end
        end
      

        dst

      end

    end
  end
  
end

