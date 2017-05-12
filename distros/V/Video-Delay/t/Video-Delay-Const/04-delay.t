# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Video::Delay::Const;

# Test.
my $obj = Video::Delay::Const->new(
	'const' => 10
);
my $ret = $obj->delay;
is($ret, 10, 'First item.');
$ret = $obj->delay;
is($ret, 10, 'Second item.');
