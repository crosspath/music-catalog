module Menu
  module DB
    module Export
      def self.call
        puts
        print 'Название файла (dump.json) --> '

        dump = Session.get_string
        dump = 'dump.json' if dump.empty?

        if File.exist?(dump) ? File.writable?(dump) : File.writable?('.')
          records = Config::DB_SONGS.find.to_h do |record|
            [record[:filename], record.slice(:options, :created_at, :updated_at, :bpm)]
          end

          File.write(dump, JSON.generate(records))
        else
          puts "Нет прав на запись в файл #{dump}"
        end
      rescue Session::Interrupt
        nil
      end
    end

    module Import
      def self.call
        puts
        print 'Название файла (dump.json) --> '

        dump = Session.get_string
        dump = 'dump.json' if dump.empty?

        unless File.readable?(dump)
          puts "Нет прав на чтение файла #{dump}"
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
