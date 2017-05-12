FROM ubuntu:yakkety

RUN apt-get update && apt-get -y install \
    git make \
    libhyperscan-dev libperl-dev libdevel-checklib-perl \
    libtest-kwalitee-perl libtest-pod-coverage-perl \
    libtest-pod-perl libtest-spelling-perl

RUN mkdir /build
WORKDIR /build
