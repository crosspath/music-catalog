# frozen_string_literal: true

module Songs
  module Repo
    TEXT = LocaleText.for_scope("songs.repo")

    class << self
      attr_reader :cache

      def files
        abs_dir = ::File.realpath(Config::LOCAL_MUSIC_DIR)

        # Ignore some directories before performing full scan.
        root_entries = Dir["*", base: abs_dir].filter_map do |fp|
          Config::IGNORE_DIRECTORIES.include?(fp.downcase) ? nil : fp
        end

        search_pattern = "{#{root_entries.join(",")}}/**/*"

        (root_entries + Dir[search_pattern, base: abs_dir]).filter_map do |filepath|
          testname = "#{filepath}/".downcase
          next if Config::IGNORE_DIRECTORIES.any? { |dir| testname.start_with?(dir) }
          next if ::File.directory?(::File.join(abs_dir, filepath))

          Songs::File.new(filepath)
        end
      end

      def all
        records = Config::DB_SONGS.find.to_h { |record| [record[:filename], record] }

        files.map { |file| Songs::Model.new(file, records[file.filename]) }
      end

      def scan
        models        = all
        new_songs     = select_new_songs(models)
        show_progress = new_songs.size > 50
        filenames     = []

        print TEXT.scanning(count: new_songs.size) if show_progress

        add_models_to_cache(models, new_songs, show_progress, filenames)
        delete_obsolete_keys_from_cache(filenames)

        puts if show_progress

        @cache.values
      end

      private

      def select_new_songs(models)
        @cache    ||= {}
        cached_keys = @cache.keys

        models.select { |model| !cached_keys.include?(model.filename) && model.new? }
      end

      def add_models_to_cache(models, new_songs, show_progress, filenames)
        counter = 0

        models.each do |model|
          filenames << model.filename
          if new_songs.include?(model)
            if show_progress
              counter += 1
              print "." if counter % 50 == 0
            end
            @cache[model.filename] = model if model.audio?
          elsif model.new?
            @cache[model.filename] if model.audio?
          else
            @cache[model.filename] = model
          end
        end
      end

      def delete_obsolete_keys_from_cache(filenames)
        @cache.each_key do |key|
          @cache.delete(key) unless filenames.include?(key)
        end
      end
    end
  end
end
