#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all =>
  "Test::Pod::Coverage 1.04 required for testing POD coverage"
  if $@;
plan tests => 2;

pod_coverage_ok($_) for qw( WWW::Comix WWW::Comix::Plugin );
