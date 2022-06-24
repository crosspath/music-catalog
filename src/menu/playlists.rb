module Menu
  module Playlists
    def self.call
      save_to = Config::LOCAL_PLAYLISTS_DIR
      save_to = Config::LOCAL_MUSIC_DIR if save_to.empty?

      songs = Songs::Model.all.reject(&:new?)

      puts

      if File.exist?(save_to)
        if Dir.exist?(save_to)
          puts "Запись в папку #{save_to}:"
        else
          puts "По указанному пути найден файл, а не папка"
          return
        end
      else
        puts "Запись в новую папку #{save_to}:"
      end

      unless File.writable?(save_to)
        puts "Нет прав на запись в папку #{save_to}"
        return
      end

      puts

      Config::PLAYLISTS.each do |config|
        if Songs::PlaylistGenerator.new(config, songs, save_to).save
          puts config.name
        else
          puts "#{config.name} | пропущен, песни по фильтрам не найдены"
        end
      end
    end
  end
end
