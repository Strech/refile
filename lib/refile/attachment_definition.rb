module Refile
  # @api private
  class AttachmentDefinition
    attr_reader :record, :name, :cache, :store, :options, :type, :valid_extensions, :valid_content_types
    attr_accessor :remove

    def initialize(name, cache:, store:, raise_errors: true, type: nil, extension: nil, content_type: nil)
      @name = name
      @raise_errors = raise_errors
      @cache_name = cache
      @store_name = store
      @type = type
      @valid_extensions = [extension].flatten if extension
      @valid_content_types = [content_type].flatten if content_type
      @valid_content_types ||= Refile.types.fetch(type).content_type if type
    end

    def cache
      Refile.backends.fetch(@cache_name.to_s)
    end

    def store
      Refile.backends.fetch(@store_name.to_s)
    end

    def accept
      if valid_content_types
        valid_content_types.join(",")
      elsif valid_extensions
        valid_extensions.map { |e| ".#{e}" }.join(",")
      end
    end

    def raise_errors?
      @raise_errors
    end

    def validate(attacher)
      errors = []

      if valid_extensions
        extension = attacher.extension.to_s.downcase
        allowed = valid_extensions.map(&:downcase)

        unless allowed.include?(extension)
          errors << [:invalid_extension, extension: extension, allowed_types: allowed.join(", ")]
        end
      end

      if valid_content_types and not valid_content_types.include?(attacher.content_type)
        errors << [:invalid_content_type, content_type: attacher.content_type]
      end

      if cache.max_size and attacher.size and attacher.size >= cache.max_size
        max_size = "#{(cache.max_size / 1024.0).round(1)}Kb"
        errors << [:too_large, max_size: max_size]
      end

      errors
    end
  end
end
