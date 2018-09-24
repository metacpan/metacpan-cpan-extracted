#!perl
use strict;
use warnings;
 
use Test::More tests => 9;
 
use lib 'lib';
use Text::CSV::Piecemeal;
use Data::Dumper;
 
my $csv = Text::CSV::Piecemeal->new( { sep_char => ',' } );
 
ok( $Text::CSV::Piecemeal::VERSION,		'Loading Text::CSV::Piecemeal' );
ok( defined($csv), 				'Object creation' );
ok( $csv->push_row( qw(Col1 Col2 Col3) ),	'Push row' );
ok( $csv->push_row( qw(a b c ) ),		'Push row' );
ok( $csv->push_value( "a,a" ), 			'Push vaulue' );
ok( $csv->push_partial_value( "a" ),		'Push partial value1');
ok( $csv->push_partial_value( " a" ),		'Push partial value2');
ok( $csv->push_value( 'a"' ),			'Push value');

my $desired = qq(Col1,Col2,Col3\na,b,c\n"a,a","a a","a"""\n);

ok( $csv->output eq $desired, 'Output valid');
