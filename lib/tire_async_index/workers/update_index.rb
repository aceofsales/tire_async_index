require 'hashie/mash'
require 'hashie/extensions/mash/symbolize_keys'

module TireAsyncIndex
  module Workers

    # Worker for updating ElasticSearch index
    class UpdateIndex
      class Smash < ::Hashie::Mash
        include Hashie::Extensions::Mash::SymbolizeKeys
      end

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
          opts = Smash.new opts
          FindModel.new(class_name: class_name).klass.new.tap do |inst|
            options = Smash.new(opts.fetch(:remove, {}))
            type = options.delete(:type).presence || inst.tire.document_type

            TireAsyncIndex.configuration.around_delete_callback.call(
              index_name: inst.tire.index_name,
              document_type: type,
              model_id: id,
              routing: options.routing
            ) do
              inst.tire.index.remove(type, { _id: id }, options)
            end
          end
        end
      end
    end
  end
end
