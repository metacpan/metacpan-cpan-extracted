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

use Test::More tests => 14;

BEGIN { require_ok("WWW::Shorten::Akari") }

use constant TEST_URL_LONG  => "http://google.com";
use constant TEST_URL_SHORT => "http://waa.ai/AvT";

note "These tests require a working Internet connection";

ok my $presence = WWW::Shorten::Akari->new, "Can instantiate Akari";
ok my $short = $presence->reduce(TEST_URL_LONG), "Can reduce presence of URLs";
is $short, TEST_URL_SHORT, "The reduced presence was reduced as expected";
ok my $long = $presence->increase($short), "The presence can be increased";
is $long, TEST_URL_LONG, "The increased presence is as it was before reduction";

is $presence->shorten($long), $short, "'shorten' alias works";
is $presence->short_link($long), $short, "'short_link' alias works";
is $presence->makeashorterlink($long), $short, "'makeashortlink' alias works";

is $presence->extract($short), $long, "'extract' alias works";
is $presence->unshorten($short), $long, "'unshorten' alias works";
is $presence->lengthen($short), $long, "'lengthen' alias works";
is $presence->long_link($short), $long, "'long_link' alias works";
is $presence->makealongerlink($short), $long, "'makealonglink' alias works";
