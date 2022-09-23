module Songs
  class Model
    extend Forwardable

    def_delegators :@file, :audio?, :filename
    def_delegators :record, :match?, :options

    # @param file Songs::File
    # @params record BSON::Document
    #   { '_id' => BSON::ObjectId, 'options' => {...}, 'filename' => String,
    #   'created_at' => Time, 'updated_at' => Time, 'bpm' => Float, 'synced_at' => Time }
    def initialize(file, record)
      @file   = file
      @record = record && Songs::DbEntry.new(record)
    end

    def record
      @record ||= Songs::DbEntry.new_by_filename(@file.filename)
    end

    def new?
      @record.nil? || @record.new?
    end

    def bpm
      record.bpm || @file.bpm
    end

    def name
      @name ||= @file.filename[0..(-1 - ::File.extname(@file.filename).size)]
    end

    def filepath
      ::File.join(Config::LOCAL_MUSIC_DIR, @file.filename)
    end

    def with_options?
      !record.options.empty?
    end

    def synced?
      record.synced_at && record.synced_at >= ::File.mtime(filepath)
    end

    def sync(options, bpm)
      new? ? record.create(bpm: bpm, options: options) : record.update(bpm: bpm, options: options)
    end

    def sync_with_device
      now = Time.now
      if new?
        record.create(bpm: bpm, synced_at: now, updated_at: now)
      else
        record.update(synced_at: now, updated_at: now)
      end
    end
  end
end
