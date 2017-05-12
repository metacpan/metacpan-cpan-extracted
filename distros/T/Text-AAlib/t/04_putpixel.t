use strict;
use warnings;
use Test::More;

use Text::AAlib;

my $aa = Text::AAlib->new(
    width  => 100,
    height => 200,
);

can_ok $aa, "putpixel";

my @PARAMS = qw/x y color/;
for my $param (@PARAMS) {
    my %args = map { $_ => 1 } grep { $_ ne $param } @PARAMS;
    eval {
        $aa->putpixel(%args);
    };
    like $@, qr/missing mandatory parameter/, "missing '$param' parameter";
}

for my $param (@PARAMS) {
    my %args = map { $_ => 1 } grep { $_ ne $param } @PARAMS;
    $args{$param} = 'aaa';
    eval {
        $aa->putpixel(%args);
    };
    like $@, qr/should be number/, "invalid '$param', not a number";
}

eval {
    $aa->putpixel(
        x => 100, y => 1, color => 10,
    );
};
like $@, qr/'x' param should be/, "invalid 'x' param(>= width)";

eval {
    $aa->putpixel(
        x => -1, y => 1, color => 10,
    );
};
like $@, qr/'x' param should be/, "invalid 'x' param(< 0)";

eval {
    $aa->putpixel(
        x => 1, y => 200, color => 10,
    );
};
like $@, qr/'y' param should be/, "invalid 'y' param(>= height)";

eval {
    $aa->putpixel(
        x => 0, y => -1, color => 10,
    );
};
like $@, qr/'y' param should be/, "invalid 'y' param(< 0)";

eval {
    $aa->putpixel(
        x => 1, y => 1, color => 256,
    );
};
like $@, qr/'color' parameter should be/, "invalid 'color' param(>= 255)";

eval {
    $aa->putpixel(
        x => 0, y => 0, color => -1,
    );
};
like $@, qr/'color' parameter should be/, "invalid 'color' param(< 0)";

done_testing;
