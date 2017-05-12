use strict;
use warnings;

use Test::Builder::Tester tests => 30;
use Test::More;

# Test using the module.
use_ok 'Test::Numeric';

# Test that the _split_format function works.
my %good_formats = (
    '0.0'     => [ 0, 0,     0, 0 ],
    '1.1'     => [ 1, 1,     1, 1 ],
    '1-2.3-4' => [ 1, 2,     3, 4 ],
    '1-.2-'   => [ 1, undef, 2, undef ]
);

my @bad_formats = qw(
  .
  1.
  .1
  -1.1
);

ok( test_split( $_, $good_formats{$_} ), "Testing good format '$_'" )
  for sort keys %good_formats;

{

    # Suppress the bad format warnings.
    no warnings 'redefine';
    local *Test::Numeric::_split_format_error = sub { 0 };

    ok( Test::Numeric::_split_format($_) == 0, "Testing bad format '$_'" )
      for @bad_formats;
}

sub test_split {
    my $format   = shift;
    my $expected = shift;
    my @actual   = Test::Numeric::_split_format($format);

    return eq_array( \@actual, $expected );
}

# Test the is_formatted function

my %good_tests = (
    '1.1'   => [ '0.0',  '1.2' ],
    '0.1'   => ['.1'],
    '1.2-3' => [ '1.12', '1.123' ],
    '1.2-' => [ '1.12', '1.123', '1.123456789' ],
);

my %bad_tests = (
    '1.1'   => [ '1.12', '12.1', '12.12' ],
    '1.2-3' => [ '1.1',  '1.1234' ],
    '1.2-'  => [ '1.1',  '1.' ],
);

foreach my $format ( sort keys %good_tests ) {
    ok Test::Numeric::_test_formatted( $format, $_ ),
      "Testing good format '$format' with '$_'"
      for @{ $good_tests{$format} };
}

foreach my $format ( sort keys %bad_tests ) {
    ok !Test::Numeric::_test_formatted( $format, $_ ),
      "Testing bad format '$format' with '$_'"
      for @{ $bad_tests{$format} };
}

test_out('ok 1 - foo');
is_formatted( '1.1', '1.1', 'foo' );
test_test("is_formatted");

test_out('not ok 1 - foo');
test_fail(+1);
is_formatted( '1.1', '12.12', 'foo' );
test_test("is_formatted");

test_out('ok 1 - foo');
isnt_formatted( '1.1', '12.12', 'foo' );
test_test("isnt_formatted");

test_out('not ok 1 - foo');
test_fail(+1);
isnt_formatted( '1.1', '1.1', 'foo' );
test_test("isnt_formatted");

# Test with bad formats.

test_out('not ok 1 - foo');
test_diag("The format 'bad' is not valid");
test_fail(+1);
is_formatted( 'bad', '12.12', 'foo' );
test_test("is_formatted with bad format");

test_out('not ok 1 - foo');
test_diag("The format 'bad' is not valid");
test_fail(+1);
isnt_formatted( 'bad', '1.1', 'foo' );
test_test("isnt_formatted with bad format");

