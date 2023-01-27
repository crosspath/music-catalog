module Menu
  ITEMS = JSON.parse(File.read('./menu.json'))

  module_function

  def main
    menu(ITEMS)
  end

  def menu(options = [])
    loop do
      puts

      options.each do |key, opt|
        puts "#{key}. #{opt['title']}"
      end

      input = Session.get_char
      found = options[input]

      if found
        case found['action']
        when nil then menu(found['items'])
        when 'back' then return
        else
          menu_module = found['action'].split('.').reduce(Menu) { |a, e| a.const_get(e) }
          menu_module.call
        end
      else
        puts I18n.t('menu.unknown_action')
      end
    end
  rescue Session::Interrupt
    return
  end
end
