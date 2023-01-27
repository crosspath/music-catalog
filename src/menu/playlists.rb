module Menu
  module Playlists
    TEXT = LocaleText.for_scope('menu.playlists')

    def self.call
      save_to = Config::LOCAL_PLAYLISTS_DIR
      save_to = Config::LOCAL_MUSIC_DIR if save_to.empty?

      puts
      puts TEXT.check_files
      puts

      songs = Songs::Repo.all.reject(&:new?)

      if File.exist?(save_to)
        if Dir.exist?(save_to)
          puts TEXT.copy_to_dir(path: save_to)

          unless File.writable?(save_to)
            puts TEXT.cannot_write(path: save_to)
            return
          end
        else
          puts TEXT.is_not_dir
          return
        end
      else
        puts TEXT.copy_to_new_dir(path: save_to)
        Session.mkdir(save_to)
      end

      puts

      Config::PLAYLISTS.each do |config|
        if Songs::PlaylistGenerator.new(config, songs, save_to).save
          puts config.name
        else
          puts "#{config.name} | #{TEXT.skipped}"
        end
      end
    end
  end
end
