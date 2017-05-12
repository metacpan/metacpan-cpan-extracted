#!perl -w
use strict;

use Benchmark qw(:all);


sub add{ $_[0] + $_[1] }

use macro::filter add => \&add;

printf "macro/%s\n", macro->VERSION;

my $n = 1000;
cmpthese timethese -1 => {
	macro => sub{
		my $sum = 0;
		for my $i (1 .. $n){
			$sum = add($sum, $i);
		}
	},
	sub => sub{
		my $sum = 0;
		for my $i (1 .. $n){
			$sum = &add($sum, $i);
		}
	},
	do => sub{
		my $sum = 0;
		for my $i (1 .. $n){
			$sum = do{ $sum + $i };
		}
	},
	eval => sub{
		my $sum = 0;
		for my $i (1 .. $n){
			$sum = eval{ $sum + $i };
		}
	},
};
