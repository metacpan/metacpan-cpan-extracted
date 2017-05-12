#!/usr/bin/perl

# Test the cPanel::TaskQueue::Task module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";

use Test::More tests => 9;
use cPanel::TaskQueue::Task;

my $task = cPanel::TaskQueue::Task->new( {cmd=>q{noop  'a \\'b\\''   "\\"c \\" d"  e}, id=>5, timeout=>10} );

# Retry counter tests.
is( $task->retries_remaining(), 1, 'Default remaining retries is correct' );
my $rt = cPanel::TaskQueue::Task->new( {cmd=>'noop a b', id=>10, timeout=>5,retries=>3} );
is( $rt->child_timeout(), 5, 'retryable: Child timeout is correct.' );
is( $rt->retries_remaining(), 3, 'retryable: remaining retries is correct.' );

my $rtc = $rt->clone();
is( $rtc->retries_remaining(), 3, 'cloned retryable: remaining retries unchanged.' );

eval {
    $rt->mutate( {id=>11, retries=>-5} );
};
like( $@, qr/Invalid value for retries/, q{Can't mutate to invalid retries value} );

my $rtm = $rt->mutate( {id=>11, retries=>5} );
is( $rtm->retries_remaining(), 5, 'mutated retryable: can change retries.' );

# Decrement the retry counter
$rt->decrement_retries();
is( $rt->retries_remaining(), 2, 'retryable: decremented retries is correct.' );
$rt->decrement_retries();
$rt->decrement_retries();
is( $rt->retries_remaining(), 0, 'retryable: no more retries.' );
$rt->decrement_retries();
is( $rt->retries_remaining(), 0, 'retryable: no decrement past 0.' );

