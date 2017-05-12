#!perl -w

use strict;
use constant HAS_THREADS => eval{ require threads };

use Test::More;

BEGIN{
	if(HAS_THREADS){
		plan tests => 6;
	}
	else{
		plan skip_all => 'require threads';
	}
}

use threads;
use Test::LeakTrace;

leaks_cmp_ok{
	async{
		my $a = 0;
		$a++;
	}->join;
} '<', 10;

my $count = leaked_count {
	async{
		leaks_cmp_ok{
			my @a;
			push @a, \@a;
		} '>', 0;

		no_leaks_ok{
			my $a;
			$a++;
		};
	}->join;
};
cmp_ok $count, '<', 10, "(actually leaked: $count)";

async{
	no_leaks_ok{
		my $a = 0;
		$a++;
	};
	no_leaks_ok{
		my $a = 0;
		$a++;
	};
}->join();

