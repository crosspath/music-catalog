module Songs
  class Model
    extend Forwardable

    def_delegators :@file, :filename
    def_delegators :@db_entry, :match?, :new?, :options

    def initialize(filename, record: nil)
      @file     = Songs::File.new(filename)
      @db_entry = Songs::DbEntry.new(record || Config::DB_SONGS.find(filename: filename).first)

      @db_entry.filename = filename
    end

    def bpm
      @db_entry.bpm ||= @file.bpm
    end

    def name
      @name ||= @file.filename[0..(-1 - ::File.extname(@file.filename).size)]
    end

    def filepath
      ::File.join(Config::LOCAL_MUSIC_DIR, @file.filename)
    end

    def with_options?
      !@db_entry.options.empty?
    end

    def synced?
      @db_entry.synced_at && @db_entry.synced_at >= ::File.mtime(filepath)
    end

    def sync(options)
      @db_entry.new? ? create_db_entry(options) : update_db_entry(options)
    end

    def ask
      options = Config::OPTIONS.each_with_object({}) do |(key, option), acc|
        selected = fill_option(key.to_s, option)
        return unless selected
        acc[key] = selected
      end

      sync(options)
    end

    def sync_with_device
      now = Time.now
      if @db_entry.new?
        @db_entry.create(bpm: bpm, synced_at: now, updated_at: now)
      else
        @db_entry.update(synced_at: now, updated_at: now)
      end
    end

    class << self
      attr_reader :cache
    end

    def self.scan
      models   = all
      @cache ||= {}

      cached_keys = @cache.keys
      new_songs   = models.select { |model| !cached_keys.include?(model.filename) && model.new? }

      show_progress = new_songs.size > 20
      counter       = 0

      print "Изучение файлов (#{new_songs.size})" if show_progress

      selected = models.filter_map do |model|
        if new_songs.include?(model)
          if show_progress
            counter += 1
            print '.' if counter % 20 == 0
          end
          model.bpm # raises RuntimeError if file is not an audio
          @cache[model.filename] = model
        elsif model.new?
          @cache[model.filename]
        else
          @cache[model.filename] = model
        end
      rescue
        nil
      end

      puts if show_progress

      selected
    end

    def self.all
      abs_dir = ::File.realpath(Config::LOCAL_MUSIC_DIR)
      skip    = abs_dir.size + 1

      filenames = Dir[::File.join(abs_dir, '**', '*')].filter_map do |filepath|
        ::File.directory?(filepath) ? nil : filepath[skip..]
      end

      filenames.reject! do |filename|
        filename += '/'
        Config::IGNORE_DIRECTORIES.any? { |dir| filename.start_with?(dir) }
      end

      records = Config::DB_SONGS.find.to_h { |record| [record[:filename], record] }

      filenames.map { |name| new(name, record: records[name]) }
    end

    private

    def create_db_entry(options)
      @db_entry.create(bpm: @file.bpm, options: options)
    end

    def update_db_entry(options)
      @db_entry.update(options: options)
    end

    def fill_option(key, option)
      loop do
        puts "- #{option.title} -"
        options_to_output = option.items_with_keys_as_hash.each_with_object({items: [], underline: []}) do |(k, v), acc|
          acc[:items] << "#{k}. #{v}"
          acc[:underline] << acc[:items].size - 1 if @db_entry.options[key]&.include?(v)
        end
        Session.print_columns(**options_to_output)
        selected = option.items_for_keys(Session.get_string)

        unless option.valid_count?(selected.size)
          raise Session::InvalidInput, "Required: #{option.select_range} items"
        end

        return selected
      rescue Session::InvalidInput => e
        puts e.message
      end
    end
  end
end
