module Filters
  TEMPO_BPM = {
    ?1 => 0...90,
    ?2 => 90...130,
    ?3 => 130...160,
    ?4 => 160...999,
  }

  TEMPO = {
    ?1 => 'медленная',
    ?2 => 'средняя',
    ?3 => 'быстрая',
    ?4 => 'очень быстрая',
  }

  TEMPO_INV = TEMPO_BPM.map { |k, interval| [interval, TEMPO[k]] }

  MOOD = {
    ?q => 'грустная',
    ?w => 'обычная',
    ?e => 'весёлая',
  }

  MOTION = {
    ?a => 'вялая',
    ?s => 'обычная',
    ?d => 'энергичная',
  }

  GENRE = CONFIG[:genres].transform_keys(&:to_s)

  module_function

  def includes?(key, options)
    unless options.key?(key)
      puts "Не найдено значение \"#{key}\" в списке"
      return false
    end
    true
  end
end
