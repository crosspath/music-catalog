class Config
  Tempo = Struct.new(:value) do
    def range
      @range ||= value.match(/\A(\d+)?(\.+)(\d+)?\Z/).then do |m|
        include_end = m[2].size == 2
        Range.new(m[1], m[3], !include_end)
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
        ki[char] || raise(Session::InvalidInput, "Unknown key: #{char}")
      end
    end
  end

  Playlist = Struct.new(:name, :options, keyword_init: true) do
    def filters
      @filters ||= options.map { |hash| PlaylistFilter.new(hash) }
    end
  end

  PlaylistFilter = Struct.new(:hash) do
    def matcher(options_hash)
      options_hash.each_with_object([]) do |(k, e), a|
        next unless hash.key?(k)

        a << hash[k].empty? ? ->(song) { empty_list?(song, k) } : ->(song) { any_of?(song, k) }
      end
    end

    def empty_list?(song, attr_name)
      song[attr_name].empty?
    end

    def any_of?(song, attr_name)
      (song[attr_name] & hash[attr_name]).size > 0
    end
  end

  CONFIG = JSON.parse(File.read("#{__dir__}/../config.json"), symbolize_names: true)
  MUSIC_DIR = CONFIG[:dir]
  IGNORE_DIRECTORIES = (CONFIG[:ignore] || []).map { |dir| dir.end_with?('/') ? dir : "#{dir}/" }

  MONGO = Mongo::Client.new(CONFIG[:mongo])
  DB_SONGS = MONGO[:songs]

  TEMPO = (CONFIG[:tempo] || {}).transform_values { |value| Tempo.new(value) }
  OPTIONS = (CONFIG[:options] || {}).transform_values { |hash| Option.new(hash) }
  PLAYLISTS = (CONFIG[:playlists] || []).map { |hash| Playlist.new(hash) }
end
