module Vivi
  module Paperclip

    class AudioTranscoder < Processor

      attr_accessor :options, :whiny

      def initialize file, options = {}, attachment = nil
        super
        @current_format = File.extname(@file.path)
        @basename = File.basename(@file.path, @current_format)

        @options = options
        @format = options[:format]
        @whiny = options[:whiny].nil? ? true : options[:whiny]
      end

      def make
        dst = Tempfile.new([@basename, @format].compact.join("."))
        dst.binmode

        # Audio transcoder :: .mp3
        if @format == 'mp3'
          recipe = %Q[ -y -i "#{File.expand_path(file.path)}" -acodec libmp3lame -ab 128k -f mp3 "#{File.expand_path(dst.path)}"]
          begin
            success = Paperclip.run('ffmpeg', recipe)
          rescue PaperclipCommandLineError
            raise PaperclipError, "Unable to transcode file #{@basename} to #{@format} using the recipe: #{recipe}" if whiny
          end
        end
      
        # Audio transcoder :: .ogg
        if @format == 'ogg'
          recipe = %Q[ -y -i "#{File.expand_path(file.path)}" -acodec vorbis -ab 192k -f ogg "#{File.expand_path(dst.path)}"]
          begin
            success = Paperclip.run('ffmpeg', recipe)
          rescue PaperclipCommandLineError
            raise PaperclipError, "Unable to transcode file #{@basename} to #{@format} using the recipe: #{recipe}" if whiny
          end
        end
      

        dst

      end

    end
  end
  
end

