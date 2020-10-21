#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin";

use Text::Indent::Tiny;
my $indent = Text::Indent::Tiny->new;

# Let's use newline per each item
$\ = "\n";

# No indent
print $indent . "Poem begins";

# Indent each line with 4 spaces (by default)
print $indent + 1 . [
	"To be or not to be",
	"That is the question",
];

# Indent the particular line locally to 5th level (with 20 spaces)
print $indent + 5 . "William Shakespeare";

# No indent
print $indent . "Poem ends";
