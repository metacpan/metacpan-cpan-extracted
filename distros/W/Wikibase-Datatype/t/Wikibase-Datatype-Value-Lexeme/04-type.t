use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Value::Lexeme->new(
	'value' => 'L42284',
);
my $ret = $obj->type;
is($ret, 'lexeme', 'Get type().');
