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
print $indent->item("Poem begins");

# Indent each line with 4 spaces (by default)
$indent->over;
print $indent->item(
	"To be or not to be",
	"That is the question",
);
$indent->back;

# Indent the particular line locally to 5th level (with 20 spaces)
print $indent->over(5)->item("William Shakespeare");

# No indent
print $indent->item("Poem ends");
