require 'logger'
require 'dotenv/load'
require_relative 'raccoon/scanner'
require_relative 'raccoon/report_generator'
require_relative 'raccoon/timer'
require_relative 'raccoon/env_creator'

class Raccoon
  class << self
    attr_accessor :logger
  end

  @logger = Logger.new('logs/raccoon.log')

  def initialize
    @logger = self.class.logger
    Raccoon::EnvCreator.setup_environment
  end

  def help
    puts <<~HELP
      Available commands:
        --help          Show this help message
        -h [target]     Set the target for scanning
        -n [target]     Run a normal scan on the target
        -l [target]     Run a less aggressive scan on the target
        -a [target]     Run an aggressive scan on the target
        -r [scan_id]    Generate a report for the given scan ID
        -o [output_dir] Specify output directory for scan results
    HELP
    @logger.info('Displayed help information')
  end

  def set_target(target)
    puts "Target set to #{target}"
    @logger.info("Target set to #{target}")
  end

  def scan(scan_type, target, output_dir = nil)
    Raccoon::Scanner.run_scan(scan_type, target, output_dir)
    @logger.info("Scan type #{scan_type} initiated on #{target} with output directory: #{output_dir}")
  end

  def generate_report(scan_id)
    scan_results = "Results for scan ID #{scan_id}"
    report_type = :standard
    Raccoon::ReportGenerator.generate_report(scan_results, report_type)
    @logger.info("Report generated for scan ID #{scan_id}")
  end

  def schedule_scans(scan_list)
    Raccoon::Timer.schedule_scans(scan_list)
  end
end
