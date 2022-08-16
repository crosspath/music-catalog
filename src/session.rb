module Session
  class Interrupt < RuntimeError
  end

  class InvalidInput < RuntimeError
  end

  module_function

  def print_columns(items)
    max_length = items.max_by(&:size).size

    count = count_items_in_line(max_length)
    if max_length < Session.columns && items.size > count
      items = items.map { |item| item.ljust(max_length) }
    end

    items.each_slice(count) do |row|
      puts row.join(' | ')
    end
  end

  def count_items_in_line(max_length)
    columns = Session.columns
    count   = 0

    loop do
      if max_length * (count + 1) + 3 * count <= columns
        count += 1
      else
        break
      end
    end

    count
  end

  def columns
    @columns ||= IO.console.winsize[1]
  end

  def get_char
    c = STDIN.getch
    raise Interrupt if ["\u0003", "\u0004"].include?(c) # Ctrl+C, Ctrl+D
    c
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
end
