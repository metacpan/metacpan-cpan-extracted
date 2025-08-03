use strict;
use warnings;

use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Term;

# Test.
my $obj = Wikibase::Datatype::Term->new(
	'value' => 'Example',
);
my $ret = $obj->language;
is($ret, 'en', 'Get default language().');

# Test.
$obj = Wikibase::Datatype::Term->new(
	'language' => 'cs',
	'value' => decode_utf8('Příklad'),
);
$ret = $obj->language;
is($ret, 'cs', 'Get explicit language().');
