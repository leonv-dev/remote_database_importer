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
        puts "=============================================================".colorize(:green)
        puts "Hi there! I see there is no config file yet, lets create one!"
        add_default_config
        puts "=============================================================".colorize(:green)
      end
      @config.read
    end

    def ask(question, default:)
      puts "#{question} [#{default}]".colorize(:light_blue)
      answer = $stdin.gets.chomp
      answer.present? ? answer : default
    end

    def add_default_config
      enter_new_environments = true
      environment_count = 1

      local_db = ask("Whats the name of your local database you wanna import to?", default: "myawesomeapp_development")
      @config.set(:local_db, value: local_db)
      puts

      while enter_new_environments
        puts "#{environment_count}. Environment".colorize(:green)
        env = ask("Whats the name of first environment you wanna add?", default: "staging")
        puts

        puts "Database settings".colorize(:green)
        db_name = ask("Enter the DB name for the #{env} environment:", default: "myawesomeapp_#{env}")
        db_user = ask("Enter the DB user for the #{env} environment:", default: "deployer")
        puts

        puts "SSH settings".colorize(:green)
        ssh_host = ask("Enter the IP address or hostname for the SSH connection:", default: "myawesomeapp.com")
        ssh_user = ask("Enter the username for the SSH connection:", default: "deployer")
        puts

        env_config = {
          env.to_s => {
            "ssh_connection" => {
              "host" => ssh_host,
              "user" => ssh_user
            },
            "database" => {
              "name" => db_name,
              "user" => db_user
            }
          }
        }
        @config.append(env_config, to: :environments)

        continue = ask("Do you wanna add another environment?", default: "no")
        if continue.downcase == "no"
          enter_new_environments = false
        end
        environment_count += 1
      end

      @config.write
    end
  end
end
