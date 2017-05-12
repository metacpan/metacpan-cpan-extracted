use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

{
	package Test;
	use Moose 2.00;
	use Test::More tests => 1;

	# WiX3::Util::StrictConstructor needs to be used within 
	# a Moose class in order to work right.
	use_ok('WiX3::Util::StrictConstructor');
}

1;