#! /usr/bin/env perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use v5.8;
use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok("WWW::Shorten::Akari", qw{:short}) }

use constant TEST_URL_LONG  => "https://twitter.com/anime_yuruyuri";
use constant TEST_URL_SHORT => "http://waa.ai/4Gi";

note "These tests require a working Internet connection";

ok my $short = short_link(TEST_URL_LONG), "Can reduce presence of URLs";
is $short, TEST_URL_SHORT, "The reduced presence was reduced as expected";
ok my $long = long_link($short), "The presence can be increased";
is $long, TEST_URL_LONG, "The increased presence is as it was before reduction";
