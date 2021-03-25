module Menu
  FILTERS = [
    {list: Filters::TEMPO,  column: :bpm,    text: 'скорость'},
    {list: Filters::MOOD,   column: :mood,   text: 'настроение'},
    {list: Filters::MOTION, column: :motion, text: 'движение'},
    {list: Filters::GENRE,  column: :genre,  text: 'жанр'},
  ]

  MAIN = [
    {key: '1', title: 'Управление каталогом музыки', fn: ->{action_manage}},
    {key: '2', title: 'Подбор музыки по каталогу', fn: ->{action_selection}},
    {key: '!', title: 'Выход', back: true},
  ]

  MANAGE = [
    {key: '1', title: 'Заполнить все новые записи', fn: ->{action_manage_sync}},
    {key: '2', title: 'Выбрать из списка', fn: ->{action_manage_list}},
    {key: '3', title: 'Поиск по названию', fn: ->{action_manage_search}},
    {key: '%', title: 'Назад', back: true},
  ]

  module_function

  # [{key: Char, title: String, back: true | nil, fn: Proc | nil}, ...]
  def menu(options = [])
    loop do
      puts

      options.each do |opt|
        puts "#{opt[:key]}. #{opt[:title]}"
      end

      c = Session.get_char
      return unless c

      found  = false

      options.each do |opt|
        if opt[:key] == c
          found = true
          return if opt[:back]
          opt[:fn].call
        end
      end

      puts 'Неизвестное действие!' unless found
    end
  end

  def main
    menu(Menu::MAIN)
  end

  def action_manage
    menu(Menu::MANAGE)
  end

  def action_manage_sync
    filters = Menu::FILTERS.reject { |item| item[:column] == :bpm }

    Songs.new.each do |(filepath, file)|
      next if DB[:songs].where(filepath: file).first

      puts file

      begin
        row = SongInfo.ask(filepath, file, filters)
        return unless row
        DB[:songs].insert(row)
      rescue => e
        puts e.message, e.backtrace
      end
    end
    
    puts 'Задача завершена'
  end

  def action_selection
    loop do
      puts
      puts 'Условия поиска:'

      Menu::FILTERS.each do |h|
        puts "- #{h[:text]} -"
        SongInfo.song_characteristics(h[:list])
        puts
      end

      puts '>> Пример ввода: 2wsz'
      puts '>> Знак "-" можно использовать для пропуска условия'
      print '--> '

      answer = Session.get_string
      return unless answer

      filters = string_to_filters(answer.chomp)
      if filters
        return if filters.empty?
        songs = Songs.filter(filters)
        action_push_songs(songs) unless songs.empty?
      end
    end
  end

  def action_push_songs(songs)
    puts
    puts 'Добавить песни в проигрыватель?'
    puts 'Номера песен, перечисленные через пробел:'
    print '--> '

    answer = Session.get_string
    return unless answer

    indices  = answer.split(' ')
    selected = []

    indices.each do |index|
      song = songs[index]
      next unless song
      selected << '"' + MUSIC_DIR + '/' + song[:filepath].gsub('"', '\"') + '"'
    end

    if selected.empty?
      puts 'Не выбраны песни'
    else
      # 2>/dev/null -- не показывать сообщения Clementine об ошибках.
      # pgroup: true -- отвязать экземпляр Clementine от процесса Ruby,
      # чтобы при остановке Ruby продолжил работать процесс Clementine.
      spawn("clementine --quiet -a #{selected.join(' ')} 2>/dev/null", pgroup: true)

      puts "Добавлены песни: #{selected.size}"
    end
  end

  def string_to_filters(string)
    res = string.each_char.map.with_index do |c, i|
      item = Menu::FILTERS[i]
      if c == '-'
        nil
      else
        return unless Filters.includes?(c, item[:list])
        [item[:column], c]
      end
    end.compact.to_h

    res[:bpm] = Filters::TEMPO_BPM[res[:bpm]] if res[:bpm]
    res
  end
end
