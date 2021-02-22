use strict;
use warnings;

use Test::More;

eval 'use Text::BibTeX';
plan skip_all => 'Text::BibTeX required' if $@;

use File::Temp;
use Text::BibTeX::Validate qw( validate_BibTeX );

plan tests => 2;

my $tmp = File::Temp->new();
my $fh;
open( $fh, '>', $tmp->filename );
print $fh <<'END';
@Article{Merkys2016,
  author    = {Merkys, Andrius and Vaitkus, Antanas and Butkus, Justas and Okuli{\v{c}}-Kazarinas, Mykolas and Kairys, Visvaldas and Gra{\v{z}}ulis, Saulius},
  journal   = {Journal of Applied Crystallography},
  title     = {{\it COD::CIF::Parser}: an error-correcting {CIF} parser for the {P}erl language},
  year      = {2016},
  month     = {Feb},
  number    = {1},
  pages     = {292--301},
  volume    = {49},
  doi       = {10.1107/S1600576715022396},
  url       = {http://dx.doi.org/10.1107/S1600576715022396},
}
END
close $fh;

my $bibfile = Text::BibTeX::File->new( $tmp->filename );
my $entry = Text::BibTeX::Entry->new( $bibfile );
my $warning;

( $warning ) = validate_BibTeX( $entry );
is( $warning, undef );

$entry->set( 'doi', 'doi/10.1107/S1600576715022396' );
( $warning ) = validate_BibTeX( $entry );
is( "$warning",
    'doi: value \'doi/10.1107/S1600576715022396\' does not look like valid DOI' );
