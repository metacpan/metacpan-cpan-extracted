package uni::perl::utf;

use uni::perl ();
use uni::perl::encodebase;
m{
use strict;
use warnings;
}x;

our $LOADED;
sub load  {
	$LOADED++ and return;
	uni::perl::encodebase::generate(['utf','utf8']);
	return;
}

1;
