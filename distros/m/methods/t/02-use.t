# Test derived from Method::Signatures::Simple:
#   Copyright 2008 Rhesa Rozendaal, all rights reserved.
#   This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

use strict;
use warnings;

use Test::More tests => 8;
use_ok 'methods';

{
    package My::Obj;
    use methods;

    method make($class: %opts) {
        bless {%opts}, $class;
    }
    method first : lvalue {
        $self->{first};
    }
    method second {
        $self->first + 1;
    }
    method nth($inc) {
        $self->first + $inc;
    }
}

my $o = My::Obj->make(first => 1);
is $o->first, 1;
is $o->second, 2;
is $o->nth(10), 11;

$o->first = 10;

is $o->first, 10;
is $o->second, 11;
is $o->nth(10), 20;

ok !$o->can('method'), 'autoclean worked'
