require 'sequel'
require 'yaml'

Sequel.extension :migration
Sequel::Model.plugin :update_or_create

module Bandiera
  class Db
    def self.connect
      database_url = ENV['DATABASE_URL']
      if database_url.nil?
        if ENV['DB_USERNAME'].nil? || ENV['DB_PASSWORD'].nil? || ENV['DB_HOSTNAME'].nil?
          raise ArgumentError, 'You must set a DATABASE_URL environment variable or DB_USERNAME, DB_PASSWORD and DB_HOSTNAME'
        end
        database_url = "mysql2://#{ENV['DB_USERNAME']}:#{ENV['DB_PASSWORD']}@#{ENV['DB_HOSTNAME']}/#{ENV['DB_DATABASE']}"
      end
      @db ||= Sequel.connect(database_url)
    end

    def self.disconnect
      @db.disconnect if @db
      @db = nil
    end

    def self.migrate
      Sequel::Migrator.apply(connect, migrations_dir)
    end

    def self.rollback
      version = (row = connect[:schema_info].first) ? row[:version] : nil
      Sequel::Migrator.apply(connect, migrations_dir, version - 1)
    end

    def self.migrations_dir
      File.join(File.dirname(__FILE__), '../../db/migrations')
    end

    def self.ready?
      connect.execute('SELECT 1')
      true
    rescue Sequel::Error
      false
    end
  end
end
