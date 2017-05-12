# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use blib;
use Devel::Peek;

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}
use WeakRef;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$cnt = 1;

sub ok {
	++$cnt;
	if($_[0]) { print "ok $cnt\n"; } else {print "not ok $cnt\n"; }
}

$| = 1;

if(1) {

my ($y,$z);

#
# Case 1: two references, one is weakened, the other is then undef'ed.
#

{
	my $x = "foo";
	$y = \$x;
	$z = \$x;
}
print "START:";
Dump($y); Dump($z);

ok( $y ne "" and $z ne "" );
weaken($y);

print "WEAK:";
Dump($y); Dump($z);

ok( $y ne "" and $z ne "" );
undef($z);

print "UNDZ:";
Dump($y); Dump($z);

ok( $y eq "" and $z eq "" );
undef($y);

print "UNDY:";
Dump($y); Dump($z);

ok( $y eq "" and $z eq "" );

print "FIN:";
Dump($y); Dump($z);

# exit(0);

# }
# {

# 
# Case 2: one reference, which is weakened
#

# kill 5,$$;

print "CASE 2:\n";

{
	my $x = "foo";
	$y = \$x;
}

ok( $y ne "" );
print "BW: \n";
Dump($y);
weaken($y);
print "AW: \n";
Dump($y);
ok( $y eq "" );

print "EXITBLOCK\n";
}

# exit(0);

# 
# Case 3: a circular structure
#

# kill 5, $$;

$flag = 0;
{
	my $y = bless {}, Dest;
	Dump($y);
	print "1: $y\n";
	$y->{Self} = $y;
	Dump($y);
	print "2: $y\n";
	$y->{Flag} = \$flag;
	print "3: $y\n";
	weaken($y->{Self});
	print "WKED\n";
	ok( $y ne "" );
	print "VALS: HASH ",$y,"   SELF ",\$y->{Self},"  Y ",\$y, 
		"    FLAG: ",\$y->{Flag},"\n";
	print "VPRINT\n";
}
print "OUT $flag\n";
ok( $flag == 1 );

print "AFTER\n";

undef $flag;

print "FLAGU\n";

#
# Case 4: a more complicated circular structure
#

$flag = 0;
{
	my $y = bless {}, Dest;
	my $x = bless {}, Dest;
	$x->{Ref} = $y;
	$y->{Ref} = $x;
	$x->{Flag} = \$flag;
	$y->{Flag} = \$flag;
	weaken($x->{Ref});
}
ok( $flag == 2 );

#
# Case 5: deleting a weakref before the other one
#

{
	my $x = "foo";
	$y = \$x;
	$z = \$x;
}

print "CASE5\n";
Dump($y);

weaken($y);
Dump($y);
undef($y);

ok($y eq "");
ok($z ne "");


#
# Case 6: test isweakref
#

$a = 5;
ok(!isweak($a));
$b = \$a;
ok(!isweak($b));
weaken($b);
ok(isweak($b));
$b = \$a;
ok(!isweak($b));

$x = {};
weaken($x->{Y} = \$a);
ok(isweak($x->{Y}));
ok(!isweak($x->{Z}));


package Dest;

sub DESTROY {
	print "INCFLAG\n";
	${$_[0]{Flag}} ++;
}
