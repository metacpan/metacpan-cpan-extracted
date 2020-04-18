# Tests for WARC convenience loader module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests => 4;
BEGIN { use_ok('WARC')
	  or BAIL_OUT "WARC failed to load" };

BEGIN {
  my $fail = 0;
  eval q{use WARC v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC version v9999.*required--this is only version/,
     'WARC version check')
}

ok(exists &WARC::Collection::assemble,	'WARC::Collection loaded');
ok(exists &WARC::Volume::mount,	'WARC::Volume loaded');
