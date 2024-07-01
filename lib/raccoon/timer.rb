module Raccoon
  module Timer
    def self.schedule_scans(scan_list)
      scan_list.each do |scan|
        type, target, delay = scan
        sleep(delay)
        Raccoon::Scanner.run_scan(type, target)
      end
    rescue StandardError => e
      Raccoon.logger.error("Error scheduling scans: #{e.message}")
      puts "Error scheduling scans: #{e.message}"
    end
  end
end
