FROM ruby:3.3-slim
LABEL Alessio Caradossi <alkcxy@gmail.com>
RUN mkdir /password-manager
WORKDIR /password-manager
# Add Zscaler root CA so bundle install can reach rubygems.org through SSL inspection proxy
COPY zscaler_ca.pem /usr/local/share/ca-certificates/zscaler_ca.crt
RUN apt-get update && apt-get upgrade -y && apt-get install -y -qq build-essential ca-certificates libyaml-dev --fix-missing --no-install-recommends && update-ca-certificates && rm -rf /var/lib/apt/lists/*
COPY . /password-manager
RUN bundle install