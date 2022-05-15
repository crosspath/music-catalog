module Songs
  class PlaylistGenerator
    def initialize(config, songs, save_to)
      @config  = config
      @save_to = save_to
      matchers = config.filters.map { |f| f.matcher(Config::OPTIONS) }
      @entries = songs.filter_map { |model| model.filename if model.match?(matchers) }
    end

    def result
      <<~TEXT
        #EXTM3U
        #{@entries.join("\n")}
      TEXT
    end

    def save
      return false if @entries.empty?

      playlist_file_name = ::File.join(@save_to, "#{@config.name}.m3u")
      ::File.write(playlist_file_name, result)

      true
    end
  end
end
