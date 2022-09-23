module Songs
  module Repo
    class << self
      attr_reader :cache

      def files
        abs_dir = ::File.realpath(Config::LOCAL_MUSIC_DIR)
        skip    = abs_dir.size + 1

        Dir[::File.join(abs_dir, '**', '*')].filter_map do |filepath|
          next if ::File.directory?(filepath)

          filename = filepath[skip..]
          testname = "#{filename}/"

          next if Config::IGNORE_DIRECTORIES.any? { |dir| testname.start_with?(dir) }

          Songs::File.new(filename)
        end
      end

      def all
        records = Config::DB_SONGS.find.to_h { |record| [record[:filename], record] }

        files.map { |file| Songs::Model.new(file, records[file.filename]) }
      end

      def scan
        models   = all
        @cache ||= {}

        cached_keys = @cache.keys
        new_songs   = models.select { |model| !cached_keys.include?(model.filename) && model.new? }

        show_progress = new_songs.size > 50
        counter       = 0
        filenames     = []

        print "Изучение файлов (#{new_songs.size})" if show_progress

        models.each do |model|
          filenames << model.filename
          if new_songs.include?(model)
            if show_progress
              counter += 1
              print '.' if counter % 50 == 0
            end
            @cache[model.filename] = model if model.audio?
          elsif model.new?
            @cache[model.filename] if model.audio?
          else
            @cache[model.filename] = model
          end
        end

        @cache.each_key do |key|
          @cache.delete(key) unless filenames.include?(key)
        end

        puts if show_progress

        @cache.values
      end
    end
  end
end
