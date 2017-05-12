#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 1;
use XML::LibXML;

BEGIN {
    use_ok( 'XML::NewsML_G2' );
}

diag( "Testing XML::NewsML_G2 $XML::NewsML_G2::VERSION" );
diag('libxml version ' . XML::LibXML::LIBXML_RUNTIME_VERSION);
