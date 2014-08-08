#encoding: UTF-8
require 'bundler'
Bundler.require

class ChantoruNotifier
  def initialize
    @id   = ENV['CHANTORU_ID']
    @pass = ENV['CHANTORU_PASS']
    @a = Mechanize.new {|agent| agent.user_agent_alias = 'Mac Safari'}
    @l = Logger.new('log', 'daily')
    @to_email_address   = @id
    @from_email_address = ENV['CHANTORU_FROM']
    write_current_pid
    login
  end

  public
  def check_new_titles
    titles = get_latest_records(@a.get(recorded_list_url))
    unless titles.size == 0 then
      # Notify to user
      report_new_titles(titles)
    else
      info('Got no new titles')
    end
  end
  def info text
    @l.info(text)
  end

  private
  def login_url
    'https://auth.api.sonyentertainmentnetwork.com/2.0/oauth/authorize?response_type=code&client_id=bcff2bf0-d77e-493c-9bae-e34d2d47b8ca&redirect_uri=https://tv.so-net.ne.jp/chan-toru/sen/&scope=psn:s2s'
  end
  def recorded_list_url
    'https://tv.so-net.ne.jp/chan-toru/list?index=0&num=10&command=title'
  end
  def login
    @a.get(login_url) do |page|
      page.form_with(id: 'signInForm') do |f|
        f.field_with(name: 'j_username').value = @id
        f.field_with(name: 'j_password').value = @pass
      end.submit
    end
  end
  def get_latest_records page
    # Get latest titles.
    new_titles = load_new_titles(page)
    old_titles = load_old_titles
    save_to_file(new_titles)
    extract_new_titles(new_titles, old_titles)
  end
  def load_new_titles page
    return [] if JSON.restore(page.content.to_s)['list'].nil?
    JSON.restore(page.content.to_s)['list'].collect do |d|
      "#{d['title']}"
    end
  end
  def save_to_file titles
    File.open('recorded_list.json', 'w') do |f|
      f.write titles.to_json
    end
  end
  def load_old_titles
    JSON.restore(File.open('recorded_list.json', 'r').read)
  end
  def extract_new_titles new_titles, old_titles
    # Compare 2 arrays.
    # it will only get new titles

    (new_titles | old_titles) - old_titles
  end
  def report_new_titles body
    # Setup AWS SES
    ses = AWS::SimpleEmailService.new(
      access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )

    # format title texts
    body_text = formated_body(body, :text)
    body_html = formated_body(body, :html)

    # send
    ses.send_email(
      subject: '新着タイトルのお知らせ',
      to: @to_email_address,
      from: @from_email_address,
      body_text: body_text,
      body_html: body_html,
      body_text_charset: 'UTF-8'
    )
    info('Message has been sent.')
  end
  def formated_body body, type
    case type
      when :text
        body.inject("") {|formated_body, title|
          formated_body += "・#{title}\n"
        }
      when :html
        body.inject(""){|formated_body, title|
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

# Run
chantoru = ChantoruNotifier.new
chantoru.info('Program has started')
chantoru.check_new_titles
EM.run do
  # 4 hour cycle. (60sec. * 60 * 4)
  EM.add_periodic_timer(60 * 60 * 4){
    chantoru = ChantoruNotifier.new
    chantoru.check_new_titles
  }
end
