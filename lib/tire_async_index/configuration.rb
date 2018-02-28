module TireAsyncIndex
  class Configuration
    AVALAIBLE_ENGINE = [:sidekiq, :resque, :none]

    attr_accessor :queue
    attr_accessor :engine
    attr_accessor :around_delete_callback

    def background_engine type
      if AVALAIBLE_ENGINE.include?(type.to_sym)
        @engine = type.to_sym
      else
        raise EngineNotFound, "Background Engine '#{type}' not found"
      end
    end

    def use_queue name
      @queue = name.to_sym
    end

    def set_around_delete_callback callback
      @around_delete_callback = callback
    end

    def initialize
      @queue  = :normal
      @engine = :none
      @around_delete_callback = ->(**args, &block) { block.call }
    end

  end
end
