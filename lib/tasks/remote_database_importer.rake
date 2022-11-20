namespace :remote_database do
  desc "Pulls a database to your filesystem"
  task import: :environment do
    RemoteDatabaseImporter::Operation.new.import
  end
end
