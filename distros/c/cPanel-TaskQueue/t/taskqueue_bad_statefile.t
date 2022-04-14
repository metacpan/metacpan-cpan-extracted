#!/usr/bin/perl

use Test::More tests => 7;

use strict;
use warnings;
use FindBin;
use File::Path ();
use File::Temp ();
use lib "$FindBin::Bin/mocks";

use cPanel::TaskQueue ( -logger => 'cPanel::FakeLogger' );

my ( $tmpdir, $statedir );
setup();

{
    open( my $fh, '>', "$statedir/tasks_queue.stor" );
    print $fh "Bad Storable file.";
}

{
    my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
    isa_ok( $queue, 'cPanel::TaskQueue', 'Correct object built.' );
    is( $queue->get_name, 'tasks', 'Queue is named correctly.' );
    ok( -e "$statedir/tasks_queue.stor.broken", 'Bad file moved out of the way.' );
    is(
        do { open my $fh, '<', "$statedir/tasks_queue.stor.broken"; scalar <$fh>; },
        "Bad Storable file.",
        'Damaged file was moved.'
    );
}

setup();

{
    use Storable ();

    open( my $fh, '>', "$statedir/tasks_queue.stor" );
    Storable::nstore_fd( [ 'TaskQueue', 3.1415, {} ], $fh );
}

{
    my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => $statedir } );
    isa_ok( $queue, 'cPanel::TaskQueue', 'Correct object built.' );
    is( $queue->get_name, 'tasks', 'Queue is named correctly.' );
    ok( -e "$statedir/tasks_queue.stor.broken", 'Bad file moved out of the way.' );
}

# Clean up after myself
sub setup {
    $tmpdir   = File::Temp->newdir();
    $statedir = "$tmpdir/state_test";
    File::Path::mkpath($statedir);

    return;
}
