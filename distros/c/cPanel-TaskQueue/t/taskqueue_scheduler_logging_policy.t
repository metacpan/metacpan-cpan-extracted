#!/usr/bin/perl

# Test the cPanel::StateFile module.
#

use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();

use Test::More tests => 7;
my $logger;
use cPanel::FakeLogger;
BEGIN { $logger = cPanel::FakeLogger->new; }
use cPanel::TaskQueue::Scheduler ( '-logger' => $logger );

eval "use cPanel::TaskQueue::Scheduler ( '-logger' => 'Foo' );";
like( $@, qr/Policies already/, 'Cannot reset policies.' );

eval "use cPanel::TaskQueue::Scheduler;";
like( $@, qr/Policies already/, 'Cannot reset policies to defaults.' );

eval "use cPanel::TaskQueue::Scheduler ();";
ok( !$@, 'Can reload with import turned off.' );

my $tmpdir = './tmp';
my $dir = "$tmpdir/statefile";

# clean up if last run failed.
cleanup();
File::Path::mkpath( $dir );

# test bad new calls.
eval {
    my $cf = cPanel::TaskQueue::Scheduler->new();
};
like( $@, qr/caching directory/, 'Cannot create StateFile without parameters' );
like( ($logger->get_msgs())[0], qr/throw.*?caching directory/, 'Logged correctly.' );
$logger->reset_msgs();

my $ts = cPanel::TaskQueue::Scheduler->new( { name => 'tasks', state_dir => $dir } );

# Make a task with no retries remaining.
my $task = cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1, retries=> 1});
$task->decrement_retries;
ok( !$ts->schedule_task( $task, { delay_seconds=>1} ), 'Finished trying to queue a task with no retries.' );
like( ($logger->get_msgs())[0], qr/info.*?0 retries/, 'Infoed correctly.' );
$logger->reset_msgs();

cleanup();

# Discard temporary files that we don't need any more.
sub cleanup {
    File::Path::rmtree( $tmpdir ) if -d $tmpdir;
}
