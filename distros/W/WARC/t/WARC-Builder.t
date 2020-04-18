# Unit tests for WARC::Builder module				# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests => 2;
BEGIN { use_ok('WARC::Builder')
	  or BAIL_OUT "WARC::Builder failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Builder v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Builder version check')
}
