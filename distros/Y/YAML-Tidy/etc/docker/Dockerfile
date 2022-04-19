FROM alpine:3.15.4

RUN apk update && apk add \
    perl \
  && true

COPY perl5 /yamltidy

ENV PERL5LIB=/yamltidy/lib/perl5 PATH=/yamltidy/bin:$PATH

WORKDIR /pwd
