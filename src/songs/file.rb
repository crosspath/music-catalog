module Songs
  class File
    RE_BPM = /:\s(\d+(?:\.\d+))\sBPM$/

    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end

    def bpm
      @bpm ||= begin
        output = `bpm-tag -f -n #{@filename.inspect} 2>&1`
        match  = output.match(RE_BPM)

        raise RuntimeError.new(output) unless match
        match[1]
      end
    end
  end
end
