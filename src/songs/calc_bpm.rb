module Songs
  module CalcBpm
    MULTIPLIERS = [0.5, 0.67, 1, 1.5, 2, 3, 4]

    TEXT = LocaleText.for_scope('songs.fill_options.bpm')

    class << self
      # @param song Songs::Model
      def call(song)
        algo_bpm = song.file_bpm
        res      = nil

        puts
        puts '- BPM -', TEXT.auto(bpm: algo_bpm, label: bpm_text(algo_bpm))

        loop do
          print TEXT.start
          Session.get_char
          print TEXT.repeat

          start = Time.now

          Session.get_char

          manual_bpm = 60 / (Time.now - start) * 4

          res = MULTIPLIERS.min_by { |coeff| (manual_bpm - algo_bpm * coeff).abs } * algo_bpm

          puts
          puts TEXT.result(manual_bpm: manual_bpm.round(2), bpm: res.round(2), label: bpm_text(res))

          break unless repeat_calc_bpm?
        end

        res
      end

      private

      def repeat_calc_bpm?
        loop do
          puts
          puts "1. #{TEXT.menu('repeat')}"
          puts "2. #{TEXT.menu('next')}"

          case Session.get_char
          when '1' then return true
          when '2' then return false
          else
            puts TEXT.menu('unknown_action')
          end
        end
      end

      def bpm_text(value)
        Config::TEMPO.find { |_, tempo| tempo.match?(value) }&.first || TEXT.no_data
      end
    end
  end
end
