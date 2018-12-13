#!/usr/bin/perl

# This test is checking some timeout code with respect to locking, so it runs
# for a long time (by necessity).

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/mocks";

use POSIX qw(strftime);
use File::Path ();
use Test::More tests => 2;

use cPanel::FakeLogger;
use cPanel::StateFile::FileLocker ();

# WARNING: The internal StateFile locking should never be used this way. However,
# I am peeking inside the class in order to test this functionality. This access
#  may be removed or changed at any time.

my $tmpdir = './tmp';

# Make sure we are clean to start with.
File::Path::rmtree($tmpdir);
my $filename = "$tmpdir/fake.file";
my $lockfile = "$filename.lock";

File::Path::mkpath($tmpdir) or die "Unable to create tmpdir: $!";
my $logger = cPanel::FakeLogger->new;
my $locker = cPanel::StateFile::FileLocker->new( { logger => $logger, max_age => 120, max_wait => 120 } );

{
    # Make sure we are clean to start with.
    unlink $lockfile;

    # Locked by my PID, but a different program.
    {
        open( my $fh, '>', $lockfile ) or die "Cannot create lockfile.";
        print $fh "$$\nfred\n", time + 100, "\n";
        close($fh);
        $logger->reset_msgs();
        my $start = time;
        my $lock  = $locker->file_lock($filename);
        my $diff  = time - $start;
        my @msgs  = $logger->get_msgs();
        $logger->reset_msgs();
        like( $msgs[0], qr/warn: Inconsistent lock/, 'handles lock with my PID but other progname.' );
        is_within( $diff, 0, 2, 'did not wait for inconsistent lock.' );

        $locker->file_unlock($lock);
    }
}
File::Path::rmtree($tmpdir);

sub is_within {
    my ( $val, $min, $max, $msg ) = @_;
    return ok( 1, $msg ) if $min <= $val && $val <= $max;
    diag("$val is not within $min and $max");
    fail($msg);
    return;
}
