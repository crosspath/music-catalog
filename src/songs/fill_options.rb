module Songs
  module FillOptions
    TEXT = LocaleText.for_scope('songs.fill_options')

    class << self
      # @param song Songs::Model
      def call(song)
        Config::OPTIONS.each do |(key, option)|
          print_option(key.to_s, option, song.options)
        end

        loop do
          print '--> '

          input  = Session.get_string.split(' ')
          values = {}

          next if input.empty?

          if input.size > Config::OPTIONS.size
            raise Session::InvalidInput, TEXT.too_many_values
          end

          Config::OPTIONS.each.with_index do |(k, option), index|
            selected =
              if input[index] == '-' || input.size < index + 1
                []
              else
                option.items_for_keys(input[index])
              end

            if option.valid_count?(selected.size)
              values[k] = selected
            else
              text = TEXT.required_count(option: option.title, count: option.select_range)
              raise Session::InvalidInput, text
            end
          end

          next if values.size != Config::OPTIONS.size

          song.sync(values, calc_bpm(song))
          break
        rescue Session::InvalidInput => e
          puts e.message # Показываем ошибку и возвращаемся в начало `loop`.
        end
      end

      private

      def print_option(key, option, song_options)
        option_items = option.items_with_keys_as_hash

        puts "- #{option.title} -"

        options_to_output = option_items.each_with_object({items: [], underline: []}) do |(k, v), acc|
          acc[:items] << "#{k}. #{v}"
          acc[:underline] << acc[:items].size - 1 if song_options[key]&.include?(v)
        end

        Session.print_columns(**options_to_output)

        puts
      end

      def calc_bpm(song)
        algo_bpm = song.file_bpm
        res      = nil

        puts
        puts '- BPM -', TEXT.bpm('auto', bpm: algo_bpm, label: bpm_text(algo_bpm))

        loop do
          print TEXT.bpm('start')
          STDIN.getch
          print TEXT.bpm('repeat')

          start = Time.now

          STDIN.getch

          manual_bpm = 60 / (Time.now - start) * 4

          res = [0.5, 0.67, 1, 1.5, 2].min_by { |coeff| (manual_bpm - algo_bpm * coeff).abs } * algo_bpm

          puts
          puts TEXT.bpm('result', manual_bpm: manual_bpm.round(2), bpm: res.round(2), label: bpm_text(res))

          break unless repeat_calc_bpm?
        end

        res
      end

      def repeat_calc_bpm?
        loop do
          puts
          puts "1. #{TEXT.bpm('menu.repeat')}"
          puts "2. #{TEXT.bpm('menu.next')}"

          case Session.get_char
          when '1' then return true
          when '2' then return false
          else
            puts TEXT.bpm('menu.unknown_action')
          end
        end
      end

      def bpm_text(value)
        Config::TEMPO.find { |_, tempo| tempo.match?(value) }&.first || TEXT.bpm('no_data')
      end
    end
  end
end
