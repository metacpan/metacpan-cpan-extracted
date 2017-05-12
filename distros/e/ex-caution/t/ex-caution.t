# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ex-caution.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('ex::caution') };

{
    my $last_warn;
    local $SIG{__WARN__}=sub { $last_warn=shift; return };
    my $x;
    use ex::caution;
    $x="1".$x;
    like($last_warn,qr/uninitialized value/,"use ex::caution; works with warnings");
    $last_warn = $x = undef;
    no ex::caution;
    $x="1".$x;
    is($last_warn,undef,'no ex::caution; works with warnings');
}
use vars qw($x $y);

{
    use ex::caution;
    $x=1; $y='x';
    my $eval_success= eval '$$y=2; $x';
    my $eval_error= $eval_success ? '' : $@;
    is($eval_success,undef,'under ex::caution eval should through an error');
    like($eval_error,qr/strict refs/,'and the error should be about strict refs');
}
{
    use strict;
    no ex::caution;
    $x=1; $y='x';
    my $eval_success= eval '$$y=2; $x';
    my $eval_error= $eval_success ? '' : $@;
    is($eval_success,2,'under ex::caution eval should not through an error');
    is($eval_error,'','and there should be no error');
}


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

