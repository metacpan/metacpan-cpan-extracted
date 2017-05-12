#!/usr/bin/env perl

use warnings;
use strict;
use Text::Pipe 'PIPE';
use Text::Pipe::Stackable;
use Test::More tests => 56;


sub pipe_ok {
    my ($spec, $input, $expect, $testname) = @_;
    $spec = [ $spec ] unless ref $spec eq 'ARRAY';
    my $type = $spec->[0];

    $testname = '' unless defined $testname;
    $testname = "$type $testname: $input";
    $testname =~ s/\n/\\n/g;

    is(PIPE(@$spec)->filter($input), $expect, "PIPE $testname");

    my $pipe = Text::Pipe->new(@$spec);
    isa_ok($pipe, 'Text::Pipe::Base');
    is($pipe->filter($input), $expect, "new $testname");
}


my $pipe_trim    = Text::Pipe->new('Trim');
my $pipe_uc      = Text::Pipe->new('Uppercase');
my $pipe_repeat  = Text::Pipe->new('Repeat', times => 2, join => ' = ');
my $pipe_reverse = Text::Pipe->new('Reverse');

isa_ok($pipe_trim,    'Text::Pipe::Trim');
isa_ok($pipe_uc,      'Text::Pipe::Uppercase');
isa_ok($pipe_repeat,  'Text::Pipe::Repeat');
isa_ok($pipe_reverse, 'Text::Pipe::Reverse');

my $stacked_pipe = Text::Pipe::Stackable->new(
    $pipe_trim, $pipe_uc, $pipe_repeat
);

my $input = '  a test  ';

is($pipe_trim->filter($input), 'a test', 'trim');
is($pipe_uc->filter('a test'), 'A TEST', 'uppercase');
is($pipe_repeat->filter('A TEST'), 'A TEST = A TEST', 'repeat');
is($pipe_reverse->filter('a test'), 'tset a', 'reverse');

is($stacked_pipe->count, 3, 'three segments');
is($stacked_pipe->filter($input), 'A TEST = A TEST', 'stacked pipe');

$stacked_pipe->unshift($pipe_reverse);
is($stacked_pipe->count, 4, 'now four segments');
is($stacked_pipe->filter($input), 'TSET A = TSET A', 'unshift pipe');

$stacked_pipe->splice(2, 1);  # should remove the third segment (uppercase)
is($stacked_pipe->count, 3, 'now three segments');
is($stacked_pipe->filter($input), 'tset a = tset a', 'spliced pipe');

pipe_ok('Trim', '  a test  ', 'a test');
pipe_ok('Uppercase', 'a test', 'A TEST');
pipe_ok([ 'Repeat', times => 2, join => ' = ' ], 'A TEST', 'A TEST = A TEST');
pipe_ok('Reverse', 'a test', 'tset a');

pipe_ok('Append', 'a test', 'a test', 'empty');
pipe_ok([ 'Append', text => 'foobar' ], 'a test', 'a testfoobar', 'text');

pipe_ok('Prepend', 'a test', 'a test', 'empty');
pipe_ok([ 'Prepend', text => 'foobar' ], 'a test', 'foobara test', 'text');

pipe_ok('Chop', "a test\n", 'a test', 'newline');
pipe_ok('Chop', 'a test', 'a tes', 'non-newline');

pipe_ok('Chomp', "a test\n", 'a test', 'newline');
pipe_ok('Chomp', 'a test', 'a test', 'non-newline');

pipe_ok('UppercaseFirst', 'test', 'Test');
pipe_ok('LowercaseFirst', 'TEST', 'tEST');

