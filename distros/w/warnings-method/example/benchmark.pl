#perl -w

use strict;
use Benchmark qw(:all);

sub f{}

my $src = 'return;' . join ';', ('f()') x 100;

print "For compiling with warnings::method/$warnings::method::VERSION\n";
cmpthese timethese 0 => {
	'use warnings::method' => sub{
		use warnings::method;
		eval $src;
		die $@ if $@;
	},
	'no  warnings::method' => sub{
		no  warnings::method;
		eval $src;
		die $@ if $@;
	},
};
