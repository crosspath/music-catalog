# frozen_string_literal: true

module Songs
  module Player
    module_function

    def add_songs(filepaths)
      Session.command(Config::PLAYER[:command], filepaths)
    end
  end
end
