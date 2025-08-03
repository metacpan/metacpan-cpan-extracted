use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Languages qw(all_language_codes);

# Test.
my @ret = all_language_codes();
is(scalar @ret, 616, 'Get language codes count (616).');
