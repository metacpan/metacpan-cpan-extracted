#!/usr/bin/perl

# Test the cPanel::TaskQueue::Task module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";

use Test::More tests => 6;
use cPanel::TaskQueue::Task;

my $task = cPanel::TaskQueue::Task->new( {cmd=>q{noop  'a \\'b\\''   "\\"c \\" d"  e}, id=>5, timeout=>10} );
my $clone = $task->clone();
isa_ok( $clone, 'cPanel::TaskQueue::Task', 'Clone is Correct type.' );

is( $clone->command(), 'noop',    'cloned: command is correct' );
is( $clone->argstring(), q{'a \\'b\\''   "\\"c \\" d"  e}, 'cloned: argstring is correct' );
is_deeply( [ $clone->args() ], [ q{a 'b'}, q{"c " d}, q{e} ], 'cloned: args list is correct' );
is( $clone->uuid(), $task->uuid(), 'cloned: Queue id still matches.' );
is( $clone->child_timeout(), $task->child_timeout(), 'cloned: Child timeout still matches.' );

