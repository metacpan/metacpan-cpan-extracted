#!/usr/bin/env perl

# This test file is from the namespace::autoclean distribution (t/role.t)

use strict;
use warnings;
use Test::More;

BEGIN {
    eval 'use Moose 0.56 ()';
    plan skip_all => 'requires Moose 0.56' if $@;
    plan tests => 1;
}

BEGIN {
    diag "Testing with Moose $Moose::VERSION";
}

{
    package Foo;
    use Moose::Role;
    use namespace::sweep;
}

# meta doesn't get cleaned, although it's not in get_method_list for roles
can_ok('Foo', 'meta')
