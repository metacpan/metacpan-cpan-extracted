use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Term;

# Test.
my $obj = Wikibase::Datatype::Term->new(
	'value' => 'Example',
);
my $ret = $obj->value;
is($ret, 'Example', 'Get value().');

# Test.
$obj = Wikibase::Datatype::Term->new(
	'value' => decode_utf8('čeština'),
);
$ret = $obj->value;
is($ret, decode_utf8('čeština'), 'Get value() with unicode.');
