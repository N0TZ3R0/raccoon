require 'net/ping'
require 'fileutils'

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

      Raccoon.logger.info("Running passive scan on #{target}")
      passive_scan(target, output_dir)

      case type
      when :normal
        Raccoon.logger.info("Running normal scan on #{target}")
        normal_scan(target, output_dir)
      when :less_aggressive
        Raccoon.logger.info("Running less aggressive scan on #{target}")
        light_scan(target, output_dir)
      when :aggressive
        Raccoon.logger.info("Running aggressive scan on #{target}")
        aggressive_scan(target, output_dir)
      else
        Raccoon.logger.error("Unknown scan type: #{type}")
        puts "Unknown scan type: #{type}"
      end
    end

    def self.passive_scan(target, output_dir = nil)
      begin
        Raccoon.logger.info("Starting WhatWeb scan on #{target}")
        output = `whatweb #{target}`
        save_output(output, output_dir, "whatweb_#{target}.txt")
        Raccoon.logger.info("WhatWeb scan completed on #{target}")
        puts output

        Raccoon.logger.info("Starting Sublist3r scan on #{target}")
        output = `sublist3r -d #{target}`
        save_output(output, output_dir, "sublist3r_#{target}.txt")
        Raccoon.logger.info("Sublist3r scan completed on #{target}")
        puts output

        Raccoon.logger.info("Starting theHarvester scan on #{target}")
        output = `theHarvester -d #{target} -b all`
        save_output(output, output_dir, "theHarvester_#{target}.txt")
        Raccoon.logger.info("theHarvester scan completed on #{target}")
        puts output
      rescue StandardError => e
        Raccoon.logger.error("Error during passive scan on #{target}: #{e.message}")
        puts "Error during passive scan on #{target}: #{e.message}"
      end
    end

    def self.light_scan(target, output_dir = nil)
      run_nmap_light(target, output_dir)
    end

    def self.normal_scan(target, output_dir = nil)
      run_nmap_normal(target, output_dir)
      if service_detected?(target, "http")
        run_nikto(target, output_dir)
      end
    end

    def self.aggressive_scan(target, output_dir = nil)
      run_nmap_aggressive(target, output_dir)
      if service_detected?(target, "http")
        run_nikto(target, output_dir)
      end
      if service_detected?(target, "smb")
        run_enum4linux(target, output_dir)
      end
      if service_detected?(target, "smtp")
        run_smtp_enum(target, output_dir)
      end
    end

    def self.run_nmap_light(target, output_dir = nil)
      run_nmap(target, "", output_dir)
    end

    def self.run_nmap_normal(target, output_dir = nil)
      run_nmap(target, "-sV -sC -O", output_dir)
    end

    def self.run_nmap_aggressive(target, output_dir = nil)
      run_nmap(target, "-sV -sC -p- -O -T4", output_dir)
    end

    def self.run_nmap(target, options, output_dir = nil)
      begin
        Raccoon.logger.info("Starting Nmap scan on #{target} with options: #{options}")
        output = `nmap #{options} #{target}`
        save_output(output, output_dir, "nmap_#{target}.txt")
        Raccoon.logger.info("Nmap scan completed on #{target}")
        puts output
      rescue StandardError => e
        Raccoon.logger.error("Error during Nmap scan on #{target}: #{e.message}")
        puts "Error during Nmap scan on #{target}: #{e.message}"
      end
    end

    def self.run_nikto(target, output_dir = nil)
      begin
        Raccoon.logger.info("Starting Nikto scan on #{target}")
        output = `nikto -h #{target}`
        save_output(output, output_dir, "nikto_#{target}.txt")
        Raccoon.logger.info("Nikto scan completed on #{target}")
        puts output
      rescue StandardError => e
        Raccoon.logger.error("Error during Nikto scan on #{target}: #{e.message}")
        puts "Error during Nikto scan on #{target}: #{e.message}"
      end
    end

    def self.run_enum4linux(target, output_dir = nil)
      begin
        Raccoon.logger.info("Starting enum4linux scan on #{target}")
        output = `enum4linux #{target}`
        save_output(output, output_dir, "enum4linux_#{target}.txt")
        Raccoon.logger.info("enum4linux scan completed on #{target}")
        puts output
      rescue StandardError => e
        Raccoon.logger.error("Error during enum4linux scan on #{target}: #{e.message}")
        puts "Error during enum4linux scan on #{target}: #{e.message}"
      end
    end

    def self.run_smtp_enum(target, output_dir = nil)
      begin
        Raccoon.logger.info("Starting SMTP enumeration on #{target}")
        output = `smtp-user-enum -M VRFY -U users.txt -t #{target}`
        save_output(output, output_dir, "smtp_enum_#{target}.txt")
        Raccoon.logger.info("SMTP enumeration completed on #{target}")
        puts output
      rescue StandardError => e
        Raccoon.logger.error("Error during SMTP enumeration on #{target}: #{e.message}")
        puts "Error during SMTP enumeration on #{target}: #{e.message}"
      end
    end

    def self.target_reachable?(target)
      check = Net::Ping::External.new(target)
      check.ping?
    end

    def self.service_detected?(target, service)
      begin
        nmap_output = `nmap -sV #{target}`
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

    def self.save_output(output, output_dir, filename)
      return unless output_dir

      File.open(File.join(output_dir, filename), 'w') do |file|
        file.write(output)
      end
    rescue StandardError => e
      Raccoon.logger.error("Error saving output to #{filename}: #{e.message}")
      puts "Error saving output to #{filename}: #{e.message}"
    end
  end
end
