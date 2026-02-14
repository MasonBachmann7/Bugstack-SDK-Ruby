# frozen_string_literal: true

require_relative "lib/bugstack/version"

Gem::Specification.new do |spec|
  spec.name = "bugstack"
  spec.version = Bugstack::VERSION
  spec.authors = ["BugStack"]
  spec.email = ["team@bugstack.dev"]

  spec.summary = "Official BugStack SDK for Ruby"
  spec.description = "Capture, report, and auto-fix production errors with BugStack. " \
                     "Zero runtime dependencies. Framework integrations for Rails, Sinatra, and more."
  spec.homepage = "https://bugstack.dev"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/MasonBachmann7/bugstack-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/MasonBachmann7/bugstack-ruby/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/MasonBachmann7/bugstack-ruby/issues"

  spec.files = Dir.glob("lib/**/*.rb") + %w[
    README.md LICENSE CHANGELOG.md
  ]
  spec.require_paths = ["lib"]

  # Zero runtime dependencies — stdlib only

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
end
