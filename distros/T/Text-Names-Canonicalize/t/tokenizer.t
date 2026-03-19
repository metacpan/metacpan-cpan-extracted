use strict;
use warnings;
use utf8;
use Test::Most;

use_ok('Text::Names::Canonicalize');

my $canon = \&Text::Names::Canonicalize::canonicalize_name;
my $tok   = \&Text::Names::Canonicalize::_tokenize;

sub tokens {
	my ($s) = @_;
	my $norm = $canon->($s, strip_diacritics => 1);
	return $tok->($norm);
}

is_deeply tokens("J. R. R. Tolkien"),
	[qw(j r r tolkien)],
	"initials tokenized";

is_deeply tokens("Mary-Anne Smith-Jones"),
	["mary-anne", "smith-jones"],
	"hyphens preserved";

is_deeply tokens("O’Connor"),
	["o'connor"],
	"curly apostrophe normalized";

is_deeply tokens("Jean‑Luc Picard"),
	["jean-luc", "picard"],
	"non-breaking hyphen normalized";

done_testing;
