module TireAsyncIndex
  class FindModel
    attr_reader :class_name

    def initialize(opts)
      @class_name = opts[:class_name]
      raise ArgumentError, 'class_name required' if self.class_name.nil?
    end

    def klass
      if defined?(RUBY_VERSION) && RUBY_VERSION.match(/^2\./)
        Kernel.const_get(class_name)
      else
        class_name.split('::').reduce(Object) do |mod, const_name|
          mod.const_get(const_name)
        end
      end
    end

    def find(id)
      if klass.respond_to?(:tire_async_finder)
        klass.tire_async_finder
      else
        klass.where(id: id).first
      end
    end
  end
end
