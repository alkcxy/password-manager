FROM ruby:3.3-slim
LABEL Alessio Caradossi <alkcxy@gmail.com>
RUN mkdir /password-manager
WORKDIR /password-manager
ARG ZSCALER_CERT=
RUN apt-get update && apt-get upgrade -y && apt-get install -y -qq build-essential ca-certificates libyaml-dev --fix-missing --no-install-recommends && \
    if [ -n "${ZSCALER_CERT}" ]; then printf '%s' "${ZSCALER_CERT}" | base64 -d > /usr/local/share/ca-certificates/zscaler_ca.crt && update-ca-certificates; fi && \
    rm -rf /var/lib/apt/lists/*
COPY . /password-manager
RUN bundle install