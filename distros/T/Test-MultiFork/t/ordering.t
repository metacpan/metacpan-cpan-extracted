#!perl -I.

use Test::MultiFork;
use Time::HiRes qw(sleep time);

my @time;

FORK_ab:


ab:
my $pn = (procname())[1];

a:
	print "1..3\n";
	sleep(0.2);
	my $t = time;
a:
	sleep(0.1);
b:
	print "1..1\n";
	my $t = time;
	sleep(0.1);
a:
	lockcommon();
	setcommon({ a => $t});
	unlockcommon();
b:
	lockcommon();
	my $x = getcommon();
	$x->{b} = $t;
	setcommon($x);
	unlockcommon();
a:
	my $x = getcommon();
	print $x->{a} ? "ok 1\n" : "not ok 1\n";
	print $x->{b} ? "ok 2\n" : "not ok 2\n";
	print $x->{b} > $x->{a} ? "ok 3\n" : "not ok 3\n";
b:
	print "ok 1\n";

