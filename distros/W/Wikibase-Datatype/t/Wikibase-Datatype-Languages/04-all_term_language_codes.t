use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Languages qw(all_term_language_codes);

# Test.
my @ret = all_term_language_codes();
is(scalar @ret, 613, 'Get term language codes count (613).');
