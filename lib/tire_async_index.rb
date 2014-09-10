require "tire_async_index/configuration"
require "tire_async_index/exceptions"
require "tire_async_index/version"
require "tire_async_index/find_model"

module TireAsyncIndex
  extend self
  attr_accessor :configuration

  def configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def queue
    self.configuration.queue
  end

  def engine
    self.configuration.engine
  end

  def worker
    case configuration.engine
    when :sidekiq
      TireAsyncIndex::Workers::Sidekiq
    when :resque
      TireAsyncIndex::Workers::Resque
    else
      TireAsyncIndex::Workers::UpdateIndex
    end
  end

  module Workers
    autoload :UpdateIndex, 'tire_async_index/workers/update_index'
    autoload :Sidekiq,     'tire_async_index/workers/sidekiq'
    autoload :Resque,      'tire_async_index/workers/resque'
  end

  def inline!
    orig_inline = self._inline
    self._inline = true
    yield
  ensure
    self._inline = orig_inline
  end

  def inline?
    !!self._inline
  end

  protected
  def _inline
    Thread.current[:tire_async_index_inline]
  end

  def _inline=(inline)
    Thread.current[:tire_async_index_inline] = inline
  end
end

require 'tire/model/async_callbacks'

TireAsyncIndex.configure {}
