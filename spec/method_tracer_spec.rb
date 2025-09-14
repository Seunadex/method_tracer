# frozen_string_literal: true

class TestClass
  include MethodTracer

  def greet(name)
    "Hello, #{name}!"
  end

  def fail_method
    raise "Intentional failure"
  end
end

RSpec.describe MethodTracer do
  it "has a version number" do
    expect(MethodTracer::VERSION).not_to be_nil
  end

  it "traces a simple block and outputs JSON" do
    TestClass.trace_methods(:greet, :fail_method, threshold: 0.0, auto_output: true)

    instance = TestClass.new
    expect(instance.greet("World")).to eq("Hello, World!")

    expect { instance.fail_method }.to raise_error(RuntimeError, "Intentional failure")
  end
end
