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
            text = I18n.t('songs.fill_options.required_count', count: option.select_range)
            raise Session::InvalidInput, text
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
        puts I18n.t('songs.fill_options.bpm.auto', bpm: song.bpm, label: bpm_text(algo_bpm))

        loop do
          print I18n.t('songs.fill_options.bpm.start')
          STDIN.getch
          print I18n.t('songs.fill_options.bpm.repeat')

          start = Time.now

          STDIN.getch

          manual_bpm = 60 / (Time.now - start) * 4

          res = [0.5, 0.67, 1, 1.5, 2].min_by { |coeff| (manual_bpm - algo_bpm * coeff).abs } * algo_bpm

          puts
          puts I18n.t('songs.fill_options.bpm.result', bpm: res, label: bpm_text(res))

          break unless repeat_calc_bpm?
        end

        res
      end

      def repeat_calc_bpm?
        loop do
          puts
          puts "1. #{I18n.t('songs.fill_options.bpm.menu.repeat')}"
          puts "2. #{I18n.t('songs.fill_options.bpm.menu.next')}"

          case Session.get_char
          when '1' then return true
          when '2' then return false
          else
            puts I18n.t('songs.fill_options.bpm.menu.unknown_action')
          end
        end
      end

      def bpm_text(value)
        text = Config::TEMPO.find { |_, tempo| tempo.match?(value) }&.first
        text || I18n.t('songs.fill_options.bpm.no_data')
      end
    end
  end
end
