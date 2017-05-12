#! /usr/bin/env perl

use v5.8;
use strict;
use warnings;

use Test::More tests => 9;

BEGIN { require_ok("WWW::Shorten::Akari") }

diag "This test carps a lot";
note "These tests aren't supposed to access the Internet";

ok my $presence = WWW::Shorten::Akari->new, "Can instantiate Akari";
ok !$presence->reduce(), "Doesn't reduce undef";
ok !$presence->increase(), "Doesn't increase undef";
ok !$presence->reduce(""), "Doesn't reduce empty URLs";
ok !$presence->increase(""), "Doesn't increase empty URLs";
ok !$presence->increase("http://bogus.url"), "Doesn't increase random URLs";
ok !$presence->increase("http://waa.ai/"), "Doesn't increase http://waa.ai itself";
ok !$presence->increase("http://waa.ai/about.php"), "Doesn't increase non-shortened waa.ai links";
