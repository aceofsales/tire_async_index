module TireAsyncIndex
  module Workers

    # Worker for updating ElasticSearch index
    class UpdateIndex

      def self.run(*args)
        if TireAsyncIndex.inline?
          self.new.process(*args)
        else
          self.enqueue(*args)
        end
      end

      def self.enqueue(*args)
        raise NotImplementedError
      end

      # Update or delete ElasticSearch index based on the action_type parameter.
      #
      # Parameters:
      #   action_type - Determine index direction. (allowed value - Update or Delete)
      #   class_name - Model class name
      #   id - Document id
      #

      def process(action_type, class_name, id, opts = {})
        case action_type.to_sym
        when :update
          object = FindModel.new(class_name: class_name).find(id)

          if object.present? && object.respond_to?(:tire)
            store_opts = {}
            if object.respond_to?(:elasticsearch_store_options)
              store_opts = object.elasticsearch_store_options
            end

            if store_opts.empty?
              object.tire.update_index
            else
              object.tire.index.store(object, store_opts)
            end
          end
        when :delete
          FindModel.new(class_name: class_name).klass.new.tap do |inst|
            type = opts.fetch(:remove, {}).fetch(:type, inst.tire.document_type)
            inst.tire.index.remove(type, { _id: id })
          end
        end
      end
    end
  end
end
