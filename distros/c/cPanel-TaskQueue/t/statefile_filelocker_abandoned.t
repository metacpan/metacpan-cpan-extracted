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
use Test::More tests=>5;

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
    skip 'Long running tests not enabled.', 5 unless $ENV{CPANEL_SLOW_TESTS};

    File::Path::mkpath( $tmpdir ) or die "Unable to create tmpdir: $!";
    my $logger = cPanel::FakeLogger->new;
    my $locker = cPanel::StateFile::FileLocker->new({logger => $logger, max_age=>120, max_wait=>120});

    # create abandoned lockfile
    {
        open( my $fh, '>', $lockfile ) or die "Cannot create lockfile.";
        print $fh 65537, "\nFred\n", time+5, "\n";
        close( $fh );
        my $start = time;
        my $lock = eval { $locker->file_lock( $filename ); };
        ok( $lock, 'Lock returned successfully' );
        my @msgs = $logger->get_msgs();
        $logger->reset_msgs();
        is( scalar(@msgs), 2, 'Abandoned: two messages found' );
        like( $msgs[0], qr/info: .*?Unable to create/, 'Abandoned: First message detected.' );
        like( $msgs[1], qr/warn: .*?Removing abandoned/, 'Abandoned: abandoned message detected.' );

        my $diff = time - $start;
        ok( $diff < 10, "Abandoned: Did not wait too long." );
        $locker->file_unlock( $lock ) if $lock;
    }
}
File::Path::rmtree( $tmpdir );
