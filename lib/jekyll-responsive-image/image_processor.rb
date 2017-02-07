module Jekyll
  module ResponsiveImage
    class ImageProcessor
      include ResponsiveImage::Utils

      def process(image_path, config)
        if image_path =~ /^https?\:\/\//
            local_path = image_path.sub(/^https?\:\/\//, '')
            output_path = format_output_path(config['output_path_format'], config, local_path, "external", "external")
            absolute_image_path = File.expand_path(output_path, config[:site_source])

            if File.file?(absolute_image_path)
                Jekyll.logger.info "Using cache at #{absolute_image_path}"
            else
                Jekyll.logger.info "Downloading #{image_path} to #{output_path}"
                file_created = false
                begin
                  ensure_output_dir_exists!(absolute_image_path)
                  Jekyll.logger.info "Opening #{absolute_image_path}"
                  file_created = true
                  File.open(absolute_image_path, 'wb') do |fo|
                    fo.write open(image_path).read
                  end
                rescue Exception => e
                  File.delete(absolute_image_path) if file_created
                  Jekyll.logger.error "Downloading #{image_path} failed '#{e.message}'"
                end
            end
        else
          absolute_image_path = File.expand_path(image_path.to_s, config[:site_source])
        end

        raise SyntaxError.new("No image path specified") if image_path.nil?
        raise SyntaxError.new("Invalid image path specified: #{absolute_image_path}") unless File.file?(absolute_image_path)

        resize_handler = ResizeHandler.new
        img = Magick::Image::read(absolute_image_path).first
        {
          original: image_hash(config, image_path, img.columns, img.rows),
          resized: resize_handler.resize_image(img, config),
        }
      end

      def self.process(image_path, config)
        self.new.process(image_path, config)
      end
    end
  end
end
