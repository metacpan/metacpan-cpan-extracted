use strict;
use warnings;

use Test::More;
use Text::BibTeX::Validate qw( validate_BibTeX );

my @cases = (
    [ { doi => 'not a DOI' },
      'doi: value \'not a DOI\' does not look like valid DOI' ],
    [ { doi => 'http://doi.org/10.1234/567890' },
      'doi: value \'http://doi.org/10.1234/567890\' is better written as \'10.1234/567890\'' ],
    [ { isbn => '0-306-40615-2' }, undef ],
    [ { isbn => '0-306-40615-X' },
      'isbn: value \'0-306-40615-X\' does not look like valid ISBN' ],
);

plan tests => scalar @cases;

for my $case (@cases) {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    validate_BibTeX( $case->[0] );
    $warning =~ s/\n$// if $warning;
    is( $warning, $case->[1] );
}
