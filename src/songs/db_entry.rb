module Songs
  class DbEntry
    def initialize(hash)
      @record = hash || {}
      @record[:options] ||= {}
    end

    %i[filename bpm options created_at updated_at copied_at].each do |mth|
      define_method(mth) { @record[mth] }
      define_method("#{mth}=") { |v| @record[mth] = v }
    end

    def copied?
      updated_at && updated_at == copied_at
    end

    def new?
      @record[:created_at].nil?
    end

    def match?(matchers) # see Config::PlaylistFilter
      options = @record[:options]
      return true if options.empty? || matchers.empty?

      matchers.any? do |matcher|
        matcher.all? { |fn| fn.call(options) }
      end
    end

    def create(new_values = {})
      now = Time.now

      @record[:created_at] = now
      @record[:updated_at] = now

      @record.merge!(new_values)

      unless Config::DB_SONGS.insert_one(@record).n == 1
        raise "Failed to create entry for #{@record[:filename]}"
      end
    end

    def update(new_values = {})
      @record[:updated_at] = Time.now

      @record.merge!(new_values)

      finder = {filename: @record[:filename]}

      unless Config::DB_SONGS.update_one(finder, @record).n == 1
        raise "Failed to update entry for #{@record[:filename]}"
      end
    end
  end
end
