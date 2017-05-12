use strict;
use warnings;
use Test::More;

use Text::AAlib;

my $aa = Text::AAlib->new(
    width  => 100,
    height => 100,
);

can_ok $aa, "putpixel";

eval {
    $aa->putpixel(
        y     => 10,
        color => 0.3,
    );
};
like $@, qr/missing mandatory parameter/, "missing 'x' parameter";

eval {
    $aa->putpixel(
        x     => 0,
        color => 0.3,
    );
};
like $@, qr/missing mandatory parameter/, "missing 'y' parameter";

eval {
    $aa->putpixel(
        x => 10,
        y => 10,
    );
};
like $@, qr/missing mandatory parameter/, "missing 'color' parameter";

done_testing;
