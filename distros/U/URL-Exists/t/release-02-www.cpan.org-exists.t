#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use Test::More 0.88 tests => 1;
use URL::Exists qw/ url_exists /;

ok(url_exists('http://www.cpan.org'), "www.cpan.org should exist");
