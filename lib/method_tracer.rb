# frozen_string_literal: true

require_relative "method_tracer/version"
require_relative "method_tracer/simple_tracer"

# Public: Mixin that adds lightweight method tracing to classes.
#
# When included, this module extends the host class with a class-level
# API (`trace_methods`) that wraps selected instance methods using
# `MethodTracer::SimpleTracer`. Wrapped methods record execution timing and
# errors with minimal overhead, suitable for ad-hoc performance debugging
# in development or selective tracing in production.
#
# Example
#   class Worker
#     include MethodTracer
#     def perform; do_work; end
#   end
#   Worker.trace_methods(:perform, threshold: 0.005, auto_output: true)
#
# See `MethodTracer::SimpleTracer` for available options.
module MethodTracer
  class Error < StandardError; end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Class-level API mixed into including classes.
  #
  # Provides `trace_methods`, which wraps the specified instance methods on the
  # target class using `MethodTracer::SimpleTracer`. Each wrapped method records
  # execution metrics (duration, status, errors) with minimal intrusion.
  #
  # Usage:
  #   class MyService
  #     include MethodTracer
  #     def call; expensive_work; end
  #   end
  #   MyService.trace_methods(:call, threshold: 0.005, auto_output: true)
  module ClassMethods
    def trace_methods(*method_names, **options)
      tracer = SimpleTracer.new(self, **options)
      method_names.each do |method_name|
        tracer.trace_method(method_name)
      end
    end
  end
end
