# Unit tests for WARC::Record::Replay::HTTP module		# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests => 2 + 2 + 2;

BEGIN { use_ok('WARC::Record::Replay::HTTP')
	  or BAIL_OUT "WARC::Record::Replay::HTTP failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::Replay::HTTP v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Record::Replay::HTTP version check')
}

is($WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold,
   2 * (1<<20),		'default deferred loading threshold');
is($WARC::Record::Replay::HTTP::Content_Maximum_Length,
   128 * (1<<20),	'default maximum content length');

$WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 4*(1<<20);
$WARC::Record::Replay::HTTP::Content_Maximum_Length = 256*(1<<20);

do $INC{'WARC/Record/Replay/HTTP.pm'};	# reload file

is($WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold,
   4 * (1<<20),		'override deferred loading threshold');
is($WARC::Record::Replay::HTTP::Content_Maximum_Length,
   256 * (1<<20),	'override maximum content length');
