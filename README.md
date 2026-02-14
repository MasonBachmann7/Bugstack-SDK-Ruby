# bugstack-ruby

Official Ruby SDK for [BugStack](https://bugstack.dev) — capture, report, and auto-fix production errors.

[![Gem Version](https://badge.fury.io/rb/bugstack.svg)](https://rubygems.org/gems/bugstack)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Installation

```ruby
gem "bugstack"
```

Or install directly:

```bash
gem install bugstack
```

## Quick Start

```ruby
require "bugstack"

Bugstack.init(api_key: "bs_live_...")

begin
  risky_operation
rescue => e
  Bugstack.capture_exception(e)
end
```

## Block Configuration

```ruby
Bugstack.init do |config|
  config.api_key = "bs_live_..."
  config.environment = "production"
  config.auto_fix = true
  config.debug = true
end
```

## Framework Integrations

### Rails

Add to your Gemfile:

```ruby
gem "bugstack"
```

Create an initializer:

```ruby
# config/initializers/bugstack.rb
Bugstack.init do |config|
  config.api_key = Rails.application.credentials.bugstack_api_key
  config.environment = Rails.env
  config.auto_fix = true
end
```

The Railtie automatically inserts Rack middleware for exception capture.

### Sinatra

```ruby
require "sinatra"
require "bugstack"
require "bugstack/integrations/sinatra"

Bugstack.init(api_key: "bs_live_...")

class MyApp < Sinatra::Base
  register Bugstack::Integrations::Sinatra

  get "/" do
    "Hello!"
  end
end
```

### Generic (at_exit hook)

```ruby
require "bugstack"
require "bugstack/integrations/generic"

Bugstack.init(api_key: "bs_live_...")
Bugstack::Integrations::Generic.install!
```

## Configuration

```ruby
Bugstack.init do |config|
  config.api_key = "bs_live_..."        # Required
  config.environment = "production"     # Default: "production"
  config.auto_fix = true                # Enable AI-powered auto-fix
  config.debug = false                  # Log SDK activity
  config.dry_run = false                # Log without sending
  config.enabled = true                 # Kill switch
  config.deduplication_window = 300     # Seconds (default: 5 min)
  config.timeout = 5.0                  # HTTP timeout in seconds
  config.max_retries = 3                # Retry attempts
  config.ignored_errors = [             # Errors to skip
    SystemExit,
    SignalException,
    "expected error message",
  ]
  config.before_send = ->(event) {      # Inspect/modify/drop events
    event  # return nil to drop
  }
end
```

## Data Transparency

### `before_send` Hook

```ruby
Bugstack.init do |config|
  config.api_key = "bs_live_..."
  config.before_send = ->(event) {
    # Drop health check errors
    return nil if event.request&.dig(:route)&.include?("/health")

    # Redact sensitive data
    event.metadata.delete("secret")

    event
  }
end
```

### `dry_run` Mode

```ruby
Bugstack.init(api_key: "bs_live_...", dry_run: true)
# Prints: [BugStack DryRun] Would send: { ... }
```

## What Gets Sent

```json
{
  "apiKey": "bs_live_...",
  "error": {
    "message": "undefined method 'foo' for nil",
    "stackTrace": "NoMethodError: undefined method...",
    "file": "app/controllers/users_controller.rb",
    "function": "show",
    "fingerprint": "a1b2c3d4e5f6g7h8"
  },
  "environment": {
    "language": "ruby",
    "languageVersion": "3.2.0",
    "framework": "rails",
    "frameworkVersion": "7.1.0",
    "os": "x86_64-linux",
    "sdkVersion": "1.0.0"
  },
  "timestamp": "2026-01-15T08:30:00Z"
}
```

Zero runtime gem dependencies. No cookies, IP addresses, or user data.

## License

MIT — see [LICENSE](LICENSE).
