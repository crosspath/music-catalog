module Songs
  module FillOptions
    class << self
      # @param song Songs::Model
      def call(song)
        options = Config::OPTIONS.each_with_object({}) do |(key, option), acc|
          selected = fill_option(key.to_s, option, song.options)
          return unless selected

          acc[key] = selected
        end

        song.sync(options, calc_bpm(song))
      end

      private

      def fill_option(key, option, options)
        option_items = option.items_with_keys_as_hash

        loop do
          puts "- #{option.title} -"
          options_to_output = option_items.each_with_object({items: [], underline: []}) do |(k, v), acc|
            acc[:items] << "#{k}. #{v}"
            acc[:underline] << acc[:items].size - 1 if options[key]&.include?(v)
          end
          Session.print_columns(**options_to_output)
          selected = option.items_for_keys(Session.get_string)

          unless option.valid_count?(selected.size)
            raise Session::InvalidInput, "Required: #{option.select_range} items"
          end

          return selected
        rescue Session::InvalidInput => e
          puts e.message
        end
      end

      def calc_bpm(song)
        algo_bpm = song.bpm
        res      = nil

        puts '- BPM -'
        puts "Автоматически определённое значение: #{song.bpm} (#{bpm_text(algo_bpm)})"

        loop do
          print 'Нажмите клавишу пробела, буквы или цифры в момент начала первой четверти такта... '
          STDIN.getch
          print 'Ещё раз... '

          start = Time.now

          STDIN.getch

          manual_bpm = 60 / (Time.now - start) * 4

          res = [0.5, 0.67, 1, 1.5, 2].min_by { |coeff| (manual_bpm - algo_bpm * coeff).abs } * algo_bpm

          puts
          puts "Значение BPM определено как #{res} (#{bpm_text(res)})"

          break unless repeat_calc_bpm?
        end

        res
      end

      def repeat_calc_bpm?
        loop do
          puts
          puts '1. Повторить'
          puts '2. Перейти к следующей песне'

          case Session.get_char
          when '1' then return true
          when '2' then return false
          else
            puts 'Неизвестное действие!'
          end
        end
      end

      def bpm_text(value)
        Config::TEMPO.find { |_, tempo| tempo.match?(value) }&.first || 'н/д'
      end
    end
  end
end
