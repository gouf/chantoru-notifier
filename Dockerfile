FROM innocentzero/ruby:2.1.1

RUN mkdir -p /tmp/app
ADD . /tmp/app
RUN chown -R root /tmp/app

WORKDIR /tmp/app
RUN bundle
ENTRYPOINT bundle && ruby /tmp/app/chantoru_notifier.rb
