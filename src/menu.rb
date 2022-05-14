module Menu
  ITEMS = [
    {
      key: '1',
      title: 'Управление каталогом музыки',
      action: :catalog,
      nested: [
        {key: '1', title: 'Заполнить все новые записи', action: :catalog_sync},
        {key: '2', title: 'Выбрать новую запись из списка', action: :catalog_select},
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

      input = Session.get_char
      found = false

      options.each do |opt|
        if opt[:key] == input
          found = true
          return if opt[:action] == :back

          public_send(opt[:action], opt[:nested])
        end
      end

      puts 'Неизвестное действие!' unless found
    end
  rescue Session::Interrupt
    return
  end

  def main
    menu(Menu::ITEMS)
  end

  def catalog(nested_menu)
    menu(nested_menu)
  end

  def catalog_sync(*)
    Songs::Model.scan.each do |model|
      next unless model.new?

      fill_record(model)
    end

    puts 'Задача завершена'
  end

  def catalog_select(*)
    puts

    songs = Songs::Model.scan.select(&:new?)

    if songs.empty?
      puts 'Нет новых записей'
      return
    end

    print_songs_without_options(songs)

    puts
    puts 'Какие новые записи необходимо заполнить?'

    select_and_fill_records(songs)
  end

  def catalog_search(*)
    songs = Songs::Model.scan

    puts
    puts 'Поиск песни по части имени файла:'
    print '--> '

    input = Session.get_string
    return if input.empty?

    found = songs.select { |model| model.filename.include?(input) }
    
    if found.empty?
      puts 'Не найдены песни'
    else
      print_songs_without_options(found)

      puts
      puts 'Какие записи необходимо заполнить или изменить?'

      select_and_fill_records(found)
    end
  end

  def selection(*)
    songs = Songs::Model.all.reject(&:new?)

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

      selected_songs = songs.select { |model| model.match?([filters]) }
      if selected_songs.empty?
        puts 'Не найдены песни по указанным фильтрам'
      else
        print_songs_with_options(selected_songs, selected_option_values)
        push_songs(selected_songs)
      end
    end
  rescue Session::Interrupt
    nil
  end

  def print_songs_with_options(songs, selected_option_values)
    max_length = Config::OPTIONS.map { |_, option| option.title }.max.size + 1
    index_size = songs.size.to_s.size

    songs.each_with_index do |song, index|
      puts "#{(index + 1).to_s.rjust(index_size, '0')}. #{song.filename}"

      Config::OPTIONS.each do |key, option|
        rest = song.options.fetch(key, []) - selected_option_values.fetch(key, [])
        next if rest.empty?

        puts "#{option.title}:#{' '.ljust(max_length - option.title.size)}#{rest.join(', ')}"
      end

      puts
    end
  end

  def print_songs_without_options(songs)
    index_size = songs.size.to_s.size

    songs.each_with_index do |song, index|
      puts "#{(index + 1).to_s.rjust(index_size, '0')}. #{song.filename}"
    end
  end

  def push_songs(songs)
    puts
    puts 'Добавить песни в проигрыватель?'
    puts 'Номера песен, перечисленные через пробел:'

    selected = select_songs_by_indices(songs).map { |song| song.filepath.inspect }

    if selected.empty?
      puts 'Не выбраны песни'
    else
      Songs::Player.add_songs(*selected)

      puts "Добавлены песни: #{selected.size}"
    end
  end

  def select_songs_by_indices(songs)
    print '--> '

    Session.get_string.split(' ').each_with_object([]) do |index, acc|
      song = songs[index.to_i - 1]
      next unless song

      acc << song
    end
  end

  def select_and_fill_records(songs)
    puts 'Номера песен, перечисленные через пробел:'

    selected = select_songs_by_indices(songs)

    if selected.empty?
      puts 'Не выбраны песни'
    else
      selected.each do |model|
        fill_record(model)
      end

      puts 'Задача завершена'
    end
  end

  def fill_record(model)
    puts
    puts "= #{model.filename}"

    begin
      Songs::Player.add_songs(model.filepath.inspect)
      model.ask
    rescue Session::Interrupt
      raise # re-raise exception
    rescue => e
      puts e.message, e.backtrace
    end
  end
end
