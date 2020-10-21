#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin";

use Text::Indent::Tiny;
my $indent = Text::Indent::Tiny->new(
	eol	=> 1,
	size	=> 1,
	level	=> 2,
);

print $indent     . "| after init";
$indent += 3;
print $indent     . "| after over";
print $indent + 1 . "> over locally";
print $indent     . "| next text";
print $indent - 1 . "< back locally";
print $indent     . "| next text";
$indent -= $indent;
#$indent->cut;
print $indent     . "| after reset";
