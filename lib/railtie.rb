require "remote_database_importer"
require "rails"

module RemoteDatabaseImporter
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/remote_database_importer.rake"
    end
  end
end
