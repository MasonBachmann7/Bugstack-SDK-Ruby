# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-02-13

### Added

- Core SDK with `Bugstack.init` and `Bugstack.capture_exception`
- Background thread transport with retry and exponential backoff
- SHA-256 error fingerprinting and client-side deduplication
- `before_send` hook for event inspection/modification/filtering
- `ignored_errors` for skipping specific error types or messages
- `dry_run` mode for transparent debugging
- `enabled` kill switch
- Block-style configuration
- Rails integration via Railtie and Rack middleware
- Sinatra integration via `register`
- Generic integration via `at_exit` hook
- Zero runtime gem dependencies
