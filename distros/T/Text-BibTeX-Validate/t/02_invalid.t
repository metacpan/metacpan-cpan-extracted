use strict;
use warnings;

use Test::More;
use Text::BibTeX::Validate qw( clean_BibTeX validate_BibTeX );

my @cases = (
    [ { doi => 'not a DOI' },
      'doi: value \'not a DOI\' does not look like valid DOI' ],
    [ { doi => 'http://doi.org/10.1234/567890' },
      'doi: value \'http://doi.org/10.1234/567890\' is better written as \'10.1234/567890\'',
      { doi => '10.1234/567890' } ],
    [ { isbn => '0-306-40615-2' }, undef ],
    [ { isbn => '0-306-40615-X' },
      'isbn: value \'0-306-40615-X\' does not look like valid ISBN' ],
    [ { month => '02' },
      'month: value \'02\' is better written as \'Feb\'',
      { month => 'Feb' } ],
    [ { month => 'August' },
      'month: value \'August\' is better written as \'Aug\'',
      { month => 'Aug' } ],
    [ { month => 'may' }, undef ],
    [ { pmid => 'PMC1234567' },
      'pmid: PMCID \'PMC1234567\' is provided instead of PMID' ],
    [ { url => "https://example.com\n" },
      'url: URL has trailing newline character',
      { url => 'https://example.com' } ],
);

plan tests => 3 * scalar @cases;

for my $case (@cases) {
    my @warnings = validate_BibTeX( $case->[0] );
    my $clean = clean_BibTeX( $case->[0] );

    is( scalar @warnings, defined $case->[1] ? 1 : 0 );
    is( @warnings ? "$warnings[0]" : undef, $case->[1] );
    is_deeply( $clean, @$case == 3 ? $case->[2] : $case->[0] );
}
