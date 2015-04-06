module Independize
  class Task < Rake::SprocketsTask
    attr_accessor :app

    def initialize(app)
      @app = app
      super()
    end

    def define
      desc "Load asset compile environment"
      task :environment do
        # Load full Rails environment by default
        Rake::Task['environment'].invoke
      end

      task :independize => :environment do
        with_logger do
          compile_assets
          render_html

          rm_rf(output)
        end
      end
    end

    private
    def compile_assets
      filters = /\.(js|css)$/
      manifest.compile(filters)
    end

    def render_html
      # ActionView::RoutingUrlFor.send(:include, ActionDispatch::Routing::UrlFor)

      view = create_view
      joined_css = join_css
      joined_js = join_js

      view_dir = app.config.paths['app/views'].first
      source_dir = "#{view_dir}/independize"
      Dir.glob("#{source_dir}/[^_]*.html*") do |file|
        html = view.render(file: "#{file}").to_str
        html = inject_css(html, joined_css)
        html = inject_js(html, joined_js)
        html = replace_html_image(html)
        write_html_file(file, html)
      end
    end

    def write_html_file(template_name, html)
      html_name = File.basename(template_name, ".*")
      public_dir = app.config.paths['public'].first
      File.open("#{public_dir}/#{html_name}", "w") { |f| f.write(html) }
    end

    def view_class(helpers_dir)
      helper_files = Dir.glob("#{helpers_dir}/**/*_helper.rb")
      helper_modules = helper_files.map do |helper_file|
        require_dependency helper_file
        module_name = File.basename(helper_file, ".rb").camelize
        module_name.constantize
      end

      Class.new(ActionView::Base) do
        routes = Rails.application.routes
        include routes.url_helpers
        include routes.mounted_helpers

        helper_modules.each do |helper_module|
          include helper_module
        end
      end
    end

    def create_view
      view_dir = app.config.paths['app/views'].first
      context = ActionView::LookupContext.new(view_dir)
      context.prefixes = "independize"

      view = view_class(app.config.paths["app/helpers"]).new(context)
    end

    def join_css
      css_dir = "#{output}/stylesheets"
      css = '<style type="text/css">'
      css = Dir.glob("#{css_dir}/*").reduce(css) { |acc, file| acc + IO.read(file) }
      css += '</style>'
      rm_rf(css_dir)
      css
    end

    def inject_css(html, css)
      html.sub(/(<\/head>)/) { "#{css}#{$1}" }
    end

    def join_js
      js_dir = "#{output}/javascripts"
      js = '<script type="text/javascript">'
      js = Dir.glob("#{js_dir}/*").reduce(js) { |acc, file| acc + IO.read(file) }
      js += '</script>'
      rm_rf(js_dir)
      js
    end

    def inject_js(html, js)
      html.sub(/(<\/body>)/) { "#{js}#{$1}" }
    end

    def replace_html_image(html)
      html.gsub(/(img.+?src=")(.+?)(")/) { "#{$1}#{replace_image_to_data_uri($2)}#{$3}" }
    end

    def replace_css_image(css)
      css.gsub(/(url\(")(.+?)("\))/) { "#{$1}#{replace_image_to_data_uri($2)}#{$3}" }
    end

    def replace_image_to_data_uri(image_file)
      image_dir = "app/assets/independize/images"
      image_path = "#{image_dir}/#{File.basename(image_file)}"

      if File.exist?(image_path)
        content_type = compute_mime_type(File.extname(image_file))
        data_uri = Base64.strict_encode64(IO.read(image_path))
        "data:#{content_type};base64,#{Rack::Utils.escape(data_uri)}"
      else
        image_file
      end
    end

    def compute_mime_type(extension)
      case extension
      when ".png"
        "image/png"
      when ".jpeg", ".jpg"
        "image/jgeg"
      when ".gif"
        "image/gif"
      when ".svg"
        "image/svg+xml"
      end
    end
  end
end
