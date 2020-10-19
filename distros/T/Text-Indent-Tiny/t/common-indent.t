#!perl -T
use 5.004;
use strict;
use warnings;
use Test::More;

use lib "t/lib";

# =========================================================================

plan tests => 3;

use Text::Indent::Tiny (
	size	=> 1,
);

note "Instantiate the global indent";
my $indent = Text::Indent::Tiny->instance;

note "Set global indent to level 3";
$indent->over(3);

ok "$indent" eq " " x 3, "Indent in main equals 3 spaces";

note "Foo increases the global indent by 1 space locally";
use Foo;
ok(Foo->me() eq " " x 4 . "Foo", "Indent in Foo was locally increased by 1 space");

note "Bar decreases the global indent by 1 space locally";
use Bar;
ok(Bar->me() eq " " x 2 . "Bar", "Indent in Bar was locally decreased by 1 space");

# =========================================================================

# EOF
