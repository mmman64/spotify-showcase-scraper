require "date"
require "bundler"
Bundler.require

require "open-uri"
require "sinatra/activerecord"

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "db/showcase.db",
)

ActiveRecord::Base.logger = nil

require_all './lib'
