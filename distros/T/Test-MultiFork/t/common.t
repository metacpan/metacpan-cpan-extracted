#!perl -I.

#
# This test assumes that everything will happen
# fast enough.  If it doesn't, then the test will
# fail.  There is no guarentee of sucess, just an
# expectation.
#

use Test::MultiFork;
use Time::HiRes qw(sleep);

FORK_a5:

my (undef, undef, $number) = procname;

print "1..$number\n";

lockcommon();
my $x = getcommon();
$x->{$number} = $$;
setcommon($x);
unlockcommon();

#print STDERR "# $number sleeps$$\n";
sleep(0.5 * ($number+1));
#print STDERR "# $number wakeup$$\n";

lockcommon();
$x = getcommon();
$x->{$number} = $$;
setcommon($x);
unlockcommon();

for my $i (1..$number) {
	print (exists $x->{$i} ? "ok $i\n" : "not ok $i\n");
}

