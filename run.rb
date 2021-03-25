#!/usr/bin/env ruby

require 'json'
require 'sequel'
require 'io/console'
require 'readline'

#----

CONFIG = JSON.parse(File.read("#{__dir__}/config.json"), symbolize_names: true)
MUSIC_DIR = CONFIG[:dir]

#----

require_relative 'src/filters'
require_relative 'src/menu'
require_relative 'src/session'
require_relative 'src/song_info'
require_relative 'src/songs'

DB = Sequel.sqlite database: "#{__dir__}/music.db"

unless DB.table_exists?('songs')
  DB.create_table 'songs' do
    primary_key :id
    String      :filepath
    Integer     :bpm # темп (количество четвертей в минуту)
    String      :mood,   fixed: true, size: 1 # грустная | обычная | весёлая
    String      :motion, fixed: true, size: 1 # вялая | обычная | энергичная
    String      :genre,  fixed: true, size: 1
    Date        :updated_at
  end
end

#----

Menu.main
