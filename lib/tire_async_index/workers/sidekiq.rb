module TireAsyncIndex
  module Workers
    class Sidekiq < UpdateIndex
      include ::Sidekiq::Worker
      sidekiq_options queue: TireAsyncIndex.queue, unique_for: 30.minutes, unique_until: :start

      def self.enqueue(action_type, class_name, id, opts = {})
        if class_name == 'Activity'
          self.set(queue: 'elasticsearch_activity').perform_async(
            action_type, class_name, id, opts
          )
        else
          self.perform_async(
            action_type, class_name, id, opts
          )
        end
      end

      def perform(action_type, class_name, id, opts = {})
        process(action_type, class_name, id, opts)
      end

    end
  end
end
