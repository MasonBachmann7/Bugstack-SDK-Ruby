# frozen_string_literal: true

require "digest/sha2"

module Bugstack
  module Fingerprint
    # Generate a stable SHA-256 fingerprint for an error.
    #
    # @param exception_type [String]
    # @param file [String]
    # @param function [String]
    # @param line [Integer, nil]
    # @return [String] 16-char hex fingerprint
    def self.generate(exception_type, file, function, line = nil)
      parts = [exception_type, file, function]
      parts << line.to_s if line
      key = parts.join(":")
      Digest::SHA256.hexdigest(key)[0, 16]
    end

    # Extract file, function, and line from an exception's backtrace.
    #
    # @param exception [Exception]
    # @return [Array<(String, String, String, Integer)>]
    #   [exception_type, file, function, line]
    def self.extract_location(exception)
      exception_type = exception.class.name

      bt = exception.backtrace
      return [exception_type, "", "", nil] if bt.nil? || bt.empty?

      # Parse the first backtrace line: "file:line:in `method'"
      first_line = bt.first
      if first_line =~ /\A(.+):(\d+):in [`'](.+)'\z/
        file = Regexp.last_match(1)
        line = Regexp.last_match(2).to_i
        function = Regexp.last_match(3)
        [exception_type, file, function, line]
      else
        [exception_type, first_line, "", nil]
      end
    end

    # Format an exception's backtrace as a string.
    #
    # @param exception [Exception]
    # @return [String]
    def self.format_backtrace(exception)
      bt = exception.backtrace
      return "#{exception.class}: #{exception.message}" if bt.nil? || bt.empty?

      lines = ["#{exception.class}: #{exception.message}"]
      bt.each { |frame| lines << "  from #{frame}" }
      lines.join("\n")
    end
  end

  # Client-side error deduplicator.
  # Prevents the same error (by fingerprint) from being reported
  # more than once within a configurable time window.
  class Deduplicator
    def initialize(window: 300.0)
      @cache = {}
      @window = window
      @mutex = Mutex.new
    end

    # Check if an error should be sent. Thread-safe.
    #
    # @param fingerprint [String]
    # @return [Boolean]
    def should_send?(fingerprint)
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      @mutex.synchronize do
        last_sent = @cache[fingerprint]
        if last_sent && (now - last_sent) < @window
          return false
        end

        @cache[fingerprint] = now
        cleanup(now)
        true
      end
    end

    def clear
      @mutex.synchronize { @cache.clear }
    end

    private

    def cleanup(now)
      @cache.delete_if { |_, ts| (now - ts) >= @window }
    end
  end
end
