module Remy
  module Utility
    def flatten_paths(*path_arrays)
      path_arrays.flatten.compact.map { |path| File.expand_path(path) }
    end
  end
end
