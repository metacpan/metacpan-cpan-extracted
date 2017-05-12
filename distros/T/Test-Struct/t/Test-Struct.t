use Test::Builder::Tester tests => 17;
use Test::Struct;
use strict;
use warnings;

my $AHASH = {
              First  => 'R: $ARRAY1->[0]',
              Second => 'R: $ARRAY1->[1]'
            };
my $AARRAY = [
               qr/Fido/i,
               'Wags',
               $AHASH
             ];
$AHASH->{First} = \$AARRAY->[0];
$AHASH->{Second} = \$AARRAY->[1];

my $BHASH = {
              First  => 'R: $ARRAY1->[0]',
              Second => 'R: $ARRAY1->[1]'
            };
my $BARRAY = [
               qr/Fido/i,
               'Wags',
               $BHASH
             ];
$BHASH->{First} = \$BARRAY->[0];
$BHASH->{Second} = \$BARRAY->[1];

# 1
test_out("ok 1");
deep_eq( [ $AHASH, $AARRAY ], [ $BHASH, $BARRAY ] );
test_test("deep_eq() works");

# 2
test_out("ok 1");
deep_eq( 1, 1 );
test_test("1 vs 1");

# 3
test_out("ok 1");
deep_eq( undef, undef );
test_test("undef vs undef");

# 4
test_out("ok 1");
deep_eq( "foo", "foo" );
test_test("'foo' vs 'foo'");

# 5
test_out("ok 1");
deep_eq( qr/baz/, qr/baz/ );
test_test("qr/baz/ vs qr/baz/");

my $foo='foo';

# 6
test_out("not ok 1");
test_fail(+2);
test_diag('at $got not expecting defined value.');
deep_eq( $foo,undef);
test_test("'foo' vs undef");

# 7
test_out("not ok 1");
test_fail(+2);
test_diag('at $got expecting value isa reference.');
deep_eq( $foo,[]);
test_test("'foo' vs []");

# 8
test_out("not ok 1");
test_fail(+3);
test_diag('at $got expecting a blessed ref.',
          'at $got expecting reftype "SCALAR" but got "ARRAY".');
deep_eq( [],qr/foo/);
test_test("[] vs qr/foo/");

# 9
test_out("not ok 1");
test_fail(+2);
test_diag('at $got not expecting a readonly value.');
deep_eq( 'foo',$foo);
test_test("'foo' vs \$foo='foo'");

# 10
my ($x,$y,$z)=({},{},{});
test_out("not ok 1");
test_fail(+2);
test_diag('not expected to have seen reference in $got->[1] before at $got->[0].');
deep_eq( [$x,$x],[$y,$z]);
test_test('[$x,$x],[$y,$z]');

# 11
test_out("not ok 1");
test_fail(+2);
test_diag('not expected to have seen $got->[1] before at $got->[0].');
deep_eq( sub{\@_}->($x,$x),[$y,$z]);
test_test('aliased [$x,$x],[$y,$z]');

# 12
test_out("not ok 1");
test_fail(+2);
test_diag('at @{$got} expecting element count of "2" but got "3".');
deep_eq( [$x,{},1],[$y,$z]);
test_test('[$x,$x],[$y,$z]');

# 13
test_out("not ok 1");
test_fail(+2);
test_diag('at @{$got} expecting element count of "3" but got "2".');
deep_eq( [$x,{}],[$y,$z,1]);
test_test('[$x,$x],[$y,$z]');

# 14
test_out("not ok 1");
test_fail(+3);
test_diag('at @{$got} expecting element count of "3" but got "2".',
          'at $got->[1] expecting reftype "HASH" but got "ARRAY".');
deep_eq( [$x,[]],[$y,$z,1]);
test_test('[$x,$x],[$y,$z]');

# 15
{
    my ($ar1,$x,$y)=([]);
    $ar1->[0]=\$ar1->[1];
    $ar1->[1]=\$ar1->[0];
    $x=\$y;
    $y=\$x;
    my $ar2=[$x,$y];
test_out("not ok 1");
test_fail(+3);
test_diag('not expected to have seen ${${$got->[0]}} before at $got->[0].',
          'not expected to have seen $got->[1] before at ${$got->[0]}.');
deep_eq( $ar1,$ar2);
test_test('Scalar cross');

}

# 16
{
    my ($ar1,$x,$y)=([]);
    $ar1->[0]=\$ar1->[1];
    $ar1->[1]=\$ar1->[0];
    $x=\$y;
    $y=\$x;
    my $ar2=[$x,$y];
test_out("ok 1");
deep_eq( $ar1, sub{\@_}->($x,$y));
test_test('Scalar cross alias');
}

# 17
{
    my %hash1=(a=>b=>c=>d=>e=>[]);
    my %hash2=(a=>1,b=>2,c=>3,d=>4,e=>{});
test_out("not ok 1");
test_fail(+8);
test_err(split /\n/,<<'ENDERRORS');
# at $got->{"e"} expecting reftype "HASH" but got "ARRAY".
# at $got->{"c"} expecting value of "3" but got "d".
# at $got->{"a"} expecting value of "1" but got "b".
# at %{$got} expecting key "b".
# at %{$got} expecting key "d".
ENDERRORS
deep_eq( \%hash1, \%hash2 );
test_test('Hash differences');
}
