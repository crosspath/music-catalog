module Menu
  module Catalog
    TEXT = LocaleText.for_scope('menu.catalog')

    module Output
      def print_title(song, index, index_size = 1)
        puts "#{(index + 1).to_s.rjust(index_size, '0')}. #{song.name}"
      end

      def bpm(song)
        text = Config::TEMPO.find { |_, tempo| tempo.match?(song.bpm) }&.first
        text ||= TEXT.no_data
        "#{song.bpm} bpm (#{text})"
      end

      def print_songs_with_options(songs)
        index_size = songs.size.to_s.size

        table_headers = ConsoleOutput::Row.new(
          [
            ConsoleOutput::Cell.new('#'),
            ConsoleOutput::Cell.new(TEXT.name),
            ConsoleOutput::Cell.new('BPM')
          ] + Config::OPTIONS.map { |(_key, option)| ConsoleOutput::Cell.new(option.title) }
        )

        table_body = songs.map.with_index do |song, index|
          ConsoleOutput::Row.new(
            [
              ConsoleOutput::Cell.new((index + 1).to_s.rjust(index_size, '0')),
              ConsoleOutput::Cell.new(song.name),
              ConsoleOutput::Cell.new(song.new? ? '' : bpm(song))
            ] + Config::OPTIONS.map do |(key, _option)|
              ConsoleOutput::Cell.new(song.options.fetch(key, []).join(', '))
            end
          )
        end

        table = ConsoleOutput::Table.new([table_headers] + table_body)
        table.print(Session.columns)
      end

      def print_songs_without_options(songs)
        index_size = songs.size.to_s.size

        songs.each_with_index do |song, index|
          print_title(song, index, index_size)
        end
      end
    end

    module SelectByIndex
      def select_songs_by_indices(songs)
        print TEXT.song_indices

        Session.get_string.split(' ').each_with_object([]) do |index, acc|
          song = songs[index.to_i - 1]
          next unless song

          acc << song
        end
      end
    end

    module SelectAndUpdate
      include Output, SelectByIndex

      def select_and_fill_records(songs)
        selected = select_songs_by_indices(songs)

        puts

        if selected.empty?
          puts TEXT.songs_not_selected
        else
          puts TEXT.fill_song_options

          selected.each { |model| fill_record(model) }

          puts
          puts TEXT.action_finished
        end
      end

      def fill_record(model)
        puts
        puts "= #{model.name}"
        puts

        begin
          Songs::Player.add_songs([model.filename])
          Songs::FillOptions.call(model)
        rescue Session::Interrupt
          raise # re-raise exception
        rescue => e
          puts e.message, e.backtrace
        end
      end
    end

    module UpdateAll
      extend SelectAndUpdate

      def self.call
        puts
        puts TEXT.fill_song_options

        Songs::Repo.scan.each do |model|
          next if model.with_options?

          fill_record(model)
        end

        puts
        puts TEXT.action_finished
      end
    end

    module UpdateOne
      extend SelectAndUpdate

      def self.call
        songs = Songs::Repo.scan.reject(&:with_options?)

        if songs.empty?
          puts TEXT.no_new_songs
          return
        end

        print_songs_without_options(songs)

        puts
        puts TEXT.which_new_songs

        select_and_fill_records(songs)
      end
    end

    module SearchByName
      extend SelectAndUpdate

      def self.call
        songs = Songs::Repo.scan

        puts
        print TEXT.find_song_by_name

        input = Session.get_string
        return if input.empty?

        found = songs.select { |model| model.name.include?(input) }

        if found.empty?
          puts TEXT.songs_not_found
        else
          # print_songs_without_options(found)
          print_songs_with_options(found)

          puts
          puts TEXT.which_songs

          select_and_fill_records(found)
        end
      end
    end

    module SearchByOptions
      extend Output, SelectByIndex

      def self.call
        puts
        puts TEXT.check_files

        songs = Songs::Repo.all.reject(&:new?)

        tempo_items = Config::TEMPO.map { |text, t| [text, "#{text}, #{t.range}"] }.to_h
        tempo       = Config::Option.new(title: 'BPM', select: '0..1', items: tempo_items.values)

        all_options = [tempo] + Config::OPTIONS.values

        loop do
          puts
          puts TEXT.filter_options

          all_options.each do |option|
            puts "- #{option.title} -"
            Session.print_columns(items: option.items_with_keys_as_array)
            puts
          end

          print TEXT.which_options

          input   = Session.get_string.split(' ')
          filters = {}

          return if input.empty?

          puts

          unless input[0] == '-'
            filters[:tempo] = tempo.items_for_keys(input[0]).map { |text| tempo_items.key(text) }
          end

          Config::OPTIONS.each.with_index do |(k, option), index|
            index += 1
            next if input[index] == '-' || !input[index]

            filters[k] = option.items_for_keys(input[index])
          end

          selected_songs = songs.select { |model| model.match?([filters]) }
          if selected_songs.empty?
            puts TEXT.songs_not_found_by_filter
          else
            print_songs_with_options(selected_songs)
            push_songs(selected_songs)
          end
        end
      rescue Session::Interrupt
        nil
      end

      def self.push_songs(songs)
        puts
        puts TEXT.which_songs_add_to_player

        selected = select_songs_by_indices(songs).map(&:filename)

        if selected.empty?
          puts TEXT.songs_not_selected
        else
          Songs::Player.add_songs(selected)

          puts TEXT.songs_added(count: selected.size)
        end
      end
    end
  end
end
