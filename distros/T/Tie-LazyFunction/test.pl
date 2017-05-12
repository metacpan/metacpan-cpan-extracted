# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 11 };
use Tie::LazyFunction;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $d; #deferred

$phase = 1; $arg = 1;
ok( (tie $d , Tie::LazyFunction, sub { $phase + $_[0] }, $arg) );

ok( $d == 2 );

$arg = 2;
ok ($d == 3 );

sub checkinside($){
	
	$phase = 2;
	$_[0];

};

ok(checkinside($d) == 4);

# test deferral of deferred vars in deferred args

ok( tie $d2, Tie::LazyFunction, sub { 100 * $_[0] + $_[1] }, $d, $arg2 );

$arg2 = 1;
ok( $d2 == 401 );

$phase = 3;
ok( $d2 == 501 );

sub dienow::TIESCALAR{ my $r; bless \$r,'dienow'};
sub dienow::FETCH{ die };

tie $grenade, 'dienow';

tie $danger, Tie::LazyFunction, sub { "ignoring arguments"}, $grenade;

ok ($danger eq "ignoring arguments");

tie $danger2, Tie::LazyFunction, sub { "ignoring arguments"}, $grenade, 1..10;
tie $danger3, Tie::LazyFunction, sub { "first arg is ".$_[0]}, $grenade, 1..10;

eval { defined $danger2 };
ok ($@);
eval { defined $danger3 };
ok ($@);
