require "thor"
require "cs_switch/version"
require "cs_switch/cs_client"

module CsSwitch
  class Cli < Thor
    include Thor::Actions

    package_name "cs_switch"

    class_option :config_file,
      default: File.join(Dir.home, '.cloudstack-cli.yml'),
      aliases: '-c',
      desc: 'Location of your cloudstack-cli configuration file'

    class_option :env,
      aliases: '-e',
      desc: 'Environment to use'

    class_option :debug,
      desc: 'Enable debug output',
      type: :boolean,
      default: false

    # catch control-c and exit
    trap("SIGINT") do
      puts
      puts "exiting.."
      exit!
    end

    # exit with return code 1 in case of a error
    def self.exit_on_failure?
      true
    end

    desc "version", "Print version number"
    def version
      say "cs_switch v#{CsSwitch::VERSION}"
    end
    map %w(-v --version) => :version

    desc "sql", "Generate SQL required for compute offering domain switch"
    option :source_domain,
      desc: "source domain",
      required: true,
      aliases: '-s'
    option :destination_domain,
      desc: "destination domain",
      default: "ROOT",
      aliases: '-d'
    option :limit,
      desc: "limit on a certain offering name",
      aliases: '-l'
    option :print_offers,
      desc: "print offering(s) at the begining of the output",
      type: :boolean,
      default: false,
      aliases: '-p'
    def sql
      cs = CsClient.new(options)
      offerings = cs.find_offerings(options)

      if offerings.size < 1
        say "No offerings found.", :yellow
        exit
      end

      if options[:print_offers]
        puts "/*"
        say "Found the following offering#{ 's' if offerings.size > 1 } in domain #{options[:source_domain]}:", :yellow
        offerings.each do |offering|
          puts "  [#{offering["id"]}] #{offering["name"]}"
        end
        puts "*/"
        puts
      end

      unless destination = cs.find_domain(options[:destination_domain])
        raise "Destination domain #{options[:destination_domain]} not found."
      end

      cloudstack_sql(offerings, destination)
      puts
      amysta_sql(offerings, destination)

    rescue => e
      say "ERROR: ", :red
      puts e.message
    end

    no_commands do
      def cloudstack_sql(offerings, destination)
        puts "/* CloudStack database update statements */"
        offerings.each do |offering|
          print "UPDATE disk_offering SET domain_id = "
          # FIXME Domain ID is db id and NOT uuid
          print(destination["name"] == "ROOT" ? "1" : destination["id"])
          puts " WHERE uuid = \"#{offering['id']}\";"
        end
      end

      def amysta_sql(offerings, destination)
        puts "/* Amysta database update statements */"
        offerings.each do |offering|
          print "UPDATE Resources SET Creation_Domain = (SELECT ID_Domain FROM Domains WHERE name = \"#{destination["name"]}\")"
          print ", Public = 1" if destination["name"] == "ROOT"
          puts " WHERE REF_Resource = \"#{offering['id']}\";"

          print "UPDATE Prices set ID_Catalog = (SELECT ID_Domain FROM Domains WHERE name = \"#{destination["name"]}\")"
          puts " WHERE ID_Resource IN (SELECT ID_Resource FROM Resources WHERE REF_Resource = \"#{offering['id']}\");"
        end
      end
    end

  end
end
