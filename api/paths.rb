module Paths
  class << self
    def root
      File.expand_path('..', __dir__)
    end

    def autoload_paths
      %w[models controllers].each do |dir|
        path = File.join(root, 'lib', dir)
        $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
      end
    end
  end
end

# Initialize autoloading
Paths.autoload_paths