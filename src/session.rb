module Session
  class Interrupt < RuntimeError
  end

  class InvalidInput < RuntimeError
  end

  module_function

  def print_columns(items)
    max_length = items.max.size

    count = count_items_in_line(max_length)
    items = items.map { |item| item.ljust(max_length) } if max_length < Session.columns

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
end
