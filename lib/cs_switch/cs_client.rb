require "cloudstack_client"
require "yaml"

module CsSwitch
  class CsClient

    def initialize(settings)
      @settings = settings
      @config ||= load_configuration
      @cs ||= CloudstackClient::Client.new(
        @config[:url],
        @config[:api_key],
        @config[:secret_key]
      )
      @cs.debug = true if settings[:debug]
      @cs
    end

    def load_configuration
      unless File.exists?(@settings[:config_file])
        message = "Configuration file '#{@settings[:config_file]}' not found."
        message += "Please run \'cloudstack-cli environment add\' to create one."
        raise message
      end
      begin
        config = YAML::load(IO.read(@settings[:config_file]))
      rescue => e
        message = "Can't load configuration from file '#{@settings[:config_file]}'."
        message += "Message: #{e.message}" if @settings[:debug]
        message += "Backtrace:\n\t#{e.backtrace.join("\n\t")}" if @settings[:debug]
        raise message
      end

      env ||= config[:default]
      if env
        unless config = config[env]
          raise "Can't find environment #{env}."
        end
      end
      unless config.key?(:url) && config.key?(:api_key) && config.key?(:secret_key)
        message = "The environment #{env || '\'-\''} does not contain all required keys."
        message += "Please check with 'cloudstack-cli environment list' and set a valid default environment."
        raise message
      end
      config
    end

    def find_offerings(options)
      if source_domain = find_domain(options[:source_domain])
        @cs.list_service_offerings(
          domain_id: source_domain['id'],
          listall: true
        )
      else
        raise "Source domain \"#{options[:source_domain]}\" not found."
      end
    end

    def find_domain(domain)
      @cs.list_domains(name: domain).first
    end

  end
end
