use strict;
use warnings;
use utf8;
use Test::Most;

use_ok 'Text::Names::Canonicalize';

my $canon = \&Text::Names::Canonicalize::canonicalize_name;
my $tok   = \&Text::Names::Canonicalize::_tokenize;
my $class = \&Text::Names::Canonicalize::_classify_tokens;
my $parts = \&Text::Names::Canonicalize::_extract_parts;

sub extract {
	my ($s) = @_;
	my $norm = $canon->($s, strip_diacritics => 1);
	my $tokens = $tok->($norm);
	my $classified = $class->($tokens);
	return $parts->($classified);
}

# 1. Simple two-part name
is_deeply extract("John Smith"),
	{
		given   => ["john"],
		middle  => [],
		surname => ["smith"],
		suffix  => [],
	},
	"simple name parts";

# 2. Middle name
is_deeply extract("Mary Anne Smith"),
	{
		given   => ["mary"],
		middle  => ["anne"],
		surname => ["smith"],
		suffix  => [],
	},
	"middle name extracted";

# 3. Initials + surname
is_deeply extract("J R R Tolkien"),
	{
		given   => ["j"],
		middle  => ["r","r"],
		surname => ["tolkien"],
		suffix  => [],
	},
	"initials handled";

# 4. Suffix
is_deeply extract("John R Smith Jr"),
	{
		given   => ["john"],
		middle  => ["r"],
		surname => ["smith"],
		suffix  => ["jr"],
	},
	"suffix extracted";

done_testing();
