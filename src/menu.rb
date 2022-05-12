module Menu
  ITEMS = [
    {
      key: '1',
      title: 'Управление каталогом музыки',
      action: :catalog,
      nested: [
        {key: '1', title: 'Заполнить все новые записи', action: :catalog_sync},
        {key: '2', title: 'Выбрать из списка', action: :catalog_select},
        {key: '3', title: 'Поиск по названию', action: :catalog_search},
        {key: '%', title: 'Назад', action: :back},
      ]
    },
    {key: '2', title: 'Подбор музыки по каталогу', action: :selection},
    {key: '3', title: 'Создать плэйлисты', action: :playlists},
    {key: '!', title: 'Выход', action: :back},
  ]

  module_function

  def menu(options = [])
    loop do
      puts

      options.each do |opt|
        puts "#{opt[:key]}. #{opt[:title]}"
      end

      c = Session.get_char
      return unless c

      found = false

      options.each do |opt|
        if opt[:key] == c
          found = true
          return if opt[:action] == :back
          public_send(opt[:action], opt[:nested])
        end
      end

      puts 'Неизвестное действие!' unless found
    end
  end

  def main
    menu(Menu::ITEMS)
  rescue Session::Interrupt
    return
  end

  def catalog(nested_menu)
    menu(nested_menu)
  rescue Session::Interrupt
    return
  end

  def catalog_sync(*)
    Songs::Model.all.each do |model|
      next unless model.new?

      puts "= #{model.filename}"

      begin
        model.ask
      rescue Session::Interrupt
        return
      rescue => e
        puts e.message, e.backtrace
      end
    end

    puts 'Задача завершена'
  end

  def selection(*)
    loop do
      puts
      puts 'Условия поиска:'

      Config::OPTIONS.each do |_, option|
        puts "- #{option.title} -"
        Session.print_columns(option.items_with_keys_as_array)
        puts
      end

      puts '>> Пример ввода: 1 2 1'
      puts '>> Знак "-" можно использовать для пропуска условия'
      print '--> '

      values  = Session.get_string.split(' ')
      filters = []

      selected_option_values = {}

      return if values.empty?

      Config::OPTIONS.each.with_index do |(k, option), index|
        next if values[index] == '-'

        selected = option.items_for_keys(values[index])
        filters << ->(song) { (song[k] & selected).size > 0 }

        selected_option_values[k] = selected
      end

      selected_songs = Songs::Model.all.select { |model| model.match?([filters]) }
      if selected_songs.empty?
        puts 'Не найдены песни по указанным фильтрам'
      else
        max_length = Config::OPTIONS.map { |_, option| option.title }.max.size + 1
        index_size = selected_songs.size.to_s.size
        selected_songs.each_with_index do |song, index|
          puts "#{(index + 1).to_s.rjust(index_size, '0')}. #{song.filename}"
          Config::OPTIONS.each do |key, option|
            rest = song.options.fetch(key, []) - selected_option_values.fetch(key, [])
            next if rest.empty?

            puts "#{option.title}:#{' '.ljust(max_length - option.title.size)}#{rest.join(', ')}"
          end
          puts
        end
        push_songs(selected_songs)
      end
    rescue Session::Interrupt
      return
    end
  end

  def push_songs(songs)
    puts
    puts 'Добавить песни в проигрыватель?'
    puts 'Номера песен, перечисленные через пробел:'
    print '--> '

    answer = Session.get_string
    return unless answer

    indices  = answer.split(' ')
    selected = []

    indices.each do |index|
      song = songs[index.to_i + 1]
      next unless song

      selected << song.filepath.inspect
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
end
