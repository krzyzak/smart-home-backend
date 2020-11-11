FROM ruby:2.7.0-buster

WORKDIR /app

RUN apt-get update && apt-get install --no-install-recommends -y \
  nano \
  tzdata \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cp /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

ADD Gemfile ./
ADD Gemfile.lock ./

RUN gem install bundler -v 2.1

RUN bundle install --jobs=4 --deployment --without="test development" \
  && rm -r vendor/bundle/ruby/2.7.0/cache/*.gem \
  && bundle clean

RUN gem install foreman
# Copy app
COPY . ./

RUN mkdir -p tmp/pids
CMD ["foreman", "start"]

