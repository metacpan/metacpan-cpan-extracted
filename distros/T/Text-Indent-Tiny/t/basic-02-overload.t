#!perl -T
use 5.004;
use strict;
use warnings;
use Test::More;

# =========================================================================

my $spaces = "    ";

my $header = "Poem";

my @poem = (
	"To be or not to be",
	"That is the question",
);

my $author = "William Shakespeare";

# =========================================================================

plan tests => 5;

use_ok 'Text::Indent::Tiny';
my $indent = Text::Indent::Tiny->new;

$\ = "\n";

note "Start with indent level 0";
ok $indent . $header eq $header, "No indent for $header";

note "Indent each line with 4 spaces (by default)";
foreach ( @poem ) {
	ok $indent + 1 . $_ eq $spaces x 1 . $_, "1st level (4 spaces) for $_";
}

note "Indent the particular line locally to 5th level (with 5 spaces)";
ok $indent + 5 . $author eq $spaces x 5 . $author, "5th level (20 spaces) for $author";

# =========================================================================

# EOF
