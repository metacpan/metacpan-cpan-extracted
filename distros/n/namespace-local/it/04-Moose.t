#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    if (!eval { require Moose; 1 }) {
        warn "WARNING: $@" unless $@ =~ /Can't locate Moose.pm/;
        plan skip_all => "No Moose found";
        exit 0;
    };
};

BEGIN {
    package My::Base;
    use Moose;
    use namespace::local -above;
    has foo => is => "rw";
    sub public {
        return private();
    };
    use namespace::local -below;
    sub private {
        return 42;
    };
};

BEGIN {
    package My::Child;
    use Moose;
    extends "My::Base";
};

my $obj = My::Child->new( foo => 137 );

isa_ok $obj, "My::Base", "base class applied";
is $obj->foo, 137, "Moose parameter propagates";
is $obj->public, 42, "public method inherited";
is $obj->can("private"), undef, "private not avail";

done_testing;
