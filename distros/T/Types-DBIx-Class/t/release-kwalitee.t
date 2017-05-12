#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use Test::More;

eval "use Test::Kwalitee 'kwalitee_ok'";
plan skip_all => "Test::Kwalitee required for testing kwalitee"
  if $@;
kwalitee_ok();
done_testing;
