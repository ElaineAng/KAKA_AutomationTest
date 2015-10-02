module Otms
  # private methods for Otms::Base
  module BasePrivate
    private

    def input_search(text, text_object, timeout)
      text_object.set(text)
      text_object.send_keys(:enter)
      sleep timeout
      wait_until(text_object.enabled?, timeout: 0)
    end

    def try_until(popup_text, parent)
      return if popup_text.exists?
      next_page = parent.div(class: 'v-filterselect-nextpage')
      loop do
        next_page.click if next_page.exists?
        sleep 1.5
        break if popup_text.exists?
      end
    end
  end
end
