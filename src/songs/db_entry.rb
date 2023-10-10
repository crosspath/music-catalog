# frozen_string_literal: true

module Songs
  class DbEntry
    TEXT = LocaleText.for_scope("songs.db_entry")

    def self.new_by_filename(filename)
      hash = Config::DB_SONGS.find(filename: filename).first

      new(hash || {filename: filename})
    end

    def initialize(hash)
      @record             = hash || {}
      @record[:options] ||= {}
    end

    %i[filename bpm options created_at updated_at synced_at].each do |mth|
      define_method(mth) { @record[mth] }
      define_method("#{mth}=") { |v| @record[mth] = v }
    end

    def new?
      @record[:created_at].nil?
    end

    # @param matchers Array(Hash(Symbol, Array(String)))
    #        {tempo: []} -- any tempo (bpm)
    #        {tempo: ["fast"]} -- tempo is "fast"
    #        {tempo: ["slow", "fast"]} -- tempo is "slow" or "fast"
    #        {"-tempo": []} -- tempo is not set
    #        {"-tempo": ["fast"]} -- tempo is not "fast" or not set
    #        {"-tempo": ["slow", "fast"]} -- tempo is not "slow" nor "fast" or not set
    # @returns true | false
    # Works with Config::Playlist#options
    def match?(matchers)
      return true if matchers.empty?

      matchers.any? do |matcher| # => Hash(Symbol, Array(String))
        matcher.all? do |key, values|
          key      = key.to_s
          negative = key.start_with?("-")
          key      = key[1..-1] if negative
          if key == "tempo"
            negative ? not_match_tempo?(values) : match_tempo?(values)
          else
            negative ? not_match_option?(key, values) : match_option?(key, values)
          end
        end
      end
    end

    def match_tempo?(values)
      return false unless bpm

      values.empty? || values.any? { |key| Config::TEMPO[key].match?(bpm) }
    end

    def match_option?(key, values)
      option = @record[:options][key]
      option && ((values.empty? && !option.empty?) || !(option & values).empty?)
    end

    def not_match_tempo?(values)
      !bpm || values.none? { |key| Config::TEMPO[key].match?(bpm) }
    end

    def not_match_option?(key, values)
      option = @record[:options][key]
      !option || option.empty? || (!values.empty? && (option & values).empty?)
    end

    def create(new_values = {})
      now = Time.now

      @record[:created_at] = now
      @record[:updated_at] = now

      @record.merge!(new_values)

      unless Config::DB_SONGS.insert_one(@record).n == 1
        raise TEXT.cannot_create(filename: @record[:filename])
      end
    end

    def update(new_values = {})
      @record[:updated_at] = Time.now

      @record.merge!(new_values)

      finder = {filename: @record[:filename]}

      unless Config::DB_SONGS.update_one(finder, @record).n == 1
        raise TEXT.cannot_update(filename: @record[:filename])
      end
    end
  end
end
