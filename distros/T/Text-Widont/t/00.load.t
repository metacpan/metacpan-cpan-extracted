#!perl -wT

use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Text::Widont' );

my $tw = Text::Widont->new;
isa_ok( $tw, 'Text::Widont' );

diag( "Testing Text::Widont $Text::Widont::VERSION" );
