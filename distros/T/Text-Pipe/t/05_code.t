#!/usr/bin/env perl

use warnings;
use strict;
use Text::Pipe;
use Text::Pipe::Stackable;
use Test::More tests => 3;

my $pipe_code = Text::Pipe->new('Code', code => sub { lc $_[0] });
is($pipe_code->filter('PERL'), 'perl', 'code filter');

my $pipe_repeat  = Text::Pipe->new('Repeat', times => 2, join => ' = ');

my $stacked_pipe = Text::Pipe::Stackable->new($pipe_repeat, $pipe_code);

is($stacked_pipe->count, 2, 'two segments');
is($stacked_pipe->filter('PERL'), 'perl = perl',
    'stacked pipe with code segment'
);
