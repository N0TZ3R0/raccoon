# lib/raccoon/scanner.rb
require 'net/ping'
require 'fileutils'
require 'json'
require_relative 'scanner_factory'

module Raccoon
  module Scanner
    TOOLS_PILE = JSON.parse(ENV['TOOLS_PILE'] || '[]')

    def self.run_scan(type, target, output_dir = nil)
      unless target_reachable?(target)
        Raccoon.logger.error("Target #{target} is not reachable.")
        puts "Target #{target} is not reachable."
        return
      end

      if TOOLS_PILE.empty?
        Raccoon.logger.error("No scanning tools available. Please install the necessary tools.")
        puts "No scanning tools available. Please install the necessary tools."
        return
      end

      if output_dir
        FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
      end

      passive_scan(target, output_dir)

      case type
      when :normal
        normal_scan(target, output_dir)
      when :less_aggressive
        light_scan(target, output_dir)
      when :aggressive
        aggressive_scan(target, output_dir)
      else
        Raccoon.logger.error("Unknown scan type: #{type}")
        puts "Unknown scan type: #{type}"
      end
    end

    def self.passive_scan(target, output_dir = nil)
      [:whatweb, :sublist3r, :theharvester].each do |tool|
        scanner = ScannerFactory.create(tool, target, output_dir)
        scanner.scan
      end
    end

    def self.light_scan(target, output_dir = nil)
      nmap_scanner = ScannerFactory.create(:nmap, target, output_dir)
      nmap_scanner.scan
    end

    def self.normal_scan(target, output_dir = nil)
      nmap_scanner = ScannerFactory.create(:nmap, target, output_dir)
      nmap_scanner.scan("-sV -sC -O")

      if service_detected?(target, "http")
        nikto_scanner = ScannerFactory.create(:nikto, target, output_dir)
        nikto_scanner.scan
      end
    end

    def self.aggressive_scan(target, output_dir = nil)
      nmap_scanner = ScannerFactory.create(:nmap, target, output_dir)
      nmap_scanner.scan("-sV -sC -p- -O -T4")

      if service_detected?(target, "http")
        nikto_scanner = ScannerFactory.create(:nikto, target, output_dir)
        nikto_scanner.scan
      end

      if service_detected?(target, "smb")
        enum4linux_scanner = ScannerFactory.create(:enum4linux, target, output_dir)
        enum4linux_scanner.scan
      end

      if service_detected?(target, "smtp")
        smtp_enum_scanner = ScannerFactory.create(:smtp_enum, target, output_dir)
        smtp_enum_scanner.scan
      end
    end

    def self.target_reachable?(target)
      check = Net::Ping::External.new(target)
      check.ping?
    end

    def self.service_detected?(target, service)
      nmap_scanner = ScannerFactory.create(:nmap, target)
      nmap_output = nmap_scanner.scan("-sV")

      regex = case service
              when "http"
                /http/
              when "smb"
                /smb|microsoft-ds/
              when "smtp"
                /smtp/
              else
                /#{service}/
              end
      !!(nmap_output =~ regex)
    rescue StandardError => e
      Raccoon.logger.error("Error detecting service #{service} on #{target}: #{e.message}")
      false
    end
  end
end
