use strict ;
use warnings ;
use Test ;
use Time::Out qw(timeout) ;


BEGIN {
	plan(tests => 3) ;
}


# exception
eval {
	timeout 3 => sub {
		die("allo\n") ;
	} ;
} ;
ok($@, "allo\n") ;


# exception
eval {
	timeout 3 => sub {
		die("allo") ;
	} ;
} ;
ok($@, qr/^allo/) ;


# exception
eval {
	timeout 3 => sub {
		die([56]) ;
	} ;
} ;
ok($@->[0], 56) ;



