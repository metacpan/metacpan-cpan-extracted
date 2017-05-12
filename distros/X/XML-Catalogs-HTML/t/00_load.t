#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { require_ok( 'XML::Catalogs::HTML' ); }

diag( "Testing XML::Catalogs::HTML $XML::Catalogs::HTML::VERSION" );
diag( "Using Perl $]" );
