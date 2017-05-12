#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::NoWarnings;

{
    package Parent;

    sub foo { "Parent"; }
}

{
    package Middle;
    use mixin::with "Parent";

    sub foo {
        my $self = shift;
        return $self->SUPER::foo(), "Middle";
    }
}

{
    package Child;
    use base qw(Parent);
    use mixin "Middle";

    sub foo {
        my $self = shift;
        return $self->SUPER::foo(), "Child";
    }
}

is_deeply [Child->foo], [qw(Parent Middle Child)];

ok( Child->isa("Parent") );
ok( !Child->isa("Middle") );
