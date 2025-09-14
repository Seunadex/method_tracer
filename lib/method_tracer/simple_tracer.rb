# frozen_string_literal: true

require "set"
require "mutex_m"
require "pry"

module MethodTracer
  # SimpleTracer wraps instance methods on a target class and records
  # execution metrics for each invocation. It measures wall-clock duration,
  # captures success or error status, stores results in-memory, and can
  # optionally print each trace as it happens.
  #
  # Options:
  # - :threshold (Float): Minimum duration in seconds to record; defaults to 0.001 (1ms).
  # - :auto_output (Boolean): When true, prints each call summary; defaults to false.
  #
  # Usage:
  #   tracer = MethodTracer::SimpleTracer.new(MyClass, threshold: 0.005)
  #   tracer.trace_method(:expensive_call)
  #   results = tracer.fetch_results
  class SimpleTracer
    def initialize(target_class, **options)
      @target_class = target_class
      @options = default_options.merge(options)
      @calls = []
      @lock  = Mutex.new
      @wrapped_methods = Set.new
    end

    def trace_method(name)
      method_name = name.to_sym
      visibility = method_visibility(method_name)
      return unless visibility
      return unless mark_wrapped(method_name)

      aliased = alias_for(method_name)
      @target_class.send(:alias_method, aliased, method_name)

      tracer = self
      key = reentrancy_key

      @target_class.define_method(method_name, &build_wrapper(aliased, method_name, key, tracer))

      @target_class.send(visibility, method_name)
    end

    def record_call(method_name, execution_time, status, error = nil)
      return if execution_time < @options[:threshold]

      call_details = {
        method_name: "#{@target_class}##{method_name}",
        execution_time: execution_time,
        status: status,
        error: error,
        timestamp: Time.now
      }

      @lock.synchronize { @calls << call_details }

      output_call(call_details) if @options[:auto_output]
    end

    def fetch_results
      snapshot = nil
      @lock.synchronize { snapshot = @calls.dup }

      {
        total_calls: snapshot.size,
        total_time: snapshot.sum { |call| call[:execution_time] },
        calls: snapshot
      }
    end

    private

    def default_options
      {
        threshold: 0.001, # 1ms
        auto_output: false
      }
    end

    def method_visibility(method_name)
      return :private if @target_class.private_method_defined?(method_name)
      return :protected if @target_class.protected_method_defined?(method_name)
      return :public if @target_class.method_defined?(method_name)

      nil
    end

    def mark_wrapped(method_name)
      return false if @wrapped_methods.include?(method_name)

      @wrapped_methods << method_name
      true
    end

    def alias_for(method_name)
      "__method_tracer_original_#{method_name}__".to_sym
    end

    def reentrancy_key
      :__method_tracer_in_trace
    end

    def build_wrapper(aliased, method_name, key, tracer)
      proc do |*args, **kwargs, &block|
        tracer.__send__(:wrap_call, method_name, key) do
          __send__(aliased, *args, **kwargs, &block)
        end
      end
    end

    def wrap_call(method_name, key)
      return yield if Thread.current[key]

      Thread.current[key] = true
      start = monotonic_time
      begin
        result = yield
        record_call(method_name, monotonic_time - start, :success)
        result
      rescue StandardError => e
        record_call(method_name, monotonic_time - start, :error, e)
        raise
      ensure
        Thread.current[key] = false
      end
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def output_call(call)
      time_str = format_time(call[:execution_time])
      status_str = call[:status] == :error ? "[ERROR]" : ""
      puts "TRACE: #{call[:method_name]} #{status_str} took #{time_str}"
      puts "       Error: #{call[:error].class}: #{call[:error].message}" if call[:error]
    end

    def format_time(seconds)
      if seconds >= 1.0
        "#{seconds.round(3)}s"
      elsif seconds >= 0.001
        "#{(seconds * 1000).round(1)}ms"
      else
        "#{(seconds * 1_000_000).round(0)}µs"
      end
    end
  end
end
