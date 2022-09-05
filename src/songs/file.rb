module Songs
  class File
    RE_BPM = /:\s(\d+(?:\.\d+))\sBPM$/

    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end

    def bpm
      @bpm ||= begin
        path   = ::File.join(Config::LOCAL_MUSIC_DIR, @filename)
        output = `bpm-tag -f -n #{path.inspect} 2>&1`
        match  = output.match(RE_BPM)

        raise RuntimeError.new(output) unless match
        match[1].to_f
      end
    end
  end
end
