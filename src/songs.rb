module Songs
  module_function

  def new
    abs_dir = File.realpath(MUSIC_DIR)
    skip    = abs_dir.size + 1

    Dir[File.join(abs_dir, '*')].map { |filepath| [filepath, filepath[skip..]] }
  end

  def filter(filters)
    skipped_filters = Menu::FILTERS.reject { |item| filters.key?(item[:column]) }

    songs  = DB[:songs].where(filters).order(:filepath).all
    count  = songs.size
    digits = songs.size.to_s.size
    found  = false
    result = {}

    songs.each_with_index do |song, index|
      next unless File.exist?(File.join(MUSIC_DIR, song[:filepath]))
      found = true
      puts "#{index.to_s.rjust(digits)}. #{song[:filepath]}"
      items = skipped_filters.map do |item|
        column_value = song[item[:column]]
        if item[:column] == :bpm
          inv = Filters::TEMPO_INV.find { |(interval, text)| interval.cover?(column_value) }
          column_value = inv[1] if inv
        end
        "#{item[:text]}: #{item[:list].fetch(column_value, column_value)}"
      end
      Session.print_columns(items)
      puts unless index + 1 == count
      result[index.to_s] = song
    end

    puts 'Не найдена' unless found

    result
  end
end
