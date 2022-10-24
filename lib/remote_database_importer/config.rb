module RemoteDatabaseImporter
  class Config
    require "tty/config"
    require "colorize"

    def initialize
      @config = TTY::Config.new
      @config.filename = "remote_database_importer"
      @config.extname = ".yml"
      @config.append_path Dir.pwd
    end

    def read_or_create_configfile
      unless @config.exist?
        puts "===========================================================".colorize(:green)
        puts "Hi there! There is no config file yet, lets create one! 😄"
        create_default_config
        puts "===========================================================".colorize(:green)
      end
      @config.read
    end

    def ask(question, default: nil, options: nil)
      question += " (#{options.join(" / ")})" if options.present?
      question += " [#{default}]" if default.present?

      puts question.colorize(:light_blue)
      answer = $stdin.gets.chomp
      answer.present? ? answer : default
    end

    def create_default_config
      enter_new_environments = true
      environment_count = 1

      local_db_name = ask("Whats the name of the local database you wanna import to?", default: "myawesomeapp_development")
      @config.set(:local_db_name, value: local_db_name)
      puts

      while enter_new_environments
        puts "#{environment_count}. Environment".colorize(:green)
        env = ask("Whats the name of the #{environment_count}. environment you wanna add?", default: "staging")
        puts

        puts "Database settings:".colorize(:green)
        db_name = ask("Enter the DB name for the #{env} environment:", default: "myawesomeapp_#{env}")
        db_user = ask("Enter the DB user for the #{env} environment:", default: "deployer")
        puts

        puts "Connection settings:".colorize(:green)
        host = ask("Enter the IP or hostname of the DB server:", default: "myawesomeapp.com")
        dump_type = ask("Should the dump happen over a ssh connection or can pg_dump access the DB port directly? (if the DB lives on a seperat server pg_dump the way to go)", default: "pg_dump", options: ["ssh", "pg_dump"])

        ssh_user, ssh_port, postgres_port = nil
        if dump_type == "ssh"
          ssh_user = ask("Enter the username for the SSH connection:", default: "deployer")
          ssh_port = ask("Enter the port for the SSH connection:", default: "22")
        else
          postgres_port = ask("Enter the database port for the pg_dump command:", default: "5432")
        end
        puts

        env_config = {
          env.to_s => {
            "database" => {
              "name" => db_name,
              "user" => db_user
            },
            "connection" => {
              "host" => host,
              "dump_type" => dump_type,
              "postgres_port" => postgres_port,
              "ssh_user" => ssh_user,
              "ssh_port" => ssh_port
            }
          }
        }
        @config.append(env_config, to: :environments)

        continue = ask("Do you wanna add another environment? (anything other than 'yes' will exit)")
        if continue&.downcase == "yes"
          environment_count += 1
        else
          enter_new_environments = false
        end
      end

      @config.write
    end

    # TODO: validate user input
    # private
    # def validate_config(config)
    #   config.each do |key, value|
    #
    #   end
    # end
  end
end
