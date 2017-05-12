use strict;
use Test::More
 tests => 4;

BEGIN { use_ok('POSIX',qw/strftime/) }
BEGIN { use_ok('Time::TAI64',qw/:tai64na/) }
BEGIN {
  is( length(unixtai64na(time)), 33, "Invalid Length");
}

SKIP: {
  eval { use Time::HiRes qw/time/ };
  skip "Cannot load Time::HiRes", 4 if $@;

  my $now = sprintf "%.9f",time + 10;
  my $tai = unixtai64na($now);
  my $new = sprintf "%.9f",tai64naunix($tai);

  cmp_ok( $now, '==', $new, "Compare $now" );
}

