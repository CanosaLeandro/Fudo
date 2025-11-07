module Paths
  class << self
    def root
      File.expand_path('..', __dir__)
    end

    def autoload_paths
      %w[lib models workers controllers].each do |dir|
        path = File.join(root, 'api', dir)
        $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
        
        # Require all Ruby files in the directory if it exists
        if Dir.exist?(path)
          Dir[File.join(path, '*.rb')].sort.each do |file|
            require File.basename(file, '.rb')
          end
        end
      end
    end
  end
end

# Initialize autoloading
Paths.autoload_paths