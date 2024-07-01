require 'dotenv'

module Raccoon
  module EnvCreator
    def self.setup_environment
      # Load environment variables from .env file
      Dotenv.load('.env')
      puts "Environment variables loaded"
    end

    def self.set_anonymous_environment
      # Example logic for setting up an anonymous environment
      puts "Setting up anonymous environment"
      # Placeholder for changing MAC address, setting up VPN, etc.
    end
  end
end
