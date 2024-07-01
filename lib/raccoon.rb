require 'logger'
require 'dotenv/load' # Ensure .env is loaded
require_relative 'raccoon/scanner'
require_relative 'raccoon/report_generator'
require_relative 'raccoon/timer'

class Raccoon
  @logger = Logger.new('logs/raccoon.log')

  class << self
    attr_accessor :logger
  end

  def initialize
    @logger = Raccoon.logger
    Raccoon::EnvCreator.setup_environment if defined?(Raccoon::EnvCreator)
  end

  def help
    puts <<-HELP
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

  def target(target)
    puts "Target set to #{target}"
    @logger.info("Target set to #{target}")
  end

  def scan_type(scan_flag, target, output_dir = nil)
    type = case scan_flag
           when '-n'
             :normal
           when '-l'
             :less_aggressive
           when '-a'
             :aggressive
           else
             :unknown
           end
    if type == :unknown
      puts "Unknown scan type: #{scan_flag}"
      @logger.error("Unknown scan type: #{scan_flag}")
      return
    end
    Raccoon::Scanner.run_scan(type, target, output_dir)
    @logger.info("Scan type #{scan_flag} initiated on #{target} with output directory: #{output_dir}")
  end

  def report(scan_id)
    scan_results = "Results for scan ID #{scan_id}"
    report_type = :standard
    Raccoon::ReportGenerator.generate_report(scan_results, report_type)
    @logger.info("Report generated for scan ID #{scan_id}")
  end

  def schedule_scans(scan_list)
    Raccoon::Timer.schedule_scans(scan_list)
  end
end
