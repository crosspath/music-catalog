# frozen_string_literal: true

module ConsoleOutput
  class Cell
    attr_reader :text, :style, :size, :sizes, :min_width

    def initialize(text, style = nil)
      @text = text
      @text = @text.split(" ") if @text.respond_to?(:split) # String

      @style     = style
      @sizes     = @text.map(&:size)
      @size      = @sizes.empty? ? 0 : @sizes.sum { |x| x + 1 } - 1
      @min_width = @sizes.max || 0
    end

    def to_s
      @to_s ||= @style == :negative ? "\e[7m#{@text.join(" ")}\e[0m" : @text.join(" ")
    end
  end

  class Row
    attr_reader :cells

    def initialize(cells)
      @cells = cells
    end

    def create_span_rows(widths)
      new_cells = []
      @cells.each_with_index do |cell, index|
        row_index  = 0
        part_index = 0
        if cell.sizes.empty?
          new_cells << {row_index: row_index, col_index: index, value: [], style: cell.style}
        else
          loop do
            parts    = []
            sizes    = []
            finished = false
            loop do
              sizes_sum = sizes.sum { |x| x + 1 }
              break if sizes_sum + cell.sizes[part_index] > widths[index]

              parts << cell.text[part_index]
              sizes << cell.sizes[part_index]

              part_index += 1
              finished    = part_index == cell.sizes.size
              break if finished
            end
            return if parts.empty? && !cell.sizes.empty?

            new_cells << {row_index: row_index, col_index: index, value: parts, style: cell.style}
            row_index += 1
            break if finished
          end
        end
      end
      new_rows = []
      new_cells.each do |hash|
        padding = widths[hash[:col_index]]
        padding -= hash[:value].sum { |s| s.size + 1 } - 1 unless hash[:value].empty?
        if padding > 0
          hash[:value] << "" if hash[:value].empty?
          hash[:value][-1] += " " * padding
        end
        new_rows[hash[:row_index]] ||= []
        new_rows[hash[:row_index]][hash[:col_index]] = Cell.new(hash[:value], hash[:style])
      end
      new_rows.map do |items|
        items = widths.map.with_index { |w, index| items[index] || Cell.new([" " * w]) }
        Row.new(items)
      end
    end

    def size
      @cells.sum(&:size) + (@cells.size - 1) * 3
    end

    def to_s
      @cells.map(&:to_s).join(" | ")
    end
  end

  Table = Struct.new(:rows) do
    def column_widths(line_length)
      max_widths = rows.each_with_object([]) do |e, a|
        e.cells.each_with_index do |cell, index|
          if !a[index] || a[index] < cell.size
            a[index] = cell.size
          end
        end
      end

      return max_widths if max_widths.sum { |x| x + 3 } - 3 <= line_length

      min_widths = rows.each_with_object([]) do |e, a|
        e.cells.each_with_index do |cell, index|
          if !a[index] || a[index] < cell.min_width
            a[index] = cell.min_width
          end
        end
      end

      diff_width = max_widths.map.with_index { |ln, i| ln - min_widths[i] }
      diff_extra = (max_widths.size - 1) * 3 / line_length.to_f
      diff_coeff = max_widths.sum.to_f / (line_length - (max_widths.size - 1) * 3) * (1 + diff_extra)

      max_widths.map.with_index do |w, index|
        diff_width[index] == 0 ? w : (w / diff_coeff - diff_extra).ceil
      end
    end

    def print(line_length)
      widths     = column_widths(line_length)
      span_rows  = rows.map { |row| row.create_span_rows(widths) || [row] }
      span_count = span_rows.size

      span_rows.each_with_index do |array, index|
        array.each { |row| puts row }
        puts "*" if span_count > index + 1
      end
    end
  end
end
