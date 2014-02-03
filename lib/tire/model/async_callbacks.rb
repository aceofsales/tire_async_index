module Tire
  module Model
    module AsyncCallbacks

      ID_CONVERSION = {
          'Moped::BSON::ObjectId' => :to_s
      }

      def self.included(base)
        # Bind after save or create callback
        if base.respond_to? :after_commit
          base.send :after_commit, :async_tire_after_commit
        else
          if base.respond_to? :after_save
            base.send :after_save, :async_tire_save_index
          end
          # Bind before destroy callback
          if base.respond_to? :before_destroy
            base.send :before_destroy, :async_tire_delete_index
          end
        end
      end

      private
      def async_tire_after_commit
        # Don't trust the instance in an after_commit callback
        fresh_object = TireAsyncIndex::FindModel.new(class_name: self.class.name).find(get_async_tire_object_id)
        if fresh_object.present? && (transaction_include_action?(:create) || transaction_include_action?(:update))
          async_tire_save_index
        elsif fresh_object.nil? || transaction_include_action?(:destroy)
          async_tire_delete_index
        end
      end

      def async_tire_save_index
        async_tire_callback :update
      end

      def async_tire_delete_index
        async_tire_callback :delete
      end

      def async_tire_callback(type)
        if TireAsyncIndex.engine == :none
          case type
          when :update
            tire.update_index
          when :delete
            tire.index.remove self
          end
        else
          TireAsyncIndex.worker.run(type, self.class.name, get_async_tire_object_id, get_async_tire_opts)
        end
      end

      def get_async_tire_object_id
        if self.respond_to?(:async_tire_object_id)
          self.send(:async_tire_object_id)
        else
          if (method = ID_CONVERSION[self.id.class.name])
            self.id.send(method)
          else
            self.id
          end
        end
      end

      def get_async_tire_opts
        opts = {}

        if self.respond_to?(:elasticsearch_remove_options)
          opts[:remove] = self.elasticsearch_remove_options
        end

        opts
      end

    end
  end
end
