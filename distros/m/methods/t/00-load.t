#!perl -T

# Test derived from Method::Signatures::Simple:
#   Copyright 2008 Rhesa Rozendaal, all rights reserved.
#   This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

use Test::More tests => 1;

BEGIN {
	use_ok( 'methods' );
}

Test::More::diag( "Testing methods $methods::VERSION, Perl $], $^X" );
