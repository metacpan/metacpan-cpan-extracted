# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use strict;
use vars qw($loaded %hash $hashctl);
BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::StrictHash;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

##==============================================================================
## Tests:
##	1.	Load the module (above)
##	2.	Create a strict hash with three members.
##	3.	Access all three members.
##	4.	Modify all three members.
##	5.	Access a member that doesn't exist (should fail)
##	6.	Modify a member that doesn't exist (should fail)
##	7.	Delete a member (should fail)
##	8.	Add a member via 'add'
##	9.	Access the added member.
## 10.	Modify the added member.
## 11.	Delete the added member (should fail).
## 12.	Delete the added member using 'delete'.
## 13.	Clear the hash (should fail)
## 14.	Clear the hash using 'clear'.
##==============================================================================

sub failbad ($$) {
	my ($msg, $test) = @_;
	print $msg;
	print(($msg ? "not ok " : "ok "), $test, "\n");
}

sub failgood ($$) {
	my ($msg, $test) = @_;
	print(($msg ? "ok " : "not ok "), $test, "\n");
}

eval {
	$hashctl = strict_hash %hash, member1 => 'a', member2 => 'b', member3 => 'c';
};
failbad $@, 2;

eval {
	my $x = $hash{member1}; $x = $hash{member2}; $x = $hash{member3};
	my @x = @hash{qw(member1 member2 member3)};
};
failbad $@, 3;

eval {
	$hash{member1} = 'A';
	$hash{member2} = 'B';
	$hash{member3} = 'C';
};
failbad $@, 4;

eval {
	my $x = $hash{member4};
};
failgood $@, 5;

eval {
	$hash{member4} = 'd';
};
failgood $@, 6;

eval {
	delete $hash{member1};
};
failgood $@, 7;

eval {
	$hashctl->add(member4 => 'd');
};
failbad $@, 8;

eval {
	my $x = $hash{member4};
};
failbad $@, 9;

eval {
	$hash{member4} = 'D';
};
failbad $@, 10;

eval {
	delete $hash{member4};
};
failgood $@, 11;

eval {
	$hashctl->delete('member4');
};
failbad $@, 12;

eval {
	%hash = ();
};
failgood $@, 13;

eval {
	$hashctl->clear;
};
failbad $@, 14;
