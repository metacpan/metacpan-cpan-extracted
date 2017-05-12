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
use Test::More tests=>4;

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
    skip 'Long running tests not enabled.', 4 unless $ENV{CPANEL_SLOW_TESTS};

    File::Path::mkpath( $tmpdir ) or die "Unable to create tmpdir: $!";
    my $logger = cPanel::FakeLogger->new;
    my $locker = cPanel::StateFile::FileLocker->new({logger => $logger, max_age=>120, max_wait=>120});

    # create expired lockfile
    {
        open( my $fh, '>', $lockfile ) or die "Cannot create lockfile.";
        print $fh 1, "\nFred\n", time+5, "\n";
        close( $fh );
        my $start = time;
        my $lock = eval { $locker->file_lock( $filename ); };
        my @msgs = $logger->get_msgs();
        $logger->reset_msgs();
        is( scalar(@msgs), 2, 'Expired: two messages found' );
        like( $msgs[0], qr/info: .*?Unable to create/, 'Expired: First message detected.' );
        # Maybe create a child and use its PID to do this right???
        #if ( $> ) {
            #like( $msgs[1], qr/warn: .*?Removing abandoned/, 'Abandoned: abandoned message detected.' );
        #}
        #else {
            like( $msgs[1], qr/info: .*?Stale lock/, 'Expired: Stale message detected.' );
        #}

        my $diff = time - $start;
        is_between( $diff, 1, 10, 'Expired: wait time.' );
        $locker->file_unlock( $lock ) if $lock;
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
