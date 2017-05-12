package indirect::Test0::Oooooo::Pppppppp;

use strict;
no indirect ":fatal";

use indirect::Test0::Fffff::Vvvvvvv
	z => 0,
	x => sub { },
	y => sub { };

use indirect::Test0::Fffff::Vvvvvvv
	t => [ xxxx => qw<xxxxxx xxxxxxx> ],
	x => sub { $_[0]->method };

1;
