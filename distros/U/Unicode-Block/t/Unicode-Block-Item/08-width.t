use strict;
use warnings;

use English;
use POSIX qw(LC_ALL setlocale);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Unicode::Block::Item;

# Test.
setlocale(LC_ALL, 'en_US.UTF-8');
my $obj = Unicode::Block::Item->new(
	'hex' => '0a',
);
my $ret = $obj->width;
is($ret, '1', "Get width for '0a'.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '3111',
);
$ret = $obj->width;
is($ret, '2', "Get width for '3111'.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '1018f',
);
$ret = $obj->width;
is($ret, 0, "Get width for '1018f', which is unasigned.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '0488',
);
$ret = $obj->width;
is($ret, 1, "Get width for '0488', which is \'Enclosing Mark\'.");

# Test.
$obj = Unicode::Block::Item->new(
	'hex' => '0300',
);
$ret = $obj->width;
is($ret, 1, "Get width for '0300', which is \'Non-Spacing Mark\'.");

# Test.
SKIP: {
	if ($PERL_VERSION lt v5.14.0) {
		skip 'Perl version lesser then 5.14.0 has not Brahmi Unicode block.', 1;
	}

	$obj = Unicode::Block::Item->new(
		'hex' => '1106d',
	);
	$ret = $obj->width;
	is($ret, 1, "Get width for '1106d'.");
};

# Test.
$ret = $obj->width;
is($ret, 1, "Get width for '1106d' again.");
