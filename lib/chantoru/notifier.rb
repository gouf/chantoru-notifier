module Chantoru
  # Report recorded video list what's new.
  class Notifier
    SEND_TO = ENV['CHANTORU_SEND_TO']
    SENT_FROM = ENV['CHANTORU_SENT_FROM']

    def report_new_titles(body)
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
        to: SEND_TO,
        from: SENT_FROM,
        body_text: body_text,
        body_html: body_html,
        body_text_charset: 'UTF-8'
      )
      info('Message has been sent.')
    end

    def formated_body(body, type)
      case type
      when :text
        body.inject('') do |ret, title|
          ret += "・#{title}\n"
        end
      when :html
        body.inject('') do |ret, title|
          ret += "・#{title}<br />"
        end
      end
    end
  end
end
