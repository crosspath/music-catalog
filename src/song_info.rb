module SongInfo
  module_function

  def get_bpm(filepath)
    output = `bpm-tag -f -n #{filepath.inspect} 2>&1`
    match  = output.match(/:\s(\d+(?:\.\d+))\sBPM$/)

    raise RuntimeError.new(output) unless match
    match[1]
  end

  def song_characteristics(hash)
    longest = hash.max_by { |x| x.last.size }.last.size + 3 # 3: "?. " ("?" is any symbol).
    items   = hash.map { |(k, v)| "#{k}. #{v}".ljust(longest) }

    Session.print_columns(items)
  end

  def ask(filepath, file, filters)
    bpm = SongInfo.get_bpm(filepath)

    values = filters.map do |h|
      c = nil
      loop do
        puts "- #{h[:text]} -"
        SongInfo.song_characteristics(h[:list])
        c = Session.get_char
        return unless c
        break if Filters.includes?(c, h[:list])
      end
      [h[:column], c]
    end.to_h

    {
      filepath:   file,
      bpm:        bpm,
      updated_at: Time.now,
      **values
    }
  end
end
