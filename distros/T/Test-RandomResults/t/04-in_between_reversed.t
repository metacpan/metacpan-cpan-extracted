use Test::Builder::Tester tests => 19;
use Test::More;

BEGIN {
use_ok( 'Test::RandomResults' );
}

my $desc;

# numeric comparisons

my $num_cmp = sub { $_[0] <=> $_[1] };

$desc = "5 between 1 and 10";
test_out("ok 1 - $desc");
in_between( 5, $num_cmp, 10, 1, $desc);
test_test( $desc );

$desc = "5 between 1 and 5";
test_out("ok 1 - $desc");
in_between( 5, $num_cmp, 5, 1, $desc);
test_test( $desc );

$desc = "5 between 5 and 5";
test_out("ok 1 - $desc");
in_between( 5, $num_cmp, 10, 5, $desc);
test_test( $desc );

$desc = "5 between 5 and 10";
test_out("ok 1 - $desc");
in_between( 5, $num_cmp, 5, 5, $desc);
test_test( $desc );

$desc = "5 not between 10 and 20";
test_out( "not ok 1 - $desc" );
test_fail(+2);
test_diag( "        5 not between 10 and 20" );
in_between( 5, $num_cmp, 20, 10, $desc);
test_test( $desc );

$desc = "5 not between 1 and 3";
test_out( "not ok 1 - $desc" );
test_fail(+2);
test_diag( "        5 not between 1 and 3" );
in_between( 5, $num_cmp, 3, 1, $desc);
test_test( $desc );

$desc = "5 not between 1 and 4";
test_out( "not ok 1 - $desc" );
test_fail(+2);
test_diag( "        5 not between 1 and 4" );
in_between( 5, $num_cmp, 4, 1, $desc);
test_test( $desc );

$desc = "5 not between 6 and 10";
test_out( "not ok 1 - $desc" );
test_fail(+2);
test_diag( "        5 not between 6 and 10" );
in_between( 5, $num_cmp, 10, 6, $desc);
test_test( $desc );

$desc = "5 not between 7 and 10";
test_out( "not ok 1 - $desc" );
test_fail(+2);
test_diag( "        5 not between 7 and 10" );
in_between( 5, $num_cmp, 10, 7, $desc);
test_test( $desc );

# string comparisons

my $str_cmp = sub { $_[0] cmp $_[1] };

$desc = "b between a and b";
test_out("ok 1 - $desc");
in_between( "b", $str_cmp, "b", "a", $desc);
test_test( $desc );

$desc = "b between b and c";
test_out("ok 1 - $desc");
in_between( "b", $str_cmp, "c", "b", $desc);
test_test( $desc );

$desc = "b between a and c";
test_out("ok 1 - $desc");
in_between( "b", $str_cmp, "c", "a", $desc);
test_test( $desc );

$desc = "b between b and b";
test_out("ok 1 - $desc");
in_between( "b", $str_cmp, "b", "b", $desc);
test_test( $desc );

$desc = "bbbbb between a and c";
test_out("ok 1 - $desc");
in_between( "bbbbb", $str_cmp, "bbbbbb", "a", $desc);
test_test( $desc );

$desc = "bbbb between a and c";
test_out("ok 1 - $desc");
in_between( "bbbb", $str_cmp, "c", "a", $desc);
test_test( $desc );

$desc = "b not between c and d";
test_out( "not ok 1 - $desc" );
test_fail(+2);
test_diag( "        b not between c and d" );
in_between( "b", $str_cmp, "d", "c", $desc);
test_test( $desc );

$desc = "b not between d and e";
test_out( "not ok 1 - $desc" );
test_fail(+2);
test_diag( "        b not between d and e" );
in_between( "b", $str_cmp, "e", "d", $desc);
test_test( $desc );

$desc = "bbbbb not between a and bbbb";
test_out( "not ok 1 - $desc" );
test_fail(+2);
test_diag( "        bbbbb not between a and bbbb" );
in_between( "bbbbb", $str_cmp, "bbbb", "a", $desc);
test_test( $desc );
