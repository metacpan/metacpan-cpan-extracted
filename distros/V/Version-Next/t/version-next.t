use strict;
use warnings;

use Test::More 0.88;
END { done_testing }
use Test::Exception 0.29;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

my ($obj);
require_ok('Version::Next');
can_ok( 'Version::Next', 'next_version' );
eval "use Version::Next 'next_version'";
can_ok( 'main', 'next_version' );
is( next_version(1), 2, "1 + 1 == 2" );

my @errors = qw(
  abc
  1_00_01
  1.00_
  1..0
  v1_
  v.2
  .1.
  .1.2.
  1_1.
);

for my $error_case (@errors) {
    throws_ok { next_version($error_case) }
    qr/Doesn't look like a version number: '$error_case' at/,
      "throws error on bad input ($error_case)";
}

for my $case (<DATA>) {
    chomp $case;
    next if $case =~ m{\A(?:#|\s*\z)};
    my ( $input, $output ) = split ' ', $case;
    is( next_version($input), $output, "$input -> $output" );
}

__DATA__
# Decimals
0       1
1       2
9       10

0.0     0.1
0.1     0.2
0.2     0.3
0.9     1.0
1.0     1.1

0.00    0.01
0.01    0.02
0.09    0.10
0.10    0.11
0.90    0.91
0.99    1.00
1.00    1.01

1.009   1.010
1.999   2.000
1.1000  1.1001
1.1999  1.2000

# Alpha decimals
0.0_1     0.0_2
0.0_1     0.0_2
0.0_2     0.0_3
0.0_9     0.1_0
1.0_0     1.0_1

0.0_00    0.0_01
0.0_01    0.0_02
0.0_09    0.0_10
0.0_10    0.0_11
0.0_90    0.0_91
0.0_99    0.1_00
1.0_00    1.0_01

1.0_009   1.0_010
1.0_999   1.1_000
1.0_1000  1.0_1001
1.0_1999  1.0_2000

1.23_01   1.23_02
1.23_09   1.23_10
1.23_99   1.24_00

# Dotted Decimals
v0      v1
v1      v2
v9      v10

v0.0    v0.1
v0.1    v0.2
v0.9    v0.10
v0.10   v0.11
v0.99   v0.100
v0.999  v1.0
v0.1000 v1.0

0.0.0    0.0.1
0.0.1    0.0.2
0.0.9    0.0.10
0.0.10   0.0.11
0.0.99   0.0.100
0.0.999  0.1.0
0.0.1000 0.1.0

v0.0.0    v0.0.1
v0.0.1    v0.0.2
v0.0.9    v0.0.10
v0.0.10   v0.0.11
v0.0.99   v0.0.100
v0.0.999  v0.1.0
v0.0.1000 v0.1.0

v0.999.0        v0.999.1
v1.999.999      v2.0.0
v1.1000.1000    v2.0.0

# dotted decimals with leading zeros

v0.00.00    v0.0.1
v0.00.01    v0.0.2
v0.00.09    v0.0.10
v0.00.010   v0.0.11
v0.00.099   v0.0.100
v0.000.999  v0.1.0
v0.0.01000  v0.1.0

# weird lax stuff

undef   1
.1      0.2
.1_1    0.1_2
1.      1.1
.1.2    v0.1.3
