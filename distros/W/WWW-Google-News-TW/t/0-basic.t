#!/usr/bin/perl
use strict;
use Test::More tests => 2;

BEGIN { use_ok('WWW::Google::News::TW',qw(get_news_for_topic get_news)); }
ok($WWW::Google::News::TW::VERSION) if $WWW::Google::News::TW::VERSION or 1;
