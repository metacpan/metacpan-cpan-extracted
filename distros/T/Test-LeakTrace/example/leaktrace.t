#!perl -w
# a test script template

use strict;

use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 1) : (skip_all => 'require Test::LeakTrace');

use Test::LeakTrace;

use threads; # for example

leaks_cmp_ok{

	my $thr = async{
		my $i;
		$i++;
	};

	$thr->join();

} '<', 1;

