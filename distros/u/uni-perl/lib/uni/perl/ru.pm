package uni::perl::ru;

use uni::perl;
use uni::perl::encodebase;
m{
use strict;
use warnings;
}x;

our $LOADED;
sub load {
	$LOADED++ and return;
	uni::perl::encodebase::generate(qw(cp1251 koi8r cp866));
	return;
}

1;
