module Features
  module Helpers
    def render_page(name = 'last_page.png')
      #page.driver.render(name, full: true)
      save_and_open_page
    end

    def render_on_error(&block)
      start = Time.now
      begin
        yield
      rescue Capybara::ElementNotFound => e
        duration = Time.now - start
        render_page
        raise Capybara::ElementNotFound.new(e.message + " (#{duration})")
      end
    end

    def debug_page
      page.driver.debug
    end
  end
end
