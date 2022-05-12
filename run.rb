#!/usr/bin/env ruby

require 'json'
require 'mongo'
require 'io/console'
require 'readline'

#----

def require_dir(dir)
  Dir[File.join(dir, '**', '*.rb')].sort.each do |file|
    require file
  end
end

require_dir('./src')

#----

Menu.main
