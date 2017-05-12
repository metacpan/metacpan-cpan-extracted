#!/usr/bin/env perl

use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.

use Capture::Tiny 'capture';

use Test2::Bundle::Extended; # Turns on strict and warnings.

use WWW::Scraper::Wikipedia::ISO3166::Database;

# ---------------------------------------------

my(@params);

push @params, '-Ilib', 'scripts/report.statistics.pl';
push @params, '-max', 'info';

my($stdout, $stderr, $result)	= capture{system($^X, @params)};
my(@got)						= map{s/\s+$//; $_} split(/\n/, $stdout);
my(@expected)					= split(/\n/, <<EOS);
countries_in_db => 249
has_subcounties => 200
subcountries_in_db => 5297
subcountry_categories_in_db => 77
subcountry_files_downloaded => 249
subcountry_info_in_db => 352
EOS

is(\@got, \@expected, 'report_statistics() returned the expected data');

@params = ();

push @params, '-Ilib', 'scripts/report.Australian.statistics.pl';
push @params, '-max', 'info';

($stdout, $stderr, $result)	= capture{system($^X, @params)};
(@got)						= map{s/\s+$//; $_} split(/\n/, $stdout);
(@expected)					= split(/\n/, <<EOS);
1: Australian Capital Territory
2: New South Wales
3: Northern Territory
4: Queensland
5: South Australia
6: Tasmania
7: Victoria
8: Western Australia
EOS

is(\@got, \@expected, 'report_Australian_statistics() returned the expected data');

done_testing;
