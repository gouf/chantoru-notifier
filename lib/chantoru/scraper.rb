module Chantoru
  LOGIN_URL = 'https://auth.api.sonyentertainmentnetwork.com/2.0/oauth/authorize?response_type=code&client_id=bcff2bf0-d77e-493c-9bae-e34d2d47b8ca&redirect_uri=https://tv.so-net.ne.jp/chan-toru/sen/&scope=psn:s2s'.freeze
  RECORDED_LISTS_URL = 'https://tv.so-net.ne.jp/chan-toru/list?index=0&num=10&command=title'.freeze

  class Scraper
    def initialize
      @email    = ENV['CHANTORU_ID']
      @password = ENV['CHANTORU_PASS']
      @watir = ::Watir::Browser.new(:firefox)
      @logger = Logger.new('log', 'daily')
      login

      # Can't break through Google's reCAPTCHA (the type for clicking image what specific object included).
      # So, Watir needs your help...
      loop do
        sleep 1
        break if @watir.html.to_s.include?('番組表')
      end
      latest_records
    end

    public

    def check_new_titles
      titles = latest_records
      if titles.size.zero?
        info('Got no new titles')
      else
        # Notify to user
        report_new_titles(titles)
      end
    end

    def info(text)
      @logger.info(text)
    end

    private

    def login
      @watir.goto(LOGIN_URL)

      @watir.text_field(name: 'j_username')
        .set(@email)
      @watir.text_field(name: 'j_password')
        .set(@password)

      @watir.button(id: 'signInButton')
        .click
      # @a.get(LOGIN_URL) do |page|
      #   page.form_with(id: 'signInForm') do |f|
      #     f.field_with(name: 'j_username').value = @email
      #     f.field_with(name: 'j_password').value = @password
      #   end.submit
      # end
    end

    def latest_records
      @watir.goto(RECORDED_LISTS_URL)
      @watir.li(class: 'rawdata').click
      html = @watir.html
      json = Nokogiri::HTML(html).css('.data').first
      pp JSON.load(json)['list'].map { |x| x['title'] }
      # Get latest titles.
      # new_titles = load_new_titles(page)
      # old_titles = load_old_titles
      # save_to_file(new_titles)
      # extract_new_titles(new_titles, old_titles)
    end

    def load_new_titles(page)
      return [] if JSON.restore(page.content.to_s)['list'].nil?
      JSON.restore(page.content.to_s)['list'].map do |d|
        "#{d['title']}"
      end
    end

    def save_to_file(titles)
      File.open('recorded_list.json', 'w') do |f|
        f.write titles.to_json
      end
    end

    def load_old_titles
      JSON.restore(File.open('recorded_list.json', 'r').read)
    end

    def extract_new_titles(new_titles, old_titles)
      # Compare 2 arrays.
      # it will only get new titles

      (new_titles | old_titles) - old_titles
    end

    def formated_body(body, type)
      case type
      when :text
        body.inject('') {|formated_body, title|
          formated_body += "・#{title}\n"
        }
      when :html
        body.inject('') {|formated_body, title|
          formated_body += "・#{title}<br />"
        }
      end
    end

    def write_current_pid
      File.open('chantoru-notifier.pid', 'w') do |f|
        f.write Process.pid
      end
    end
  end
end
