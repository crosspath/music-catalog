module Songs
  class Model
    extend Forwardable

    def_delegators :@file, :bpm, :filename
    def_delegators :@db_entry, :match?, :new?, :options

    def initialize(filename, record: nil)
      @file     = Songs::File.new(filename)
      @db_entry = Songs::DbEntry.new(record || Config::DB_SONGS.find(filename: filename).first)

      @db_entry.filename = filename
    end

    def filepath
      ::File.join(Config::MUSIC_DIR, @file.filename)
    end

    def sync(options)
      @db_entry.new? ? create_db_entry(options) : update_db_entry(options)
    end

    def ask
      options = Config::OPTIONS.transform_values do |option|
        selected = fill_option(option)
        return unless selected
        selected
      end

      sync(options)
    end

    def self.all
      abs_dir = ::File.realpath(Config::MUSIC_DIR)
      skip    = abs_dir.size + 1

      songs   = Dir[::File.join(abs_dir, '*')].map { |filepath| filepath[skip..] }
      records = Config::DB_SONGS.find.to_h { |record| [record['filename'], record] }

      songs.map do |filename|
        model = new(filename, record: records[filename])
        model.bpm # raises RuntimeError if file is not an audio
        model
      rescue
        nil
      end.compact
    end

    private

    def create_db_entry(options)
      @db_entry.create(bpm: @file.bpm, options: options)
    end

    def update_db_entry(options)
      @db_entry.update(options: options)
    end

    def fill_option(option)
      loop do
        puts "- #{option.title} -"
        Session.print_columns(option.items_with_keys_as_array)
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
