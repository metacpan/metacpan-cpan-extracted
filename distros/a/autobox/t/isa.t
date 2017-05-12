#!/usr/bin/env perl

package Left;

sub left { __PACKAGE__ }
sub both { __PACKAGE__ }

package Right;

sub right { __PACKAGE__ }
sub both { __PACKAGE__ }

package main;

use strict;
use warnings;

use Test::More tests => 32;

{
    use autobox SCALAR => [ qw(Left Right) ];

    ok(42->autobox_class->isa('Left'), 'LR1: isa Left');
    ok(42->autobox_class->isa('Right'), 'LR1: isa Right');

    ok(42->autobox_class->can('left'), 'LR1: can left');
    ok(42->autobox_class->can('both'), 'LR1: can both');
    ok(42->autobox_class->can('right'), 'LR1: can right');

    is(42->left, 'Left', 'LR1: left');
    is(42->both, 'Left', 'LR1: both');
    is(42->right, 'Right', 'LR1: right');
}

{
    use autobox SCALAR => 'Left';
    use autobox SCALAR => 'Right';

    ok(42->autobox_class->isa('Left'), 'LR2: isa Left');
    ok(42->autobox_class->isa('Right'), 'LR2: isa Right');

    ok(42->autobox_class->can('left'), 'LR2: can left');
    ok(42->autobox_class->can('both'), 'LR2: can both');
    ok(42->autobox_class->can('right'), 'LR2: can right');

    is(42->left, 'Left', 'LR2: left');
    is(42->both, 'Left', 'LR2: both');
    is(42->right, 'Right', 'LR2: right');
}

{
    use autobox SCALAR => [ qw(Right Left) ];

    ok(42->autobox_class->isa('Left'), 'RL1: isa Left');
    ok(42->autobox_class->isa('Right'), 'RL1: isa Right');

    ok(42->autobox_class->can('left'), 'RL1: can left');
    ok(42->autobox_class->can('both'), 'RL1: can both');
    ok(42->autobox_class->can('right'), 'RL1: can right');

    is(42->left, 'Left', 'RL1: left');
    is(42->both, 'Right', 'RL1: both');
    is(42->right, 'Right', 'RL1: right');
}

{
    use autobox SCALAR => 'Right';
    use autobox SCALAR => 'Left';

    ok(42->autobox_class->isa('Left'), 'RL2: isa Left');
    ok(42->autobox_class->isa('Right'), 'RL2: isa Right');

    ok(42->autobox_class->can('left'), 'RL2: can left');
    ok(42->autobox_class->can('both'), 'RL2: can both');
    ok(42->autobox_class->can('right'), 'RL2: can right');

    is(42->left, 'Left', 'RL2: left');
    is(42->both, 'Right', 'RL2: both');
    is(42->right, 'Right', 'RL2: right');
}
