
use Test::More;

BEGIN{
	eval "use Time::HiRes qw/time sleep/";

# TODO: It is theoretically possible, though unlikely, that you can get
#	Time::HiRes::time() without getting Time::HiRes::sleep(), and in
#	order to use the HiRes functionality you only need time(), so 
#	this is a little sloppy.  OTOH, I don't really see a good way to 
#	test without a finer grain sleep.  (I know you can get finer grain
#	sleep with a three-argument select, but Time::HiRes knows this and
#	will provide you with sleep() if you have select().  Presumably, 
#	it knows the tricks better than I do.)  So... if you can think of
#	a good way to test without getting sleep, testing patches are
#	welcome.

	if($@){
		plan skip_all	=>	"Time::HiRes isn't available on this system.";
	} else {
		plan tests	=>	3;
	}
}

use_ok('Tie::Hash::Expire');

my %res;
tie %res, 'Tie::Hash::Expire', {'expire_seconds' => 1.5};

$res{foo} = 'bar';
sleep 1.2;
is($res{foo},	'bar',	'fractional sleep lower than expiration');

sleep 0.4;
ok(!defined $res{foo},	'fractional sleep higher than expiration');






