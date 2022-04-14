#!/usr/bin/perl

use Test::More tests => 7;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/mocks";
use File::Path ();
use File::Temp ();

use cPanel::TaskQueue::Scheduler ( -logger => 'cPanel::FakeLogger', -serializer => 'cPanel::TQSerializer::YAML' );

my ( $tmpdir, $statedir );

setup();

{
    open( my $fh, '>', "$statedir/tasks_sched.yaml" ) or die "Unable to create file: $!\n";
    print $fh "Bad YAML file.";
}

{
    my $queue = cPanel::TaskQueue::Scheduler->new( { name => 'tasks', state_dir => $statedir } );
    isa_ok( $queue, 'cPanel::TaskQueue::Scheduler', 'Correct object built.' );
    is( $queue->get_name, 'tasks', 'Queue is named correctly.' );
    ok( -e "$statedir/tasks_sched.yaml.broken", 'Bad file moved out of the way.' );
    is(
        do { open my $fh, '<', "$statedir/tasks_sched.yaml.broken"; scalar <$fh>; },
        "Bad YAML file.",
        'Damaged file was moved.'
    );
}

setup();

{
    use YAML::Syck ();

    open( my $fh, '>', "$statedir/tasks_sched.yaml" ) or die "Unable to create file: $!\n";
    print $fh YAML::Syck::Dump( 'TaskScheduler', 3.1415, {} );
}

{
    my $queue = cPanel::TaskQueue::Scheduler->new( { name => 'tasks', state_dir => $statedir } );
    isa_ok( $queue, 'cPanel::TaskQueue::Scheduler', 'Correct object built.' );
    is( $queue->get_name, 'tasks', 'Queue is named correctly.' );
    ok( -e "$statedir/tasks_sched.yaml.broken", 'Bad file moved out of the way.' );
}

exit;

# Clean up after myself
sub setup {
    $tmpdir   = File::Temp->newdir();
    $statedir = "$tmpdir/state_test";
    File::Path::mkpath($statedir);
    return;
}
