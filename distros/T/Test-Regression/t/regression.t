#!perl 

use strict;
use warnings;
use Test::Builder::Tester tests => 1;
use Test::More;
use Test::Regression;
use lib qw(t/lib);
srand(42);
use OutputDir;

sub faithful_function {
    my $r = "";
    for(my $i = 0; $i < 10; $i++) {
	$r .= "$i\n";
    }
    return $r;
}

sub unfaithful_function {
    my $r = "";
    for(my $i = 0; $i < 10; $i++) {
	$r .= rand()."\n";
    }
    return $r;
}

sub fatal_function {
    die "How am I doing?";
}

sub empty_string_function {
    return '';
}


test_out("ok 1 - f1 gen");
test_out("ok 2 - f1 check");
test_out("ok 3 - f2 gen");
test_out("not ok 4 - f2 check");
test_out("not ok 5 - f3 gen");
test_out("not ok 6 - f3 check");
test_out("ok 7 - f4 gen");
test_out("ok 8 - f4 check");
test_diag("  Failed test 'f2 check'");

$ENV{TEST_REGRESSION_GEN} = 1;
ok_regression(\&faithful_function, "t/output/f1", "f1 gen");
delete $ENV{TEST_REGRESSION_GEN};
ok_regression(\&faithful_function, "t/output/f1", "f1 check");
$ENV{TEST_REGRESSION_GEN} = 1;
ok_regression(\&unfaithful_function, "t/output/f2", "f2 gen");
delete $ENV{TEST_REGRESSION_GEN};
ok_regression(\&unfaithful_function, "t/output/f2", "f2 check");
$ENV{TEST_REGRESSION_GEN} = 1;
ok_regression(\&fatal_function, "t/output/f3", "f3 gen");
delete $ENV{TEST_REGRESSION_GEN};
ok_regression(\&fatal_function, "t/output/f3", "f3 check");
$ENV{TEST_REGRESSION_GEN} = 1;
ok_regression(\&empty_string_function, "t/output/f4", "f4 gen");
delete $ENV{TEST_REGRESSION_GEN};
ok_regression(\&empty_string_function, "t/output/f4", "f4 check");

test_test(name=>"blah", skip_err=>1);

