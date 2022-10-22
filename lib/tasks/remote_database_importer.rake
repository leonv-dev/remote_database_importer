namespace :remote_database do
  desc "Pulls a database to your filesystem"
  task import: :environment do
    importer = RemoteDatabaseImporter::Operation.new
    importer.import
  end
end
