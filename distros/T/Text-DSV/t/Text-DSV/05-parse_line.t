use strict;
use warnings;

use Text::DSV;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Text::DSV->new;
my @ret = $obj->parse_line('1:2:3');
is_deeply(
	\@ret,
	[1, 2, 3],
	'Parse line data',
);

# Test.
@ret = $obj->parse_line('1:text\:text');
is_deeply(
	\@ret,
	[1, 'text:text'],
	'Parse line data with \':\'.',
);

# Test.
@ret = $obj->parse_line('1:text\:text\:text');
is_deeply(
	\@ret,
	[1, 'text:text:text'],
	'Parse line data with multiple \':\'.',
);

# Test.
@ret = $obj->parse_line('1:text\ntext');
is_deeply(
	\@ret,
	[1, "text\ntext"],
	'Parse line data with newline.',
);

# Test.
@ret = $obj->parse_line('1:text\ntext\ntext');
is_deeply(
	\@ret,
	[1, "text\ntext\ntext"],
	'Parse line data with multiple newline.',
);

# Test.
@ret = $obj->parse_line('1:text\ntext\:text');
is_deeply(
	\@ret,
	[1, "text\ntext:text"],
	'Parse line data with \':\' and newline.',
);
