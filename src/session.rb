module Session
  module_function

  def print_columns(items)
    width = 0

    items.each do |item|
      unless width == 0
        new_width = width + 3 + item.size
        if new_width <= Session.columns
          print ' | '
          width += 3
        else
          width = 0
          puts
        end
      end
      print item
      width += item.size
    end

    puts unless items.empty?
  end

  def columns
    @_columns ||= Readline.get_screen_size[1] # [lines, columns] => columns
  end

  def get_char
    c = STDIN.getch
    return if ["\u0003", "\u0004"].include?(c) # Ctrl+C, Ctrl+D
    c
  end

  def get_string
    Signal.trap('INT') { return } # Ctrl+C
    answer = gets
    answer # answer == nil if Ctrl+D
  end
end
