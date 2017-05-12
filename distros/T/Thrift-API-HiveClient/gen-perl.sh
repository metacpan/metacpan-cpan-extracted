#!/bin/bash

set -e

thrift \
  --gen perl \
  --allow-64bit-consts \
  -strict \
  -recurse \
  -I ./thrift-inc \
  thrift-inc/service/if/hive_service.thrift

gen_perl=./gen-perl

for pm in $(find $gen_perl -name '*.pm'); do
  perl -p -i -e 's/^package/package\n  /' $pm
  mkdir -p $(dirname lib/${pm##$gen_perl/})
  cp $pm lib/${pm##$gen_perl/}
done

rm -rf gen-perl
