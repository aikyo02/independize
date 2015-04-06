module Independize
  class RenderingController < ActionController::Base
    source_dir = "app/views/independize"
    Dir.glob("#{source_dir}/[^_]*") do |file|
      action = File.basename(file, ".*")
      action.sub!(/\..*/, "")
      puts "action: #{action}"
      eval <<-ACTION
        def #{action}
          render
        end
      ACTION
    end
  end
end
