module RemoteDatabaseImporter
  class Operation
    require("tty/config")
    require("pry")

    def initialize
      @config = TTY::Config.new
      @config.filename = "remote_database_importer"
      @config.extname = ".json"
      @config.append_path Dir.pwd

      if @config.exist?
        @config.read
      else
        puts "============================================================="
        puts "Hi there! I see there is no config file yet, lets create one!"
        add_default_config
        puts "============================================================="
      end
    end

    def ask(question, default:)
      puts "#{question} [#{default}]"
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
        puts "#{environment_count}. Environment"
        env = ask("Whats the name of first environment you wanna add?", default: "staging")
        puts

        puts "#{environment_count}. Environment - SSH settings"
        ssh_host = ask("Enter the IP address or hostname for the SSH connection:", default: "myawesomeapp.com")
        ssh_user = ask("Enter the username for the SSH connection:", default: "deployer")
        puts

        puts "#{environment_count}. Environment - Database settings"
        db_name = ask("Enter the DB name for the #{env} environment:", default: "myawesomeapp_#{env}")
        db_user = ask("Enter the DB user for the #{env} environment:", default: ssh_user)
        puts

        env_config = {
          "#{env}": {
            ssh_connection: {
              host: ssh_host,
              user: ssh_user
            },
            database: {
              name: db_name,
              user: db_user
            }
          }
        }
        @config.append(env_config, to: :environments)

        continue = ask("Do you wanna add another environment?", default: "No")
        if continue.downcase == "no"
          enter_new_environments = false
        end
      end

      @config.write
    end

    def environments
      @config.fetch(:environments)
    end

    def environment(env_index)
      environments[env_index].values[0]
    end

    def local_db
      @config.fetch(:local_db)
    end

    def import
      puts "Select the operation environment:"
      enviroment_names = environments.map(&:keys).flatten
      enviroment_names.each_with_index do |env, index|
        puts "#{index} for #{env.capitalize}"
      end
      env = environment($stdin.gets.chomp.to_i)
      raise "Environment couldn't be found!" if env.blank?
      puts env

      # Export und Importjobs die ausgeführt werden
      tasks = [
        "psql -d #{local_db} -c 'SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid();' > remote_database_importer.log",
        "ssh #{env["ssh_connection"]["user"]}@#{env["ssh_connection"]["host"]} 'pg_dump -Fc -U #{env["database"]["user"]} -d #{env["database"]["name"]} -h localhost -C' > #{env["database"]["name"]}.dump",
        "rails db:environment:set RAILS_ENV=development; rake db:drop db:create > remote_database_importer.log",
        "pg_restore --jobs 8 --no-privileges --no-owner --dbname #{local_db} #{env["database"]["name"]}.dump",
        "rake db:migrate > remote_database_importer.log",
        "rm remote_database_importer.log"
      ]

      # progressbar = ProgressBar.create(title: "DB von #{env.capitalize} importieren", total: tasks.length, format: '%t %p%% %B %a')

      tasks.each do |task|
        puts "run: #{task}"
        was_good = system(task)
        return "Can't continue, following task failed: #{task}" unless was_good
        # progressbar.increment
      end

      # Nicht im Task Array, damit kein Output angezeigt wird
      # `stellar remove #{env}; stellar snapshot #{env}`
    end
  end
end
