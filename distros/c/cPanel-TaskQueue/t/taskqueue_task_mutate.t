#!/usr/bin/perl

# Test the cPanel::TaskQueue::Task module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";

use Test::More tests => 12;
use cPanel::TaskQueue::Task;

my $task = cPanel::TaskQueue::Task->new( {cmd=>q{noop  'a \\'b\\''   "\\"c \\" d"  e}, id=>5, timeout=>10} );

my $mtask = $task->mutate( {id => 6} );
isa_ok( $mtask, 'cPanel::TaskQueue::Task', 'Mutant is Correct type.' );

is( $mtask->command(), 'noop',    'mutated: command is correct' );
is( $mtask->argstring(), q{'a \\'b\\''   "\\"c \\" d"  e}, 'mutated: argstring is correct' );
is_deeply( [ $mtask->args() ], [ q{a 'b'}, q{"c " d}, q{e} ], 'mutated: args list is correct' );
is( $mtask->uuid(), $task->uuid(), 'mutated task has original uuid.' );
is( $mtask->child_timeout(), $task->child_timeout(), 'mutated: Child timeout still matches.' );

my $mtask2 = $task->mutate( {timeout => 2*$task->child_timeout()} );
isa_ok( $mtask2, 'cPanel::TaskQueue::Task', 'Mutant is Correct type.' );

eval {
    $task->mutate( {timeout=>-5} );
};
like( $@, qr/Invalid child timeout/, q{Can't mutate to a bad timeout} );

is( $mtask2->command(), 'noop',    'mutated: command is correct' );
is( $mtask2->argstring(), q{'a \\'b\\''   "\\"c \\" d"  e}, 'mutated: argstring is correct' );
is_deeply( [ $mtask2->args() ], [ q{a 'b'}, q{"c " d}, q{e} ], 'mutated: args list is correct' );
is( $mtask2->child_timeout(), 2*$task->child_timeout(), 'mutated: Child timeout still matches.' );
