use Test::More;
use UNIVERSAL::filename;

use lib qw(t/lib);
use Foo;
use Foo::Bar;

is (
    Foo->filename,
    "t/lib/Foo.pm",
    "Foo is t/lib/Foo.pm",
);

is (
    Foo::Bar->filename,
    "t/lib/Foo/Bar.pm",
    "Foo::Bar is t/lib/Foo/Bar.pm",
);

is (
    Baz->filename,
    undef,
    "Baz didn't index filename in \%INC",
);

done_testing;
