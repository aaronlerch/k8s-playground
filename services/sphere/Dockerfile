FROM ruby:2.7.1-alpine

RUN apk add --no-cache g++ musl-dev make libstdc++

RUN adduser -D app-user
USER app-user

WORKDIR /home/app-user/app

ADD Gemfile Gemfile.lock ./
RUN bundle install

ENV APP_ENV=production
EXPOSE 4567

COPY --chown=app-user . .

CMD ruby app.rb