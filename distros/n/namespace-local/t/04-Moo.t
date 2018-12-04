#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    if (!eval { require Moo; 1 }) {
        warn "WARNING: $@" unless $@ =~ /Can't locate Moo.pm/;
        plan skip_all => "No Moo found";
        exit 0;
    };
};

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

lives_ok {
    package Foo;
    use Moo;

    with "Bar", "Baz";
} "no conflict in roles";

lives_ok {
my $foo = Foo->new;

is $foo->bar, 42, "role Bar propagated";
is $foo->baz, 137, "role Baz propagated";
is $foo->can("_private"), undef, "Private masked";
} "no expection in usage";
done_testing;
