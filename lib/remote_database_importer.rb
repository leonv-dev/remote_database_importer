# frozen_string_literal: true

require_relative "remote_database_importer/version"
require_relative "remote_database_importer/operation"

module RemoteDatabaseImporter
  class Error < StandardError; end
  require_relative "railtie" if defined?(Rails)
end
