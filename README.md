[![Ruby](https://github.com/Seunadex/method_tracer/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/Seunadex/method_tracer/actions/workflows/main.yml)

# MethodTracer

MethodTracer is a lightweight Ruby mixin for targeted method tracing. It wraps instance methods, measures wall-clock runtime, flags errors, and can stream results to your logger without pulling in a full APM agent. Use it to surface slow paths in production or gather quick instrumentation while debugging.

## Highlights
- Wrap only the methods you care about; public, protected, and private methods are supported.
- Records duration, success/error state, and timestamps with thread-safe storage.
- Configurable threshold to ignore fast calls and optional log streaming via `Logger`.
- Zero dependencies beyond the Ruby standard library, keeping overhead minimal.

## Installation

This project has not yet been published to RubyGems.

Add it to your Gemfile directly from GitHub:

```ruby
# Gemfile
gem "method_tracer", github: "Seunadex/method_tracer"
```

Then install:

```bash
bundle install
```

For local development or experimentation:

```bash
git clone https://github.com/Seunadex/method_tracer.git
cd method_tracer
bundle exec rake install
```

## Usage

Include `MethodTracer` in any class whose instance methods you want to observe. Register the target methods with optional settings.

```ruby
require "method_tracer"

class Worker
  include MethodTracer

  def perform(user_id)
    expensive_call(user_id)
  end

  private

  def expensive_call(id)
    # work...
  end
end

Worker.trace_methods(:perform, threshold: 0.005, auto_output: true)

Worker.new.perform(42)
```

With `auto_output: true`, each invocation prints a colorized summary:

```
TRACE: Worker#perform [OK] took 6.3ms
```

To inspect trace results programmatically, manage the tracer yourself:

```ruby
tracer = MethodTracer::SimpleTracer.new(Worker, threshold: 0.002)
tracer.trace_method(:perform)

Worker.new.perform(42)

pp tracer.fetch_results
# => {
#      total_calls: 1,
#      total_time: 0.0063,
#      calls: [
#        { method_name: "Worker#perform", execution_time: 0.0063, status: :success, ... }
#      ]
#    }
```

### Options

- `threshold` (Float, default `0.001`): minimum duration (in seconds) to record.
- `auto_output` (Boolean, default `false`): emit a log line using `Logger` for each recorded call.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake spec` to execute the test suite. You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version in `lib/method_tracer/version.rb`, and then run `bundle exec rake release`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Seunadex/method_tracer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/Seunadex/method_tracer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT). See `LICENSE.txt` for details.

## Code of Conduct

Everyone interacting in the MethodTracer project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/Seunadex/method_tracer/blob/main/CODE_OF_CONDUCT.md).
