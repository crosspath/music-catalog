# frozen_string_literal: true

module Songs
  class File
    RE_BPM = /:\s(\d+(?:\.\d+))\sBPM$/

    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end

    def audio?
      path   = ::File.join(Config::LOCAL_MUSIC_DIR, @filename)
      output = `file #{path.inspect}`

      output.sub!(path, "")
      output.include?("MPEG ADTS, layer III") || output.include?("Audio file with ID3") # mp3
    end

    def bpm
      @bpm ||= begin
        path   = ::File.join(Config::LOCAL_MUSIC_DIR, @filename)
        output = `bpm-tag -f -n -m 50 -x 310 #{path.inspect} 2>&1`
        raise RuntimeError.new(output) if output.include?("\nsox FAIL")

        match  = output.match(RE_BPM)
        raise RuntimeError.new(output) unless match

        match[1].to_f
      end
    end
  end
end
