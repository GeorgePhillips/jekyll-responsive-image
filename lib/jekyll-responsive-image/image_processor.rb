module Jekyll
  module ResponsiveImage
    class ImageProcessor
      include ResponsiveImage::Utils

      def process(image_path, config)
        raise SyntaxError.new("No image path specified") if image_path.nil?
        external = is_external_path?(image_path)
        width = nil
        unless external
          absolute_image_path = File.expand_path(image_path.to_s.gsub(/^\//, ""), config[:site_source])
          raise SyntaxError.new("Invalid image path specified: #{absolute_image_path}") unless File.file?(absolute_image_path)
          img = Magick::Image::read(absolute_image_path).first
          width = img.columns
        end

        resize_handler = ResizeHandler.new
        {
          original: image_hash(config, image_path, width),
          resized: resize_handler.resize_image(image_path, external, img, config),
        }
      end

      def self.process(image_path, config)
        self.new.process(image_path, config)
      end
    end
  end
end
