#!/usr/bin/perl

use Test::More tests => 7;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();
use File::Temp ();

use cPanel::TaskQueue::Scheduler ( -logger => 'cPanel::FakeLogger' );

my ( $tmpdir, $statedir );
setup();

{
    open( my $fh, '>', "$statedir/tasks_sched.stor" ) or die "Unable to create file: $!\n";
    print $fh "Bad Storable file.";
}

{
    my $queue = cPanel::TaskQueue::Scheduler->new( { name => 'tasks', state_dir => $statedir } );
    isa_ok( $queue, 'cPanel::TaskQueue::Scheduler', 'Correct object built.' );
    is( $queue->get_name, 'tasks', 'Queue is named correctly.' );
    ok( -e "$statedir/tasks_sched.stor.broken", 'Bad file moved out of the way.' );
    is(
        do { open my $fh, '<', "$statedir/tasks_sched.stor.broken"; scalar <$fh>; },
        "Bad Storable file.",
        'Damaged file was moved.'
    );
}

setup();

{
    use Storable ();

    open( my $fh, '>', "$statedir/tasks_sched.stor" ) or die "Unable to create file: $!\n";
    Storable::nstore_fd( [ 'TaskScheduler', 3.1415, {} ], $fh );
}

{
    my $queue = cPanel::TaskQueue::Scheduler->new( { name => 'tasks', state_dir => $statedir } );
    isa_ok( $queue, 'cPanel::TaskQueue::Scheduler', 'Correct object built.' );
    is( $queue->get_name, 'tasks', 'Queue is named correctly.' );
    ok( -e "$statedir/tasks_sched.stor.broken", 'Bad file moved out of the way.' );
}

exit;

sub setup {
    $tmpdir   = File::Temp->newdir();
    $statedir = "$tmpdir/state_test";
    File::Path::mkpath($statedir);

    return;
}
