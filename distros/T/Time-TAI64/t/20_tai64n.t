use strict;
use Test::More
  tests => 12;

BEGIN { use_ok('POSIX',qw/strftime/) }
BEGIN { use_ok('Time::TAI64',qw/:tai64n/) }
BEGIN {
  is( length(unixtai64n(time)), 25, "Invalid Length" );
}

SKIP: {
  eval {use Time::HiRes qw(time)};
  skip "Cannot Load Time::HiRes", 9 if $@;

  #
  ## Well Known TAI64N Strings
  ##

  is( unixtai64n(1), '@400000000000000b00000000', 'unixtai64n(1)'  );
  is( unixtai64n(1,500_000_000), '@400000000000000b1dcd6500', 'unixtai64n(1,500_000_000)' );
  is( unixtai64n(1.194785), '@400000000000000b0b9c2ee8', 'unixtai64n(1.194785)' );
  is( unixtai64n(1.784526), '@400000000000000b2ec2eab0', 'unixtai64n(1.784526)' );

  is( sprintf("%.6f",tai64nunix('@400000000000000b00000000')), "1.000000" );
  is( sprintf("%.6f",tai64nunix('@400000000000000b1dcd6500')), "1.500000" );
  is( sprintf("%.6f",tai64nunix('@400000000000000b0b9c2ee8')), "1.194785" );
  is( sprintf("%.6f",tai64nunix('@400000000000000b2ec2eab0')), "1.784526" );

  my $now = sprintf "%.6f",time;
  my $tai = unixtai64n($now);
  my $new = sprintf "%.6f",tai64nunix($tai);

  cmp_ok( $now, '==', $new, "Compare $now" );
}

