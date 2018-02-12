require 'bundler'
Bundler.require(:default, :development)
Dotenv.load

module Chantoru
  require_relative 'chantoru/scraper.rb'
  require_relative 'chantoru/notifier.rb'
end
