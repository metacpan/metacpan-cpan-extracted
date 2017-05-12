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
File::Path::mkpath( $tmpdir ) or die "Unable to create temporary directory: $!";
my $filename = "$tmpdir/fake.file";
my $lockfile = "$filename.lock";

my $logger = cPanel::FakeLogger->new;
my $locker = cPanel::StateFile::FileLocker->new({logger => $logger, max_age=>120, max_wait=>120});

# Someone else's lockfile
{
    open( my $fh, '>', $lockfile ) or die "Cannot create lockfile.";
    print $fh "1\n$0\n", time+200, "\n";
    close( $fh );
    eval { $locker->file_unlock( $lockfile ) };
    like( $@, qr/locked by another/, 'Did not unlock belonging to someone else' );
    ok( -e $lockfile, 'Empty: lockfile not removed' );
    unlink $lockfile;
}

# Attempt to double lock a file
{
    my $lock = $locker->file_lock( $filename );
    eval { $locker->file_lock( $filename ); };
    like( $@, qr/relock/, 'Not allowed to double-lock' );
    $locker->file_unlock( $lock );
}

{
    open( my $fh, '>', $lockfile ) or die "Unable to create fake lockfile: $!\n";
    print $fh "This is not actually a lock file\n";
    close $fh;

    eval { $locker->file_lock( $filename ); };
    like( $@, qr/Invalid lock file/, 'Correctly handle invalid lock file.' );
}
File::Path::rmtree( $tmpdir );
