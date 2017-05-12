#!/usr/bin/perl

# This test is checking some timeout code with respect to locking, so it runs
# for a long time (by necessity). This code is normally disabled, unless it is
# run with the environment variable CPANEL_SLOW_TESTS set.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/mocks";

use POSIX qw(strftime);
use File::Path ();
use Test::More tests=>19;

use cPanel::FakeLogger;
use cPanel::StateFile::FileLocker ();

# WARNING: The internal StateFile locking should never be used this way. However,
# I am peeking inside the class in order to test this functionality. This access
#  may be removed or changed at any time.

my $tmpdir = './tmp';

# Make sure we are clean to start with.
File::Path::rmtree( $tmpdir );
my $filename = "$tmpdir/fake.file";
my $lockfile = "$filename.lock";

SKIP:
{
    skip 'Long running tests not enabled.', 19 unless $ENV{CPANEL_SLOW_TESTS};

    File::Path::mkpath( $tmpdir ) or die "Unable to create tmpdir: $!";
    my $logger = cPanel::FakeLogger->new;
    my $locker = cPanel::StateFile::FileLocker->new({logger => $logger, max_age=>120, max_wait=>120});

    # create old empty lock file
    {
        system( 'touch', '-t', strftime( '%m%d%H%M.%S', localtime( time-220 ) ), $lockfile ) ;
        my $start = time;
        my $lock = $locker->file_lock( $filename );
        my @msgs = $logger->get_msgs();
        $logger->reset_msgs();
        is( scalar(@msgs), 2, 'Empty: two messages found' );
        like( $msgs[0], qr/info: .*?Unable to create/, 'Empty: First message detected.' );
        like( $msgs[1], qr/info: .*?Old, but empty/, 'Empty: Empty file message detected.' );

        my $diff = time - $start;
        ok( $diff < 10, "Very old lockfile taken out quickly." );
        ok( open( my $fh, '<', $lockfile ), 'Lockfile readable' );
        chomp( my ($pid, $name, $wait_time ) = <$fh> );
        close( $fh );
        is( $pid, $$, 'Pid in lockfile is correct' );
        is( $name, $0, 'Name in lockfile is correct' );
        ok( $wait_time >= $start+120, 'Wait time in lockfile is correct' );
        ok( -e $lockfile, 'File exists before unlock' );
        $locker->file_unlock( $lock ) if $lock;
        ok( !-e $lockfile, 'File gone after unlock' );
    }

    # create medium old empty lock file
    {
        system( 'touch', '-t', strftime( '%m%d%H%M.%S', localtime( time-60 ) ), $lockfile ) ;
        my $start = time;
        my $lock = $locker->file_lock( $filename );
        my @msgs = $logger->get_msgs();
        $logger->reset_msgs();
        is( scalar(@msgs), 2, 'Medium: two messages found' );
        like( $msgs[0], qr/info: .*?Unable to create/, 'Medium: First message detected.' );
        like( $msgs[1], qr/info: .*?Old, but empty/, 'Medium: Empty file message detected.' );

        my $diff = time - $start;
        is_between( $diff, 55, 70, 'Medium: expiration time is reasonable.' );
        $locker->file_unlock( $lock ) if $lock;
    }

    # create new empty lockfile
    {
        open( my $fh, '>', $lockfile ) or die "Cannot create lockfile.";
        close( $fh );
        my $start = time;
        my $lock = eval { $locker->file_lock( $filename ); };
        my $diff = time - $start;
        like( $@, qr/Failed to acquire/, "Timed out on empty file" );
        my @msgs = $logger->get_msgs();
        pop @msgs; # Discard throw message that we have already checked.
        $logger->reset_msgs();
        ok( scalar(@msgs) > 2, 'Medium: multiple messages found' );
        like( $msgs[0], qr/info: .*?Unable to create/, 'New: First message detected.' );
        like( $msgs[-1], qr/info: .*?Unable to create/, 'New: Last message detected.' );

        is_between( $diff, 115, 125, 'New: Reasonable timeout.' );
    }
}

File::Path::rmtree( $tmpdir );

sub is_between {
    my ($val, $min, $max, $msg) = @_;
    return ok( 1, $msg ) if $min < $val && $val < $max;
    diag( "$val is not between $min and $max" );
    fail( $msg );
    return;
}
