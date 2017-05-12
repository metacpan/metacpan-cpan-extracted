#!/usr/bin/perl

# Test the cPanel::TaskQueue::Task module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";

use Test::More tests => 27;
use cPanel::TaskQueue::Task;

my $t1 = cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1, timeout=>10} );
isa_ok( $t1, 'cPanel::TaskQueue::Task', 'Correct type.' );

is( $t1->command(), 'noop',   'no args: command is correct' );
is( $t1->argstring(), '',     'no args: argstring is correct' );
is_deeply( [ $t1->args() ], [],   'no args: args list is empty' );
is( $t1->child_timeout(), 10, 'no args: timeout is correct' );
ok( time == $t1->timestamp() || time-1 == $t1->timestamp(), 'Correct timestamp.' );

my $t2 = cPanel::TaskQueue::Task->new( {cmd=>'NOOP a b c', id=>3, timeout=>10} );
isa_ok( $t2, 'cPanel::TaskQueue::Task', 'Correct type.' );

is( $t2->command(), 'NOOP',    'simple args: command is correct' );
is( $t2->argstring(), 'a b c', 'simple args: argstring is correct' );
is( $t2->full_command(), 'NOOP a b c', 'simple args: full command is correct' );
is_deeply( [ $t2->args() ], [qw/a b c/], 'simple args: args list is correct' );

my $t3 = cPanel::TaskQueue::Task->new( {cmd=>q{noop  'a b'   "c d"  e}, id=>2, timeout=>10} );

is( $t3->command(), 'noop',    'quoted args: command is correct' );
is( $t3->argstring(), q{'a b'   "c d"  e}, 'quoted args: argstring is correct' );
is( $t3->full_command(), q{noop 'a b'   "c d"  e}, 'quoted args: full command is correct' );
is_deeply( [ $t3->args() ], [ q{a b}, q{c d}, q{e} ], 'quoted args: args list is correct' );

my $t4 = cPanel::TaskQueue::Task->new( {cmd=>q{noop  'a \\'b\\''   "\\"c \\" d"  e}, id=>5, timeout=>10} );

is( $t4->command(), 'noop',    'escaped quoted args: command is correct' );
is( $t4->argstring(), q{'a \\'b\\''   "\\"c \\" d"  e}, 'escaped quoted args: argstring is correct' );
is_deeply( [ $t4->args() ], [ q{a 'b'}, q{"c " d}, q{e} ], 'escaped quoted args: args list is correct' );

my $t6 = cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1} );
is( $t6->child_timeout(), -1, 'Missing timeout' );

eval { $t1->get_userdata() };
like( $@, qr/No userdata key/, 'Require a key to access user data.' );

ok( !defined $t1->started, 'Has not yet begun.' );
$t1->begin;
ok( time == $t1->started || time-1 == $t1->started, 'Has now started.' );

ok( !defined $t1->pid, 'Task without a child process has no pid' );
$t1->set_pid( $$ );
is( $t1->pid, $$, ' ... but I can give it one.' );

# Verify valid taskid test
ok( cPanel::TaskQueue::Task::is_valid_taskid( $t1->uuid() ), 'Taskid is not valid.' );
ok( !cPanel::TaskQueue::Task::is_valid_taskid(), 'Missing taskid is not valid.' );
ok( !cPanel::TaskQueue::Task::is_valid_taskid( 'fred' ), 'badly formed taskid is not valid.' );
