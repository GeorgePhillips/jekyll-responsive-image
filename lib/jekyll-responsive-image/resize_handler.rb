module Jekyll
  module ResponsiveImage
    class ResizeHandler
      include ResponsiveImage::Utils

      def resize_image(image_path, external, img, config)
        resized = []

        config['sizes'].each do |size|
          width = size['width']

          if external
              height = "external"
          else
              ratio = width.to_f / img.columns.to_f
              height = (img.rows.to_f * ratio).round
              next unless needs_resizing?(img, width)
          end

          filepath = format_output_path(config['output_path_format'], config, image_path, width)
          resized.push(image_hash(config, filepath, width))

          site_source_filepath = File.expand_path(filepath, config[:site_source])
          site_dest_filepath = File.expand_path(filepath, config[:site_dest])

          # Don't resize images more than once
          next if File.exist?(site_source_filepath)

          if external and img.nil?
              img = download_external_image(config, image_path)
          end

          ensure_output_dir_exists!(site_source_filepath)
          ensure_output_dir_exists!(site_dest_filepath)

          Jekyll.logger.info "Generating #{site_source_filepath}"

          ratio = width.to_f / img.columns.to_f
          i = img.scale(ratio)
          i.write(site_source_filepath) do |f|
            f.interlace = i.interlace
            f.quality = size['quality'] || config['default_quality']
          end

          # Ensure the generated file is copied to the _site directory
          Jekyll.logger.info "Copying resized image to #{site_dest_filepath}"
          FileUtils.copy_file(site_source_filepath, site_dest_filepath)

          i.destroy!
        end

        img.destroy! unless img.nil?

        resized
      end

      def needs_resizing?(img, width)
        img.columns > width
      end
    end
  end
end
