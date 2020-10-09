FROM alpine:3.12.0

RUN apk update && apk add \
    perl \
  && true

COPY perl5 /yamltidy

ENV PERL5LIB=/yamltidy/lib/perl5 PATH=/yamltidy/bin:$PATH
