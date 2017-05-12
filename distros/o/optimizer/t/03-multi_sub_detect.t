# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
my $i;
BEGIN { $i = 1; print "1..14\n" };
sub ok { print "ok $_[0]\n"; }



ok($i++); # If we made it this far, we're ok.
use B;
use optimizer 'sub-detect' => sub { 
	my $op = shift;
	ok($i++);
};

package test;
use optimizer 'sub-detect' => sub { 
	my $op = shift;
	main::ok($i++);
};

sub hi {

}

eval 'main::ok(10);$i++';


eval 'main::ok(13);$i++';
main::ok(14);