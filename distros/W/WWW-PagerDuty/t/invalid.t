#!/usr/bin/perl


use Test::More tests => 2;

BEGIN { use_ok('WWW::PagerDuty'); }

my $pager_duty = new WWW::PagerDuty();

is (ref $pager_duty, "HASH", "");

