# Unit tests for WARC::Index::File::SDBM::Entry module		# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests => 3;
BEGIN { use_ok('WARC::Index::File::SDBM::Entry')
	  or BAIL_OUT "WARC::Index::File::SDBM::Entry failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Index::File::SDBM::Entry v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Index::File::SDBM::Entry version check')
}

isa_ok('WARC::Index::File::SDBM::Entry', 'WARC::Index::Entry');
