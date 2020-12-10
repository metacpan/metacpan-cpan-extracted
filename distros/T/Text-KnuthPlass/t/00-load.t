#!perl -T
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::KnuthPlass' );
}

diag( "Testing Text::KnuthPlass $Text::KnuthPlass::VERSION, Perl $], $^X" );
