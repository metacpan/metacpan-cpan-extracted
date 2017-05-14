#!/usr/bin/perl -w

my $loaded;

use strict;

BEGIN { $| = 1; print "1..4\n"; }
END { print "not ok 1\n" unless $loaded; }

use Tie::Scalar::Decay;

$loaded=1;
print "ok 1\n";

tie my $scalar, 'Tie::Scalar::Decay', (  # test radioactive decay
	VALUE    => 10
);
sleep 3;
if($scalar == 10) {                      # good, hasn't decayed yet
	sleep 3;
	print "not " unless($scalar == 5);
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

tie $scalar, 'Tie::Scalar::Decay', (     # test suffix on period, and
	VALUE    => 10,                  # an evalled FUNCTION
	FUNCTION => '$value-=1',
	PERIOD   => (1/30).'m'
);
sleep 1;
if($scalar == 10) {                      # good, hasn't decayed yet
	sleep 2;
	print "not " unless($scalar == 9);
	print "ok 3\n";
	sleep 4;
	print "not " unless($scalar == 7);
	print "ok 4\n";
} else {
        print "not ok 3\n";
        print "not ok 4\n";
}

# Don't do this test - too sensitive to system load
#
# tie $scalar, 'Tie::Scalar::Decay', (     # test a coderef FUNCTION
# 	VALUE    => 0,                   # and a sub-second PERIOD
# 	FUNCTION => \&increment,
# 	PERIOD   => 0.1
# );
# my $sequence='';
# while($scalar<10) {
# 	select(undef, undef, undef, 0.1);
# 	$sequence.="$scalar ";
# }
# print "not " unless($sequence eq '0 1 2 3 4 5 6 7 8 9 10 ');
# print "ok 5\n";

sub increment { $_[0]+1; }
