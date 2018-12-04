#!perl

use 5.010;
use strictures;

{
    package Bar;
    use Moo::Role;

    sub bar {
        return _private(@_);
    };

    # comment this line out to get kaboom
    use namespace::local -below;
    sub _private {
        return 42;
    };
};

{
    package Baz;
    use Moo::Role;

    sub baz {
        return _private(@_);
    };

    # comment this line out to get kaboom
    use namespace::local -below;
    sub _private {
        return 137;
    };
};

{
    package Foo;
    use Moo;

    with "Bar", "Baz";
};

my $foo = Foo->new;

say $foo->bar;
say $foo->baz;
