#!/usr/bin/env perl -w

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { require_ok( 'XML::Catalogs' ); }

diag( "Testing XML::Catalogs $XML::Catalogs::VERSION" );
diag( "Using Perl $]" );
