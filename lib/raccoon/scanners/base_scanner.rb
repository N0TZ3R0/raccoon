module Raccoon
  module Scanners
    class BaseScanner
      def initialize(target, output_dir = nil)
        @target = target
        @output_dir = output_dir
      end

      def scan
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      protected

      def save_output(output, filename)
        return unless @output_dir

        File.open(File.join(@output_dir, filename), 'w') do |file|
          file.write(output)
        end
      rescue StandardError => e
        Raccoon.logger.error("Error saving output to #{filename}: #{e.message}")
        puts "Error saving output to #{filename}: #{e.message}"
      end
    end
  end
end
