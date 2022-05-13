module Songs
  module Player
    module_function

    def add_songs(*filepaths)
      # 2>/dev/null -- не показывать сообщения Clementine об ошибках.
      # pgroup: true -- отвязать экземпляр Clementine от процесса Ruby,
      # чтобы при остановке Ruby продолжил работать процесс Clementine.
      spawn("clementine --quiet -a #{filepaths.join(' ')} 2>/dev/null", pgroup: true)
    end
  end
end
