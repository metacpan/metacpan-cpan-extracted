#! /usr/bin/env perl

use v5.8;
use strict;
use warnings;

use Test::More tests => 6;

BEGIN { require_ok("WWW::Shorten::Akari") }

ok !__PACKAGE__->can('makeashorterlink'), "'makeashorterlink' is not imported";
ok !__PACKAGE__->can('short_link'), "'short_link' is not imported";

WWW::Shorten::Akari->import(qw{short_link});
ok  __PACKAGE__->can('short_link'), "'short_link' is now imported";
ok !__PACKAGE__->can('makeashorterlink'), "'makeashorterlink' is still not imported";

WWW::Shorten::Akari->import(qw{:default});
ok  __PACKAGE__->can('makeashorterlink'), "'makeashorterlink' is now imported";
