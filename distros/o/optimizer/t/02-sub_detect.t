# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
my $i;
BEGIN { $i = 1 };
use Test;
BEGIN { plan tests => 5 };


ok($i++); # If we made it this far, we're ok.
use B;
use optimizer 'sub-detect' => sub { 
	my $op = shift;
#	print $op->name() . ":" . $op->desc() . "\n";
	ok($i++);
};

sub hi {

}

eval 'ok("should be last")';


