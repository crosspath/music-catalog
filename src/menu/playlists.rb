module Menu
  module Playlists
    def self.call
      save_to = Config::LOCAL_PLAYLISTS_DIR
      save_to = Config::LOCAL_MUSIC_DIR if save_to.empty?

      puts
      puts I18n.t('menu.playlists.check_files')
      puts

      songs = Songs::Repo.all.reject(&:new?)

      if File.exist?(save_to)
        if Dir.exist?(save_to)
          puts I18n.t('menu.playlists.copy_to_dir', path: save_to)

          unless File.writable?(save_to)
            puts I18n.t('menu.playlists.cannot_write', path: save_to)
            return
          end
        else
          puts I18n.t('menu.playlists.is_not_dir')
          return
        end
      else
        puts I18n.t('menu.playlists.copy_to_new_dir', path: save_to)
        Session.mkdir(save_to)
      end

      puts

      Config::PLAYLISTS.each do |config|
        if Songs::PlaylistGenerator.new(config, songs, save_to).save
          puts config.name
        else
          puts "#{config.name} | #{I18n.t('menu.playlists.skipped')}"
        end
      end
    end
  end
end
