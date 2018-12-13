#!/usr/bin/perl

use Test::More tests => 7;

use strict;
use warnings;
use FindBin;
use File::Path ();
use lib "$FindBin::Bin/mocks";

use cPanel::TaskQueue ( -logger => 'cPanel::FakeLogger' );

my $tmpdir   = './tmp';
my $statedir = "$tmpdir/state_test";

# In case the last test did not succeed.
cleanup();
File::Path::mkpath($statedir);

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

cleanup();
File::Path::mkpath($statedir);

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

cleanup();

# Clean up after myself
sub cleanup {
    File::Path::rmtree($tmpdir);
}
