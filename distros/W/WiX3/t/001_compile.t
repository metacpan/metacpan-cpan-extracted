use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Test::UseAllModules;

# XML::WiX3::Classes::StrictConstructor needs to be used within 
# a Moose class in order to work right.
# We'll test it later.
all_uses_ok(except => qw(WiX3::Util::StrictConstructor));

END {
	diag( "Testing WiX3 $WiX3::VERSION" );
}