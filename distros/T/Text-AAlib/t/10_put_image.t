use strict;
use warnings;

use Test::More;
use Text::AAlib;

eval q{ use Imager; };
plan skip_all => "Imager is not installed" if $@;

my $aa = Text::AAlib->new(
    width  => 100,
    height => 100,
);

can_ok $aa, "put_image";

eval {
    $aa->put_image;
};
like $@, qr/missing mandatory parameter/, "missing 'image' parameter";

eval {
    $aa->put_image(image => 10);
};
like $@, qr/should be is-a Imager/, "invalid 'image' parameter";

eval {
    $aa->put_image(image => Imager->new(), x => 101, y => 100);
};
ok $@, "invalid 'x' parameter";

eval {
    $aa->put_image(image => Imager->new(), x => 100, y => 101);
};
ok $@, "invalid 'y' parameter";

done_testing;
