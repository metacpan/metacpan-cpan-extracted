#!/usr/bin/env perl

use warnings;
use strict;
use Text::Pipe;
use Text::Pipe::Stackable;
use Test::More tests => 3;

my $pipe_trim    = Text::Pipe->new('Trim');
my $pipe_uc      = Text::Pipe->new('Uppercase');
my $pipe_repeat  = Text::Pipe->new('Repeat', times => 2, join => ' = ');
my $pipe_reverse = Text::Pipe->new('Reverse');

my $stacked_pipe = $pipe_trim | $pipe_uc | $pipe_repeat;

my $input = '  a test  ';
is($stacked_pipe->count, 2, 'two segments in the top pipe');
is($stacked_pipe->deep_count, 3, 'but three segments overall (nested pipe)');
is($stacked_pipe->filter($input), 'A TEST = A TEST', 'stacked, nested pipe');
