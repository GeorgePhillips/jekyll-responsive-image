require 'pathname'

module Jekyll
  module ResponsiveImage
    module Utils
      def keep_resized_image!(site, image)
        keep_dir = File.dirname(image['path'])
        site.config['keep_files'] << keep_dir unless site.config['keep_files'].include?(keep_dir)
      end

      def ensure_output_dir_exists!(path)
        dir = File.dirname(path)

        unless Dir.exist?(dir)
          Jekyll.logger.info "Creating output directory #{dir}"
          FileUtils.mkdir_p(dir)
        end
      end

      def is_external_path?(image_path)
          image_path =~ /^https?\:\/\//
      end

      def format_output_path(format, config, image_path, width)
        if is_external_path?(image_path)
            image_path = image_path.sub(/^https?\:\/\//, '')
        end
        params = symbolize_keys(image_hash(config, image_path, width))

        Pathname.new(format % params).cleanpath.to_s
      end

      def symbolize_keys(hash)
        result = {}
        hash.each_key do |key|
          result[key.to_sym] = hash[key]
        end
        result
      end

      # Build a hash containing image information
      def image_hash(config, image_path, width)
        {
          'path'      => image_path,
          'dirname'   => relative_dirname(config, image_path),
          'basename'  => File.basename(image_path),
          'filename'  => File.basename(image_path, '.*'),
          'extension' => File.extname(image_path).delete('.'),
          'width'     => width
        }
      end

      def download_external_image(config, image_path)
          local_path = image_path.sub(/^https?\:\/\//, '')
          output_path = format_output_path(config['output_path_format'], config, local_path, "external")
          absolute_image_path = File.expand_path(output_path, config[:site_source])

          if File.file?(absolute_image_path)
              Jekyll.logger.info "Using cache at #{absolute_image_path}"
          else
              Jekyll.logger.info "Downloading #{image_path} to #{output_path}"
              ensure_output_dir_exists!(absolute_image_path)
              begin
                File.open(absolute_image_path, 'wb') do |fo|
                  fo.write open(image_path).read
                end
              rescue Exception => e
                File.delete(absolute_image_path)
                Jekyll.logger.error "Downloading #{image_path} failed '#{e.message}'"
              end
          end

          Magick::Image::read(absolute_image_path).first
      end

      def relative_dirname(config, image_path)
        path = Pathname.new(File.expand_path(image_path, config[:site_source]))
        base = Pathname.new(File.expand_path(config['base_path'], config[:site_source]))

        path.relative_path_from(base).dirname.to_s.delete('.')
      end
    end
  end
end
