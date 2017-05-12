#!perl -T

use Test::More tests => 5;
use Fcntl qw(:flock);
use XML::Debian::ENetInterfaces;
# TODO: Test the lock detection stuff.
# DOES: Forces locking to avoid hitting the lock detection stuff.

BEGIN {
    if (!eval q{ use Test::Differences; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

my $readname = q{./t/share/interfaces};
my $xmlname = q{./t/share/interfaces.xml};
my $writename = q{./t/share/interfaces-out};
my $sysint = q{/etc/network/interfaces};

my $xmldat;
{ local *FH;
open( *FH, $xmlname) || die("Error: $!\n");
-f *FH and sysread *FH, $xmldat, -s *FH;
close *FH; }

$ENV{INTERFACES} = $readname;
XML::Debian::ENetInterfaces::lock(LOCK_SH);
my $xmlstr = XML::Debian::ENetInterfaces::read();
XML::Debian::ENetInterfaces::unlock();
eq_or_diff $xmlstr, $xmldat, 'Read in provided interfaces compare to provided xml.';

my $intdat;
{ local *FH;
open( *FH, $readname) || die("Error: $!\n");
-f *FH and sysread *FH, $intdat, -s *FH;
close *FH; }

$ENV{INTERFACES} = $writename;
XML::Debian::ENetInterfaces::lock();
XML::Debian::ENetInterfaces::write($xmldat);
XML::Debian::ENetInterfaces::unlock();

my $intout;
{ local *FH;
open( *FH, $writename) || die("Error: $!\n");
-f *FH and sysread *FH, $intout, -s *FH;
close *FH; }

eq_or_diff $intout, $intdat, 'Write out provided xml compare to provided interfaces.';

# All things being equal then the other iterations shouldn't matter.

SKIP: {
      skip q{Can't find interfaces, not likely Debian/Ubuntu/ect.}, 3 unless (-f $sysint and -r $sysint);

$ENV{INTERFACES}=q{/tmp/dontfreak};
XML::Debian::ENetInterfaces::lock();
# No we are locked.  So no more changes to the lock files, reading /etc/network/interfaces.
delete $ENV{INTERFACES};
$xmldat = XML::Debian::ENetInterfaces::read();
$ENV{INTERFACES}=q{/tmp/dontfreak};
XML::Debian::ENetInterfaces::unlock();

ok($xmldat, 'Read system interfaces into memory.');

$ENV{INTERFACES} = $writename;
XML::Debian::ENetInterfaces::lock();
XML::Debian::ENetInterfaces::write($xmldat);
XML::Debian::ENetInterfaces::unlock();

my $sysdat;
{ local *FH;
open( *FH, $sysint) || die("Error: $!\n");
-f *FH and sysread *FH, $sysdat, -s *FH;
close *FH; }

my $locdat;
{ local *FH;
open( *FH, $writename) || die("Error: $!\n");
-f *FH and sysread *FH, $locdat, -s *FH;
close *FH; }

eq_or_diff $locdat, $sysdat, 'Write out interfaces compare to system interfaces.';

# Now to test the round trip.
XML::Debian::ENetInterfaces::lock(LOCK_SH);
my $xmlstr = XML::Debian::ENetInterfaces::read();
XML::Debian::ENetInterfaces::unlock();

eq_or_diff $xmlstr, $xmldat, 'Read in written interfaces compare to xml written.';

}

