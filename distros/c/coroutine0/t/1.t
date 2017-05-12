# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 16, todo => [] };
use coroutine0;
ok(1); # If we made it this far, we're ok. #'

$coderef = new coroutine0
	# DIE => 1,
	VARS => [qw{$number $another}],
	# PRE => 'print "$number\n";',
	BODY => <<'EOF',
		$number = 1;
		YIELD ($_[0] + $number++);
		YIELD $_[0] + $number++;
		YIELD ($_[0] + $number++);
EOF
	PROTO => '($)';
ok($coderef);

$another = copy $coderef;
ok($another);


sub addn($);

*addn = $another;

ok(addn(3) , 4 );
ok(addn(2) , 4 );
ok(addn(1) , 4 ); # test 6


# after yielding everything, yield an undef and return
ok(!defined(addn(200)));

# back to $number == 1
ok(&$another(23), 24 );

# addn and another should be using the same pad
ok(addn 22 , 24); # test 9

# but $coderef has its own pad
ok(&$coderef(23), 24); 
ok(&$another(21), 24);

# we expect \&addn to be blessed
$crefname = ref(\&addn);
ok($crefname,'coroutine0');
$cref = \&addn;
eval {
  # $another_copy = copy $cref;
  $another_copy = copy {\&addn};
  *yet_another_copy = (\&addn)->copy();
};
ok(!$@);
ok(&$another_copy(23), 24);
ok(yet_another_copy(23), 24);
ok(&$another_copy(23), 25); # separate pad.

