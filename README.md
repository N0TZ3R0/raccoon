# Raccoon

## Description

Raccoon is a comprehensive reconnaissance tool designed for penetration testers and security enthusiasts. It provides both passive and active scanning capabilities, integrating various popular scanning tools to gather information about the target. The tool also includes functionalities for saving scan results and generating detailed reports.

## Goals

- Provide a unified interface for various reconnaissance tools
- Support passive and active scanning techniques
- Enable saving scan results to a specified directory
- Generate detailed reports from scan results
- Handle errors gracefully and provide useful logging

## Program Abilities

- **Passive Scanning**: Uses tools like WhatWeb, Sublist3r, and theHarvester to gather information without direct interaction.
- **Active Scanning**: Uses Nmap and other tools to perform detailed scans:
  - **Light Scan**: Basic Nmap scan without flags
  - **Normal Scan**: Nmap with service and OS detection, followed by Nikto if a web server is detected
  - **Aggressive Scan**: Full Nmap scan with all ports and service detection, followed by additional tools based on detected services (e.g., enum4linux for SMB, SMTP enumeration)
- **Output Saving**: Save scan results to a specified directory
- **Service Detection**: Detect specific services from Nmap scan results

## Setup Instructions

### Prerequisites

- Kali Linux or similar distribution
- Ruby installed (preferably managed via rbenv or RVM)
- Required tools installed (Nmap, Nikto, WhatWeb, Sublist3r, theHarvester, etc.)

### Installation

1. **Clone the Repository**
    ```bash
    git clone https://github.com/yourusername/raccoon.git
    cd raccoon
    ```

2. **Setup Environment**
    - Create a `.env` file with your OpenAI API key and tools list:
    ```dotenv
    OPENAI_API_KEY=your_openai_api_key
    TOOLS_PILE=["nmap", "nikto", "dnsrecon", "wafw00f", "sublist3r", "theHarvester", "smbmap", "enum4linux", "dirb", "whatweb", "smtp-user-enum"]
    ```

3. **Run Setup Script**
    ```bash
    chmod +x raccoon_setup.sh
    sudo ./raccoon_setup.sh
    ```

### Usage

#### Running Scans

1. **Help Command**
    ```bash
    raccoon --help
    ```
    Output:
    ```
    Available commands:
      --help          Show this help message
      -h [target]     Set the target for scanning
      -n [target]     Run a normal scan on the target
      -l [target]     Run a less aggressive scan on the target
      -a [target]     Run an aggressive scan on the target
      -r [scan_id]    Generate a report for the given scan ID
      -o [output_dir] Specify output directory for scan results
    ```

2. **Set Target**
    ```bash
    raccoon -h example.com
    ```

3. **Run Normal Scan**
    ```bash
    raccoon -n example.com -o ./scan_results
    ```

4. **Run Less Aggressive Scan**
    ```bash
    raccoon -l example.com -o ./scan_results
    ```

5. **Run Aggressive Scan**
    ```bash
    raccoon -a example.com -o ./scan_results
    ```

6. **Generate Report**
    ```bash
    raccoon -r scan_id
    ```

### Code Snippets

#### Example: Scanner Module

```ruby
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

    # Remaining methods...
  end
end
```

#### Example: Timer Module

```ruby
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
```

### License

Raccoon is released under the GPL-2.0 License. See the LICENSE file for more details.

---
