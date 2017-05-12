#!/usr/bin/env perl

use warnings;
use strict;
use Text::Pipe::Tester;
use Test::More tests => 13;


pipe_ok('Uppercase', [], [ qw(abc def ghi) ], [ qw(ABC DEF GHI) ],
    'array input'
);

pipe_ok('List::First', [ code => sub { $_ > 8 } ], [ 1 .. 20 ], 9);
pipe_ok('List::Max', [], [ 1 .. 20 ], 20);
pipe_ok('List::MaxStr', [], [ 'A' .. 'Z' ], 'Z');
pipe_ok('List::MinStr', [], [ 'A' .. 'Z' ], 'A');
pipe_ok('List::Reduce', [ code => sub { $_[0] < $_[1] ? $_[0] : $_[1] } ],
    [ 1 .. 20 ], 1);
pipe_ok('List::Sum', [], [ 1 .. 10 ], 55);
pipe_ok('List::Map', [ code => sub { $_ * 2 } ],
    [ 1 .. 5 ], [ 2, 4, 6, 8, 10 ]);
pipe_ok('List::Grep', [ code => sub { $_ % 2 } ],
    [ 1 .. 10 ], [ 1, 3, 5, 7, 9 ]);
pipe_ok('List::Pop', [], [ 1 .. 10 ], 10);
pipe_ok('List::Shift', [], [ 1 .. 10 ], 1);
pipe_ok('List::Size', [], [ 1 .. 10 ], 10);
pipe_ok('List::Sort', [ code => sub { $_[1] <=> $_[0] } ],
    [ 1 .. 6 ], [ 6, 5, 4, 3, 2, 1 ]);
