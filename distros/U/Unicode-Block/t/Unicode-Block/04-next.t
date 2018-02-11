use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::Block;

# Test.
my $obj = Unicode::Block->new(
	'char_from' => '0061',
	'char_to' => '0061',
);
my $ret = $obj->next;
isa_ok($ret, 'Unicode::Block::Item');
is($ret->char, 'a', "Get unicode character for '0061'.");

# Test.
$ret = $obj->next;
is($ret, undef, 'No other character.');
