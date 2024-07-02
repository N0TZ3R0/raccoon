module Raccoon
  module Scanners
    class NmapScanner < BaseScanner
      def scan(options = "")
        Raccoon.logger.info("Starting Nmap scan on #{@target} with options: #{options}")
        output = `nmap #{options} #{@target}`
        save_output(output, "nmap_#{@target}.txt")
        Raccoon.logger.info("Nmap scan completed on #{@target}")
        puts output
      rescue StandardError => e
        Raccoon.logger.error("Error during Nmap scan on #{@target}: #{e.message}")
        puts "Error during Nmap scan on #{@target}: #{e.message}"
      end
    end
  end
end
