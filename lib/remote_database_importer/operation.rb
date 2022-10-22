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
        @current_environment = env
        return
      end

      @current_environment = environments[0].values[0]
    end

    def import
      select_environment
      tasks = [
        terminate_current_db_sessions,
        dump_remote_db,
        drop_and_create_local_db,
        restore_db,
        run_migrations,
        remove_logfile,
        remove_dumpfile,
      ]

      puts "Be aware, you may get asked for a password for the ssh or db connection"
      progressbar = ProgressBar.create(title: "Import remote DB", total: tasks.length, format: "%t %p%% %B %a")
      tasks.each do |task|
        was_good = system(task)
        return "Can't continue, following task failed: #{task} - checkout the logfile: #{LOG_FILE}" unless was_good
        progressbar.increment
      end
    end

    private

    # terminate local db sessions, otherwise the db can't be dropped
    def terminate_current_db_sessions
      "psql -d #{@config.fetch("local_db_name")} -c 'SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid();' > #{LOG_FILE}"
    end

    def dump_remote_db
      env = @current_environment
      host = env["connection"]["host"]
      db_name = env["database"]["name"]
      db_user = env["database"]["user"]
      dump_type = env["connection"]["dump_type"]
      ssh_user = env["connection"]["ssh_user"]
      ssh_port = env["connection"]["ssh_port"]
      postgres_port = env["connection"]["postgres_port"]

      if dump_type == 'ssh'
        "ssh #{ssh_user}@#{host} -p #{ssh_port} 'pg_dump -Fc -U #{db_user} -d #{db_name} -h localhost -C' > #{db_dump_location}"
      else
        "pg_dump -Fc 'host=#{host} dbname=#{db_name} user=#{db_user} port=#{postgres_port}' > #{db_dump_location}"
      end
    end

    def drop_and_create_local_db
      "rails db:environment:set RAILS_ENV=development; rake db:drop db:create > #{LOG_FILE}"
    end

    def restore_db
      "pg_restore --jobs 8 --no-privileges --no-owner --dbname #{@config.fetch("local_db_name")} #{db_dump_location}"
    end

    def run_migrations
      "rake db:migrate > #{LOG_FILE}"
    end

    def remove_logfile
      "rm #{LOG_FILE}"
    end

    def remove_dumpfile
      "rm #{db_dump_location}"
    end

    def db_dump_location
      "tmp/#{@current_environment["database"]["name"]}.dump"
    end
  end
end
