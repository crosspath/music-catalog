# frozen_string_literal: true

module Menu
  module Device
    TEXT = LocaleText.for_scope("menu.device")

    module Sync
      def self.call
        puts
        puts TEXT.check_files
        puts

        songs_to_copy, files_to_remove = prepare_lists

        have_changes = !songs_to_copy.empty? || !files_to_remove.empty?

        if have_changes && Session.ask(TEXT.do_sync_songs)
          device_dir = File.realpath(Config::DEVICE_MUSIC_DIR)
          local_dir  = File.realpath(Config::LOCAL_MUSIC_DIR)

          puts "", TEXT.removing unless files_to_remove.empty?

          files_to_remove.each do |file_name|
            puts file_name
            File.delete(File.join(device_dir, file_name))
          end

          puts "", TEXT.copying unless songs_to_copy.empty?

          songs_to_copy.each do |song|
            file_name     = song.filename
            new_file_path = File.join(device_dir, file_name)
            puts file_name
            Session.mkdir(File.dirname(new_file_path))
            File.copy_stream(File.join(local_dir, file_name), new_file_path)
            song.sync_with_device
          end

          puts
        end

        if Session.ask(TEXT.do_sync_playlists)
          Menu::Playlists.call
          Session.mkdir(Config::DEVICE_PLAYLISTS_DIR)

          device_pl_dir   = File.realpath(Config::DEVICE_PLAYLISTS_DIR)
          local_pl_dir    = File.realpath(Config::LOCAL_PLAYLISTS_DIR)
          device_dir_skip = device_pl_dir.size + 1
          local_dir_skip  = local_pl_dir.size + 1

          on_device = Dir[File.join(device_pl_dir, "*")].reject { |x| File.directory?(x) }
          on_local  = Dir[File.join(local_pl_dir, "*")].reject { |x| File.directory?(x) }

          on_device.map! { |file_path| file_path[device_dir_skip..] }
          on_local.map! { |file_path| file_path[local_dir_skip..] }

          (on_device - on_local).each do |file|
            File.delete(File.join(device_pl_dir, file))
          end

          (on_local - on_device).each do |file|
            File.copy_stream(File.join(local_pl_dir, file), File.join(device_pl_dir, file))
          end

          (on_local & on_device).each do |file|
            device_file_path = File.join(device_pl_dir, file)
            local_file_path  = File.join(local_pl_dir, file)

            if File.mtime(local_file_path) != File.mtime(device_file_path)
              File.copy_stream(local_file_path, device_file_path)
            end
          end
        end

        puts
        puts TEXT.action_finished
      rescue Session::Interrupt
        nil
      end

      def self.prepare_lists
        device_abs_dir = File.realpath(Config::DEVICE_MUSIC_DIR)

        songs = Songs::Repo.scan
        songs_to_copy = songs.reject(&:synced?)

        on_device = Dir["**/*", base: device_abs_dir]

        on_device = on_device.filter_map do |x|
          testname = x.downcase
          next if Config::IGNORE_DIRECTORIES.any? { |dir| testname.start_with?(dir) }
          next if File.directory?(File.join(device_abs_dir, x))

          x
        end

        files_to_remove = on_device.filter_map do |x|
          songs.none? { |song| song.filename == x } && x
        end

        puts TEXT.songs_to_copy(count: songs_to_copy.size)

        print_list(songs_to_copy, &:filename)

        puts TEXT.songs_to_remove(count: files_to_remove.size)

        print_list(files_to_remove, &:itself)

        [songs_to_copy, files_to_remove]
      end

      def self.print_list(list)
        return if list.empty? || !Session.ask(TEXT.show_list)

        puts

        list.each { |song| puts yield(song) }

        puts
      end
    end

    module Command
      def self.songs_list
        Songs::Repo.scan.reject(&:synced?).map(&:filename)
      end

      module Picard
        def self.call
          songs = Menu::Device::Command.songs_list
          Session.command("picard %{files}", songs)
        end
      end

      module MP3Gain
        def self.call
          songs = Menu::Device::Command.songs_list
          Session.command("mp3gain -e -r -p -q %{files}", songs)
        end
      end

      module Player
        def self.call
          songs = Menu::Device::Command.songs_list
          Songs::Player.add_songs(songs)
        end
      end
    end
  end
end
