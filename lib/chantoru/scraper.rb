module Chantoru
  LOGIN_URL = 'https://auth.api.sonyentertainmentnetwork.com/2.0/oauth/authorize?response_type=code&client_id=bcff2bf0-d77e-493c-9bae-e34d2d47b8ca&redirect_uri=https://tv.so-net.ne.jp/chan-toru/sen/&scope=psn:s2s'.freeze
  RECORDED_LISTS_URL = 'https://tv.so-net.ne.jp/chan-toru/list?index=0&num=10&command=title'.freeze

  class Scraper
    def initialize
      @email    = ENV['CHANTORU_ID']
      @password = ENV['CHANTORU_PASS']
      @watir = ::Watir::Browser.new(:firefox)
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

    private

    def login
      @watir.goto(LOGIN_URL)

      @watir.text_field(name: 'j_username')
        .set(@email)
      @watir.text_field(name: 'j_password')
        .set(@password)

      @watir.button(id: 'signInButton')
        .click
    end

    def latest_records
      @watir.goto(RECORDED_LISTS_URL)
      @watir.li(class: 'rawdata').click
      html = @watir.html
      json = Nokogiri::HTML(html).css('.data').first
      JSON.load(json)['list'].map { |x| x['title'] }
    end
  end
end
