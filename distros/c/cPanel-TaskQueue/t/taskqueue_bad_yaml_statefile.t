#!/usr/bin/perl

use Test::More tests => 7;

use strict;
use warnings;
use FindBin;
use File::Path ();
use File::Temp ();
use lib "$FindBin::Bin/mocks";

use cPanel::TaskQueue ( -logger => 'cPanel::FakeLogger', -serializer => 'cPanel::TQSerializer::YAML' );

my ( $tmpdir, $statedir );
setup();

{
    open( my $fh, '>', "$statedir/tasks_queue.yaml" );
    print $fh "Bad YAML file.";
}

{
    my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
    isa_ok( $queue, 'cPanel::TaskQueue', 'Correct object built.' );
    is( $queue->get_name, 'tasks', 'Queue is named correctly.' );
    ok( -e "$statedir/tasks_queue.yaml.broken", 'Bad file moved out of the way.' );
    is(
        do { open my $fh, '<', "$statedir/tasks_queue.yaml.broken"; scalar <$fh>; },
        "Bad YAML file.",
        'Damaged file was moved.'
    );
}

setup();

{
    use YAML::Syck ();

    open( my $fh, '>', "$statedir/tasks_queue.yaml" );
    print $fh YAML::Syck::Dump( 'TaskQueue', 3.1415, {} );
}

{
    my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
    isa_ok( $queue, 'cPanel::TaskQueue', 'Correct object built.' );
    is( $queue->get_name, 'tasks', 'Queue is named correctly.' );
    ok( -e "$statedir/tasks_queue.yaml.broken", 'Bad file moved out of the way.' );
}

exit;

sub setup {
    $tmpdir   = File::Temp->newdir();
    $statedir = "$tmpdir/state_test";
    File::Path::mkpath($statedir);

    return;
}
