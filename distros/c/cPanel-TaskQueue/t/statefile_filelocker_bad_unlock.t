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

    # Make sure we are clean to start with.
    unlink $lockfile;

    # Test unlocking
    eval { $locker->file_unlock() };
    like( $@, qr/Missing/, 'Correct handling of unlock with no lockfile' );
    $logger->reset_msgs();

    eval { $locker->file_unlock( $lockfile ) };
    ok( !$@, 'Correct handling of unlock with missing lockfile' );
    my @msgs = $logger->get_msgs();
    $logger->reset_msgs();
    is( scalar(@msgs), 1, 'Lost: one messages found' );
    like( $msgs[0], qr/warn: .*?lost!/, 'Abandoned: First message detected.' );
}

File::Path::rmtree( $tmpdir );
