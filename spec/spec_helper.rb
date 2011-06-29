$LOAD_PATH << "." unless $LOAD_PATH.include?(".")

begin
  require "rubygems"
  require "bundler"

  if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new("0.9.5")
    raise RuntimeError, "Your bundler version is too old." +
     "Run `gem install bundler` to upgrade."
  end

  # Set up load paths for all bundled gems
  Bundler.setup
rescue Bundler::GemNotFound
  raise RuntimeError, "Bundler couldn't find some gems." +
    "Did you run \`bundlee install\`?"
end

Bundler.require
require File.expand_path('../../lib/acts-as-taggable-on-padrino', __FILE__)

unless [].respond_to?(:freq)
  class Array
    def freq
      k=Hash.new(0)
      each {|e| k[e]+=1}
      k
    end
  end
end

ENV['DB'] ||= 'sqlite3'

database_yml = File.expand_path('../database.yml', __FILE__)
if !File.exists?(database_yml)
  raise "Please create #{database_yml} first to configure your database. Take a look at: #{database_yml}.sample"
end

active_record_configuration = YAML.load_file(database_yml)[ENV['DB']]

require 'active_support/core_ext/logger'
ActiveRecord::Base.establish_connection(active_record_configuration)
ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), "debug.log"))

ActiveRecord::Base.silence do
  ActiveRecord::Migration.verbose = false

  load(File.dirname(__FILE__) + '/schema.rb')
  load(File.dirname(__FILE__) + '/models.rb')
end

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.start

RSpec.configure do |config|
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
