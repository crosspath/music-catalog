#!/usr/bin/env ruby
# frozen_string_literal: true

require "rubygems"
require "bundler/setup"

require "i18n"
require "io/console"
require "json"
require "mongo"

#----

def require_dir(dir)
  Dir[File.join(dir, "**", "*.rb")].sort.each do |file|
    require file
  end
end

require_dir("./src")

#----

Menu.main
