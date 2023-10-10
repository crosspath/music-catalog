# frozen_string_literal: true

module Songs
  module FillOptions
    class RetryError < RuntimeError
    end

    TEXT = LocaleText.for_scope("songs.fill_options")

    class << self
      # @param song Songs::Model
      def call(song)
        print_options(song)

        loop do
          print "--> "

          input = Session.get_string.split(" ")

          next if input.empty?

          if input.size > Config::OPTIONS.size
            raise Session::InvalidInput, TEXT.too_many_values
          end

          values = selected_values(input)

          next if values.size != Config::OPTIONS.size

          begin
            song.sync(values, CalcBpm.call(song))
            break
          rescue Session::Interrupt
            # Вернуться к вводу опций.
            puts "^C", ""
            raise RetryError
          end
        rescue Session::InvalidInput => e
          puts e.message # Показываем ошибку и возвращаемся в начало `loop`.
        end
      rescue RetryError
        retry
      end

      private

      def print_options(song)
        Config::OPTIONS.each do |(key, option)|
          print_option(key.to_s, option, song.options)
        end
      end

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

      def selected_values(input)
        values = {}

        Config::OPTIONS.each.with_index do |(k, option), index|
          selected =
            if input[index] == "-" || input.size < index + 1
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

        values
      end
    end
  end
end
