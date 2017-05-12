#!/usr/bin/perl -w

use Test::More 'no_plan';

use Treemap;

my ( $input, $output ) = ( 1, 1 );
my $treemap = Treemap->new( INPUT=>$input, OUTPUT=>$output );

ok( defined $treemap, 'Treemap->new returned something' );
ok( $treemap->isa( 'Treemap' ), '  and it is the correct class' );
#is( $treemap->rect( (1,2) ), 2, '  rect returned correctly' );	# Why did I think this would return 2?
#is( $treemap->text( (1,2) ), 2, '  text returned correctly' );	# Why did I think this would return 2?

