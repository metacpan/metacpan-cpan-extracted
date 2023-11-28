use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Unicode::Block::Ascii;

# Test.
my $obj = Unicode::Block::Ascii->new(
	'title' => 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz',
);
eval {
	$obj->get;
};
is($EVAL_ERROR, "Long title.\n", 'Long title.');
clean();
