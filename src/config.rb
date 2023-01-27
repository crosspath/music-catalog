class Config
  Tempo = Struct.new(:value) do
    def range
      @range ||= value.match(/\A(\d+)?(\.+)(\d+)?\Z/).then do |m|
        include_end = m[2].size == 2
        Range.new(m[1]&.to_f, m[3]&.to_f, !include_end)
      end
    end

    def match?(bpm)
      range.cover?(bpm)
    end
  end

  Option = Struct.new(:title, :select, :items, keyword_init: true) do
    def select_range
      @select_range ||= begin
        values = select.split('..', 2)
        first  = values.first
        last   = values.last
        Range.new(first.empty? ? nil : first.to_i, last.empty? ? nil : last.to_i)
      end
    end

    # => Hash {char => String, ...}
    def items_with_keys_as_hash
      @items_with_keys_as_hash ||= begin
        key = 1
        base = 11 + 'z'.ord - 'a'.ord # => 36

        items.each_with_object({}) do |e, a|
          a[key.to_s(base)] = e
          key += 1
        end
      end
    end

    def items_with_keys_as_array
      @items_with_keys_as_array ||= items_with_keys_as_hash.map { |k, v| "#{k}. #{v}" }
    end

    def valid_count?(input)
      select_range.cover?(input)
    end

    def items_for_keys(input)
      ki = items_with_keys_as_hash
      input.each_char.map do |char|
        ki[char] || raise(Session::InvalidInput, I18n.t('config.option.unknown_char', char: char))
      end
    end
  end

  Playlist = Struct.new(:name, :options, keyword_init: true)

  CONFIG = JSON.parse(File.read("#{__dir__}/../config.json"), symbolize_names: true)
  LOCAL_MUSIC_DIR = CONFIG[:local][:music]
  LOCAL_PLAYLISTS_DIR = CONFIG[:local][:playlists]
  DEVICE_MUSIC_DIR = CONFIG[:portable][:music]
  DEVICE_PLAYLISTS_DIR = CONFIG[:portable][:playlists]
  IGNORE_DIRECTORIES = (CONFIG[:ignore] || []).map { |dir| dir.end_with?('/') ? dir : "#{dir}/" }

  MONGO = Mongo::Client.new(CONFIG[:mongo])
  DB_SONGS = MONGO[:songs]

  # 2>/dev/null -- не показывать сообщения Clementine об ошибках.
  PLAYER = (CONFIG[:player] || {}).tap do |hash|
    hash[:os] ||= 'linux'
    hash[:command] ||= 'clementine --quiet -a %{files} 2>/dev/null'
    hash[:path] ||= LOCAL_MUSIC_DIR
  end

  TEMPO = (CONFIG[:tempo] || {}).transform_values { |value| Tempo.new(value) }
  OPTIONS = (CONFIG[:options] || {}).transform_values { |hash| Option.new(hash) }
  PLAYLISTS = (CONFIG[:playlists] || []).map { |hash| Playlist.new(hash) }

  I18n.load_path += Dir[File.expand_path('locales') + '/*.yml']
  I18n.default_locale = CONFIG[:locale]
end
