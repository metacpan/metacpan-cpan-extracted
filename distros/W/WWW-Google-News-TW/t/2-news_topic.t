#!/usr/bin/perl
use strict;
use Test::More tests => 2;

use WWW::Google::News::TW qw( get_news_for_topic );

#BEGIN { use_ok('WWW::Google::News::TW',qw(get_news_for_topic get_news)); }

my $results;

$results = get_news_for_topic( '國際' );

#use Data::Dumper::Simple;
#print STDERR "\n",Dumper($results);

ok(defined($results),'GN-TW: At least we got something');
ok(defined($$results[0]->{url}),'GN-TW: First result URL exists');
