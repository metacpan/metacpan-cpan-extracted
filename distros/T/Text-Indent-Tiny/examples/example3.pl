#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use Text::Indent::Tiny (
	size	=> 2,
	eol	=> 1,
);

my $indent = Text::Indent::Tiny->instance;

print $indent->item("Start conversation...");

# All greetings coming from modules will be indented once
$indent->over;

# All our greetings will be indented twice
print $indent->over->item(__PACKAGE__ . ": Hello, World! I am going to start greetings.");

print $indent->back->item("Start greetings...");

use Foo;
print $indent->over->item(__PACKAGE__ . ": Hello, Foo!");
print Foo->greet;

use Bar;
print $indent->over->item(__PACKAGE__ . ": Hello, Bar!");
print Bar->greet;

$indent->cut;

print $indent->item("Finished...");
