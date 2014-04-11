#encoding: UTF-8
require 'nokogiri'
require 'mechanize'
require 'aws-sdk'
require 'json'
require 'kconv'
require 'eventmachine'
require 'logger'

ID   = ENV['CHANTORU_ID']
PASS = ENV['CHANTORU_PASS']

@a = Mechanize.new {|agent|
  agent.user_agent_alias = 'Mac Safari'
}
@l = Logger.new('log', 'daily')
@l.info('Program started')

def latest_list page
  # Get latest recorded list. format.
  new_title_list = JSON.restore(page.content.to_s)['list'].collect do |d|
    "#{d['title']}"
  end
  old_title_list = JSON.restore(File.open('recorded_list.json', 'r').read)
  File.open('recorded_list.json', 'w') do |f|
    f.write new_title_list.to_json
  end
  res = new_title_list - old_title_list
end

def login id, pass
  # Login ID/PASS
  uri = 'https://account.sonyentertainmentnetwork.com/external/auth/login.action?returnURL=https://tv.so-net.ne.jp/chan-toru/sen'
  @a.get(uri) do |page|
    res = page.form_with(id: 'signInForm') do |f|
      f.field_with(name: 'j_username').value = id
      f.field_with(name: 'j_password').value = pass
    end.submit
  end
end

def send_email opt
  ses = AWS::SimpleEmailService.new(
    access_key_id: ENV['AWS_ACCESS_KEY_ID'],
    secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  )

  # format
  body_text = opt[:body_text].inject(""){|body, x| body += "・#{x}\n"}
  body_html = opt[:body_html].inject(""){|body, x| body += "・#{x}<br />"}

  # send
  ses.send_email(
    subject: '新着タイトルのお知らせ',
    to: opt[:to_email],
    from: opt[:from_email],
    body_text: body_text,
    body_html: body_html,
    body_text_charset: 'UTF-8'
  )
  return 'The message has been send.'
end

# Get recorded list
def get_recorded_list
  uri = 'https://tv.so-net.ne.jp/chan-toru/list?index=0&num=10&command=title'
  return 'Faild to log in.' if (login(ID, PASS)).nil?
  return 'Faild to get recerded list.' if (page = @a.get(uri)).nil?
  res = latest_list(page)
  unless res.size == 0 then
    # set up mail send
    to_email = ENV['CHANTORU_ID']
    from_email = 'noreply@example.com'

    send_email({body_text: res, body_html: res, to_email: to_email, from_email: from_email})
  else
    return 'No new recorded list yet.'
  end
end

# Run
@l.info(get_recorded_list)
EM.run do
  # 1 hour cycle. (60sec. * 60)
  EM.add_periodic_timer(60 * 60){@l.info(get_recorded_list)}
end
