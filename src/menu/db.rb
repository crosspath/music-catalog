module Menu
  module DB
    module Export
      def self.call
        default_path = File.join(File.realpath(Config::LOCAL_MUSIC_DIR), 'dump.json')

        puts
        print I18n.t('menu.db.export.filename', filename: default_path)

        dump = Session.get_string
        dump = default_path if dump.empty?

        if !File.exist?(dump) || File.writable?(dump)
          records = Config::DB_SONGS.find.to_h do |record|
            [record[:filename], record.slice(:options, :created_at, :updated_at, :bpm)]
          end

          File.write(dump, JSON.generate(records))
        else
          puts I18n.t('menu.db.export.cannot_write', filename: dump)
        end
      rescue Session::Interrupt
        nil
      end
    end

    module Import
      def self.call
        default_path = File.join(File.realpath(Config::LOCAL_MUSIC_DIR), 'dump.json')

        puts
        print I18n.t('menu.db.import.filename', filename: default_path)

        dump = Session.get_string
        dump = default_path if dump.empty?

        unless File.readable?(dump)
          puts I18n.t('menu.db.export.cannot_read', filename: dump)
          return
        end

        records = JSON.parse(File.read(dump))
        records.each do |filename, data|
          # => Возвращает значение записи до обновления или nil (если это новая запись).
          Config::DB_SONGS.find_one_and_update(
            {filename: filename},
            {'$set' => {filename: filename}.merge(data)},
            upsert: true
          )
        end
      end
    end
  end
end
