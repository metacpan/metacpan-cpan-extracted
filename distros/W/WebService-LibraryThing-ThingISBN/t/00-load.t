#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::LibraryThing::ThingISBN' );
}

diag( "Testing WebService::LibraryThing::ThingISBN $WebService::LibraryThing::ThingISBN::VERSION, Perl $], $^X" );
