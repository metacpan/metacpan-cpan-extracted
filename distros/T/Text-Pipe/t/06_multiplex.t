#!/usr/bin/env perl

use warnings;
use strict;
use Text::Pipe;
use Text::Pipe::Stackable;
use Test::More tests => 2;

my $pipe_uc      = Text::Pipe->new('Uppercase');
my $pipe_repeat  = Text::Pipe->new('Repeat', times => 2, join => ' = ');
my $pipe_reverse = Text::Pipe->new('Reverse');
my $pipe_stacked = Text::Pipe::Stackable->new(
    $pipe_uc, $pipe_repeat, $pipe_reverse
);

my $pipe = Text::Pipe->new('Multiplex',
    pipes => [ $pipe_uc, $pipe_repeat, $pipe_reverse, $pipe_stacked ],
);

is($pipe->deep_count, 6, 'six segments in all');
is_deeply($pipe->filter('a test'),
    [ 'A TEST', 'a test = a test', 'tset a', 'TSET A = TSET A' ],
    'multiplex with stacked pipe'
);
