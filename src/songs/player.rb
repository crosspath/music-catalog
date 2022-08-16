module Songs
  module Player
    module_function

    def add_songs(*filepaths)
      windows = Config::PLAYER[:os] == 'windows'

      filepaths = filepaths.map { |x| x.gsub('/', '\\') } if windows
      filepaths = filepaths.map { |x| "#{Config::PLAYER[:path]}#{windows ? '\\' : '/'}#{x}".inspect }

      command = sprintf(Config::PLAYER[:command], files: filepaths.join(' '))

      # pgroup: true -- отвязать экземпляр проигрывателя от процесса Ruby,
      # чтобы при остановке Ruby продолжил работать процесс проигрывателя.
      spawn(command, pgroup: true)
    end
  end
end
