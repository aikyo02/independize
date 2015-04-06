module Independize
  class Railtie < Rails::Railtie
    rake_tasks do |app|
      require 'independize/tasks.rb'
      Independize::Task.new(app) do |t|
        t.environment = build_environment(app)
        t.output = File.join(app.config.paths['public'].first, "independize/temp")
        t.assets = %(sample.js.coffee sample.css.sass)

      end
    end

    def build_environment(app)
      env = Sprockets::Environment.new(app.root.to_s)

      assets_path = "app/assets/independize"
      env.append_path(assets_path)
      env.js_compressor  = app.config.assets.js_compressor
      env.css_compressor = app.config.assets.css_compressor

      if app.config.cache_classes
        env = env.cached
      end

      env
    end
  end
end
