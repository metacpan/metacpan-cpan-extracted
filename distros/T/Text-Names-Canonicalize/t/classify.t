use strict;
use warnings;
use utf8;
use Test::Most;

use_ok('Text::Names::Canonicalize');

my $canon = \&Text::Names::Canonicalize::canonicalize_name;
my $tok   = \&Text::Names::Canonicalize::_tokenize;
my $class = \&Text::Names::Canonicalize::_classify_tokens;

sub classify {
	my $s = $_[0];
	my $norm = $canon->($s, strip_diacritics => 1);
	my $tokens = $tok->($norm);
	return $class->($tokens);
}

# 1. Initials
is_deeply classify("J. R. R. Tolkien")->{types},
	[qw(initial initial initial word)],
	"initials classified";

# 2. Suffix
is_deeply classify("John R Smith Jr")->{types},
	[qw(word initial word suffix)],
	"suffix classified";

# 3. No initials
is_deeply classify("Mary Anne Smith")->{types},
	[qw(word word word)],
	"simple words classified";

done_testing;
