module RemoteDatabaseImporter
  class Operation
    require "remote_database_importer/config"
    require "ruby-progressbar"
    require "pry"

    LOG_FILE = "tmp/remote_database_importer.log"

    def initialize
      config_handler = RemoteDatabaseImporter::Config.new
      @config = config_handler.read_or_create_configfile
    end

    def environments
      @config.fetch("environments")
    end

    def select_environment
      if environments.size > 1
        puts "Select the operation environment:"

        environments.map(&:keys).flatten.each_with_index do |env, index|
          puts "#{index} for #{env.capitalize}"
        end
        env = environments[$stdin.gets.chomp.to_i].values[0]
        raise "Environment couldn't be found!" if env.blank?
        return env
      end

      environments[0].values[0]
    end

    def import
      env = select_environment
      tasks = [
        terminate_current_db_sessions,
        dump_remote_db(env),
        drop_and_create_local_db,
        restore_db(env),
        run_migrations,
        clear_logfile
      ]

      progressbar = ProgressBar.create(title: "Import remote DB", total: tasks.length, format: "%t %p%% %B %a")
      tasks.each do |task|
        was_good = system(task)
        return "Can't continue, following task failed: #{task} - checkout the logfile: #{LOG_FILE}" unless was_good
        progressbar.increment
      end
    end

    private

    def terminate_current_db_sessions
      "psql -d #{@config.fetch("local_db")} -c 'SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid();' > #{LOG_FILE}"
    end

    def dump_remote_db(env)
      ssh_user = env["ssh_connection"]["user"]
      ssh_host = env["ssh_connection"]["host"]
      db_user = env["database"]["user"]
      db_name = env["database"]["name"]
      "ssh #{ssh_user}@#{ssh_host} 'pg_dump -Fc -U #{db_user} -d #{db_name} -h localhost -C' > #{db_name}.dump"
    end

    def drop_and_create_local_db
      "rails db:environment:set RAILS_ENV=development; rake db:drop db:create > #{LOG_FILE}"
    end

    def restore_db(env)
      db_name = env["database"]["name"]
      "pg_restore --jobs 8 --no-privileges --no-owner --dbname #{@config.fetch("local_db")} #{db_name}.dump"
    end

    def run_migrations
      "rake db:migrate > #{LOG_FILE}"
    end

    def clear_logfile
      "rm #{LOG_FILE}"
    end
  end
end
