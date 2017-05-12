#!perl -w

use strict;
use Benchmark qw(:all);

use WeakRef::Auto;
use Scalar::Util qw(weaken);

my $weakref;
my $normal;

autoweaken my $autoweak;

my $ref = [42];

print "Create:\n";
cmpthese timethese -1 => {
	weakref => sub{
		for(1 .. 100){
			$weakref = $ref;
			weaken $weakref;
		}
	},
	autoweak => sub{
		for(1 .. 100){
			$autoweak = $ref;
		}
	},
	strongref => sub{
		for(1 .. 100){
			$normal = $ref;
		}
	},
};

print "\nCreate and destroy:\n";
cmpthese timethese -1 => {
	weakref => sub{
		for(1 .. 100){
			$weakref = [42];
			weaken $weakref;
		}
	},
	autoweak => sub{
		for(1 .. 100){
			$autoweak = [42];
		}
	},
	strongref => sub{
		for(1 .. 100){
			$normal = [42];
		}
	},
};
