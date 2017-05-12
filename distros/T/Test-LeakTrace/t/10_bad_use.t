#!perl -w

use strict;
use Test::More tests => 6;

use Test::LeakTrace;

for(1 .. 2){
	eval{
		my @a = leaked_refs{
			my @b = leaked_refs{
				my %a = (foo => 42);
				my %b = (bar => 3.14);

				$b{a} = \%a;
				$a{b} = \%b;
			};
		};
	};
	isnt $@, '', 'multi leaktrace';

	eval{
		leaktrace{
			my %a = (foo => 42);
			my %b = (bar => 3.14);

			$b{a} = \%a;
			$a{b} = \%b;
		} sub {
			die ['foo'];
		};
	};
	is_deeply $@, ['foo'], 'die in callback';

	eval{
		leaktrace{
			my @array;
			push @array, \@array;
		} -foobar;
	};
	like $@, qr/Invalid reporting mode/, 'invalid mode';
}
