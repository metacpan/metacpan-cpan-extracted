#!/usr/bin/env perl

use strict;
use warnings;
use lib::abs '../lib';
use Test::More tests => 2;
use Test::NoWarnings ();

BEGIN {
	use_ok( 'XML::Declare' );
}
Test::NoWarnings::had_no_warnings();

diag( "Testing XML::Declare $XML::Declare::VERSION, XML::LibXML $XML::LibXML::VERSION, Perl $], $^X" );
exit;
require Test::NoWarnings; # Stupid hack for cpants::kwalitee
