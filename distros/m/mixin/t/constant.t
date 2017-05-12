#!/usr/bin/perl -w

# 5.10.0 changed the way constants are represented in the symbol table.

use strict;
use Test::More tests => 2;

{
    package A;
    use mixin::with 'Top';
    use constant FOO => "Bar";
}

{
    package Top;
    sub new { bless {}, shift }
}

{
    package MixinUser;
    use base qw(Top);
    use mixin qw(A);
}

pass("Mixins work with classes using constants");
is(MixinUser->new->FOO, "Bar", "Expected constant value");
