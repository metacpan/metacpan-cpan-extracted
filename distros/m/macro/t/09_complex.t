#!perl -w
use strict;
use Test::More tests => 6;

use macro::filter
	zero  => sub{ do{ $_ = 0 } while $_ },
	one   => sub{ ++(my $var) },
	two   => sub{ my $var = $_ for 2 },
	three => sub{ {3} },
	four  => sub{ +{ four => 4 } },
	five  => sub{ local $_ = 5 },
;

is zero(),  0;
is one(),   1;
is two(),   '';
is three(), 3;
is four()->{four}, 4;
is five(),  5;
