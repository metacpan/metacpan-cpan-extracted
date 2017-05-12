#!/usr/bin/perl

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 10;
use cPanel::TaskQueue;
use cPanel::TaskQueue::PluginManager;

my $tmpdir = './tmp';
my $statedir = "$tmpdir/state_test";

# In case the last test did not succeed.
cleanup();
File::Path::mkpath( $tmpdir ) or die "Unable to create tmpdir: $!";

cPanel::TaskQueue::PluginManager::load_all_plugins(
    directories => [ "$FindBin::Bin/mocks" ],
    namespaces => [ 'cPanel::ExampleTasks' ],
);

# Create the real TaskQueue
my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
isa_ok( $queue, 'cPanel::TaskQueue', 'Correct object built.' );

my @qids = (
    $queue->queue_task( 'noop 1 2 3' ),
    $queue->queue_task( 'noop a  b  c' ),
    $queue->queue_task( 'bye Fred' ),
    $queue->queue_task( 'adios Fred Bianca' ),
    $queue->queue_task( 'helloworld' ),
    $queue->queue_task( 'hello Bianca' ),
);

is( $queue->how_many_queued(), scalar(@qids), 'Commands queued for further testing.' );

{
    ok( !defined $queue->find_command( 'foo' ), 'Did not find command not queued' );
    is_deeply( [$queue->find_commands( 'foo' )], [],  'Still did not find missing commands' );
}

{
    is( $queue->find_command( 'noop' )->uuid(), $qids[0], 'Found first command' );
    my @tasks = $queue->find_commands( 'noop' );
    is_deeply( [map { $_->uuid } @tasks], [ @qids[0,1] ],  'Found the appropriate commands.' );
}

{
    is( $queue->find_command( 'adios' )->uuid(), $qids[3], 'Found different command' );
    my @tasks = $queue->find_commands( 'adios' );
    is_deeply( [map { $_->uuid } @tasks], [ $qids[3] ],  'Found the appropriate commands.' );
}

{
    is( $queue->find_command( 'hello' )->uuid(), $qids[5], 'Found command that is a substring of another' );
    my @tasks = $queue->find_commands( 'hello' );
    is_deeply( [map { $_->uuid } @tasks], [ $qids[5] ],  'Found only the substring command.' );
}

cleanup();

sub cleanup {
    File::Path::rmtree( $tmpdir );
}
