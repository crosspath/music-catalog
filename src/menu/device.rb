module Menu
  module Device
    module Sync
      def self.call
        device_abs_dir = ::File.realpath(Config::DEVICE_MUSIC_DIR)
        skip           = abs_dir.size + 1

        songs = Songs::Model.scan
        songs_to_copy = songs.reject(&:copied?)

        on_device = Dir[File.join(device_abs_dir, '**/*')].reject { |x| File.directory?(x) }
        files_to_remove = on_device.filter_map do |x|
          x = x[skip..]
          songs.any? { |song| song.filename == x } ? nil : x
        end

        puts 'Будут перезаписаны файлы с плэйлистами.'
        puts "Сколько песен выбрано для копирования: #{songs_to_copy.size}"

        show_new_and_changed = false

        unless songs_to_copy.empty?
          loop do
            puts 'Показать список? (y/n)'
            input = Session.get_char
            show_new_and_changed = true if input == 'y'
            break if input == 'y' || input == 'n'
          end
          
          puts

          if show_new_and_changed
            songs_to_copy.each do |song|
              puts song.filename
            end
          end
        end

        puts "Сколько песен выбрано для удаления: #{files_to_remove.size}"

        show_removable = false

        unless files_to_remove.empty?
          loop do
            puts 'Показать список? (y/n)'
            input = Session.get_char
            show_removable = true if input == 'y'
            break if input == 'y' || input == 'n'
          end
          
          puts

          if show_removable
            files_to_remove.each do |song|
              puts song.filename
            end
          end
        end

        if !songs_to_copy.empty? || !files_to_remove.empty?
          loop do
            puts 'Выполнить синхронизацию? (y/n)'
            input = Session.get_char
            return if input == 'n'
            break if input == 'y'
          end
        end
      rescue Session::Interrupt
        nil
      end
    end

    module Command
      def self.call
        DEVICE_DIR
      end
    end
  end
end
