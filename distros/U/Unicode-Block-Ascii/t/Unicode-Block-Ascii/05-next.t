use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::Block::Ascii;

# Test.
my $obj = Unicode::Block::Ascii->new(
	'char_from' => '0061',
	'char_to' => '0061',
);
my $ret = $obj->next;
isa_ok($ret, 'Unicode::Block::Item');
is($ret->char, 'a', "Get unicode character for '0061'.");

# Test.
$ret = $obj->next;
is($ret, undef, 'No other character.');
