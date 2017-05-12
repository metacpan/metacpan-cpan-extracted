use strict;
use Test::More
  tests => 8;

BEGIN { use_ok('POSIX',qw/strftime/) }
BEGIN { use_ok('Time::TAI64',qw/:all/) }
BEGIN {
  is( length(unixtai64(time)), 17, "Invalid Length");
  is( length(unixtai64n(time)), 25, "Invalid Length");
  is( length(unixtai64na(time)), 33, "Invalid Length");
}

SKIP: {
  eval { use Time::HiRes qw/time/ };
  skip "Cannot locad Time::HiRes", 3 if $@;

  my $now = time;
  my $tst = int($now);

  my $tai = unixtai64($tst);
  my $new = tai64unix($tai);
  cmp_ok ($tst, '==', $new, "Compare tai64 $now");

  $tst = sprintf("%.6f",$now);
  $tai = unixtai64n($tst);
  $new = tai64nunix($tai);
  cmp_ok ($tst, '==', $new, "Compare tai64n $now");

  $tst = sprintf("%.12f",$now);
  $tai = unixtai64na($tst);
  $new = tai64naunix($tai);
  cmp_ok ($now, '==', $new, "Compare tai64na $now");

}
