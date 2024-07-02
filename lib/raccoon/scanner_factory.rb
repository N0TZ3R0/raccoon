# lib/raccoon/scanner_factory.rb
require_relative 'scanners/base_scanner'
require_relative 'scanners/nmap_scanner'
# Require other scanner classes

module Raccoon
  class ScannerFactory
    def self.create(scanner_type, target, output_dir = nil)
      case scanner_type
      when :nmap
        Scanners::NmapScanner.new(target, output_dir)
      when :whatweb
        Scanners::WhatWebScanner.new(target, output_dir)
      # Add other scanner types
      else
        raise ArgumentError, "Unknown scanner type: #{scanner_type}"
      end
    end
  end
end
