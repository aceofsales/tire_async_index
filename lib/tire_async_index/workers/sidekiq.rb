module TireAsyncIndex
  module Workers
    class Sidekiq < UpdateIndex
      include ::Sidekiq::Worker
      sidekiq_options queue: TireAsyncIndex.queue, unique_for: 30.minutes

      def self.enqueue(action_type, class_name, id, opts = {})
        self.perform_async(
          action_type, class_name, id, opts
        )
      end

      def perform(action_type, class_name, id, opts = {})
        process(action_type, class_name, id, opts)
      end

    end
  end
end
