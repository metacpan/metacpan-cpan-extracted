use warnings;
use strict;

## be sure eol settings are honor in header parsing.
## created in response to:
## https://rt.cpan.org/Public/Bug/Display.html?id=74506

use Test::More tests => 4;

use Text::xSV::Slurp;

my $text = join "\015\012", 'a,b', '1,2', '';

my $got_aoa = xsv_slurp( shape => 'aoa', string => $text, text_csv => { eol => "\015\012" } );
my $exp_aoa = [ ['a','b'], ['1','2'] ];

is_deeply( $got_aoa, $exp_aoa, 'aoa' );

my $got_aoh = xsv_slurp( shape => 'aoh', string => $text, text_csv => { eol => "\015\012" } );
my $exp_aoh = [ { a => 1, b => 2 } ];

is_deeply( $got_aoh, $exp_aoh, 'aoh' );

my $got_hoa = xsv_slurp( shape => 'hoa', string => $text, text_csv => { eol => "\015\012" } );
my $exp_hoa = { a => [1], b => [2] };

is_deeply( $got_hoa, $exp_hoa, 'hoa' );

my $got_hoh = xsv_slurp( shape => 'hoh', key => 'a', string => $text, text_csv => { eol => "\015\012" } );
my $exp_hoh = { 1 => { b => '2' } };

is_deeply( $got_hoh, $exp_hoh, 'hoh' );