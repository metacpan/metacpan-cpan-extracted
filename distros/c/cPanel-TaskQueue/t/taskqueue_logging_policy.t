#!/usr/bin/perl

# Test the cPanel::StateFile module.
#

use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 10;
my $logger;
use cPanel::FakeLogger;
BEGIN { $logger = cPanel::FakeLogger->new; }
use cPanel::TaskQueue ( '-logger' => $logger );

eval "use cPanel::TaskQueue ( '-logger' => 'Foo' );";
like( $@, qr/Policies already/, 'Cannot reset policies.' );

eval "use cPanel::TaskQueue;";
like( $@, qr/Policies already/, 'Cannot reset policies to defaults.' );

eval "use cPanel::TaskQueue ();";
ok( !$@, 'Can reload with import turned off.' );

my $tmpdir = './tmp';

# clean up if last run failed.
cleanup();
File::Path::mkpath( $tmpdir ) or die "Unable to create tmpdir: $!";

# test bad new calls.
eval {
    my $cf = cPanel::TaskQueue->new( {} );
};
like( $@, qr/state directory/, 'Cannot create StateFile without parameters' );
like( ($logger->get_msgs())[0], qr/throw.*?state directory/, 'Logged correctly.' );
$logger->reset_msgs();

my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $tmpdir } );

cPanel::TaskQueue->register_task_processor( 'mock', sub {} );

ok( $queue->queue_task( 'mock this is a test' ), 'Task added.' );

cPanel::TaskQueue->unregister_task_processor( 'mock' );

ok( $queue->process_next_task(), 'Task completed' );
like( ($logger->get_msgs())[0], qr/warn.*?No processor found/, 'Warned correctly.' );
$logger->reset_msgs();

# Make a task with no retries remaining.
my $task = cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1, retries=> 1});
$task->decrement_retries;
ok( !$queue->queue_task( $task ), 'Finished trying to queue a task with no retries.' );
like( ($logger->get_msgs())[0], qr/info.*?0 retries/, 'Infoed correctly.' );
$logger->reset_msgs();

cleanup();

# Discard temporary files that we don't need any more.
sub cleanup {
    File::Path::rmtree( $tmpdir ) if -d $tmpdir;
}
