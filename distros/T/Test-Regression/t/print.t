#!perl 

use strict;
use warnings;
our $mock;

use Test::Builder::Tester tests => 2;
use Test::More;
BEGIN {
  use FileHandle;
  eval "use Test::MockObject::Extends";
  unless( $@ ) {
    $mock = FileHandle->new;
    $mock= Test::MockObject::Extends->new($mock);
    $mock->set_false( 'print' );
    $mock->fake_new('FileHandle');
  }

  use_ok( 'Test::Regression' );
}

use Test::Regression;
srand(42);
use lib qw(t/lib);
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

sub empty_string_function {
    return '';
}

diag "mark tests start";
test_out("not ok 1 - actual write failed: t/output/f1");
test_out("not ok 2 - f1 check");
test_out("not ok 3 - actual write failed: t/output/f2");
test_out("not ok 4 - f2 check");
test_out("ok 5 - f4 gen");
test_out("ok 6 - f4 check");
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
ok_regression(\&empty_string_function, "t/output/f4", "f4 gen");
delete $ENV{TEST_REGRESSION_GEN};
ok_regression(\&empty_string_function, "t/output/f4", "f4 check");

test_test(name=>"blah", skip_err=>1);

