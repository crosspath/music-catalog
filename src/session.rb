module Session
  class Interrupt < RuntimeError
  end

  class InvalidInput < RuntimeError
  end

  module_function

  def print_columns(items: [], underline: [])
    columns_sizes = calc_columns_sizes(items.map(&:size))

    if columns_sizes.empty?
      # Print one item per line.
      items = items.map.with_index do |item, index|
        underline.include?(index) ? negate_output(item) : item
      end
      puts items
    else
      # Print items in columns.
      items = items.map.with_index do |item, index|
        length = columns_sizes[index % columns_sizes.size]
        if underline.include?(index)
          negate_output(item).ljust(length + 8)
        else
          item.ljust(length)
        end
      end
      items.each_slice(columns_sizes.size) do |row|
        puts row.join(' | ')
      end
    end
  end

  def calc_columns_sizes(items_lengths)
    columns     = Session.columns
    max_lengths = []
    try_count   = items_lengths.size

    loop do
      # Given items_lengths = [8, 10, 13, 17] (sum + spaces: 57)
      # Given columns = 50
      # Trace variables' values by loop iteration:
      #   when try_count = 4, then try_lengths = [[8, 10, 13, 17]]
      #   when try_count = 3, then try_lengths = [[8, 10, 13], [17]]
      try_lengths = items_lengths.each_slice(try_count).to_a

      # Trace variables' values by loop iteration:
      #   when try_count = 4, then max_lengths = [8, 10, 13, 17]
      #   when try_count = 3, then max_lengths = [17, 10, 13]
      max_lengths = try_lengths.each_with_object(Array.new(try_count, 0)) do |e, a|
        e.each_with_index { |x, i| a[i] = [a[i], x].max }
      end

      return max_lengths if max_lengths.sum + (max_lengths.size * 3) - 3 <= columns

      try_count -= 1
      return [] if try_count == 0
    end
  end

  def columns
    @columns ||= IO.console.winsize[1]
  end

  def get_char
    c = STDIN.getch
    raise Interrupt if ["\u0003", "\u0004"].include?(c) # Ctrl+C, Ctrl+D
    c
  end

  def negate_output(str)
    "\e[7m#{str}\e[0m"
  end

  def get_string
    Signal.trap('INT') { raise Interrupt } # Ctrl+C
    result = gets # nil if Ctrl+D
    raise Interrupt unless result

    result.chomp
  end

  def ask(question)
    loop do
      puts "#{question} (y/n)"
      case Session.get_char
      when 'y' then return true
      when 'n' then return false
      end
    end
  end

  def mkdir(path)
    parts = path.split(File::SEPARATOR)

    first = parts.shift
    parts.each_with_object(first) do |e, a|
      a << "#{File::SEPARATOR}#{e}"
      Dir.mkdir(a) unless Dir.exists?(a)
    end
  end

  def command(tpl, files)
    windows = Config::PLAYER[:os] == 'windows'

    files = files.map { |x| x.gsub('/', '\\') } if windows
    files = files.map { |x| "#{Config::PLAYER[:path]}#{windows ? '\\' : '/'}#{x}".inspect }

    str = sprintf(tpl, files: files.join(' '))

    # pgroup: true -- отвязать экземпляр проигрывателя от процесса Ruby,
    # чтобы при остановке Ruby продолжил работать процесс проигрывателя.
    spawn(str, pgroup: true)
  end
end
