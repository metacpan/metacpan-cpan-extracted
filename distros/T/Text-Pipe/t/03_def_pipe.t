#!/usr/bin/env perl

use warnings;
use strict;
use Text::Pipe;
use Text::Pipe::Stackable;
use Test::More tests => 3;

Text::Pipe->def_pipe('Foobar', sub { lc $_[1] });
my $pipe_lowercase = Text::Pipe->new('Foobar');
is($pipe_lowercase->filter('A TEST'), 'a test', 'lowercase by def_pipe');

my $pipe_repeat  = Text::Pipe->new('Repeat', times => 2, join => ' = ');
my $pipe_reverse = Text::Pipe->new('Reverse');

my $stacked_pipe = Text::Pipe::Stackable->new(
    $pipe_repeat, $pipe_lowercase, $pipe_reverse
);

my $input = 'A TEST';

is($stacked_pipe->count, 3, 'three segments');
is($stacked_pipe->filter($input), 'tset a = tset a',
    'stacked pipe works with def_pipe'
);
