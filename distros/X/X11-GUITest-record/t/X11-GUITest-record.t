# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl X11-GUITest-record.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

my $ver = 0; 
BEGIN {
      unless (length $ENV{'DISPLAY'})
         {
         warn "Not able to open display\n";
         exit 0;
         }
	$| = 1;  
	};

END { print "not ok 1\n" unless $use;
      unless ($ver)
        {
        print "1..0 # Skip Record extension is not enabled" unless $ver;
        }
      }

use X11::GUITest::record qw/:ALL :CONST/;

$use = 1;


# QueryVersion
my $VERSION_REC = QueryVersion;

exit 0 unless ($VERSION_REC);
$ver = 1;

print "1..4\n";
print "ok 1\n";
print "ok 2 - QueryVersion of record extension\n" if ($VERSION_REC);


my @ret = MotionNotify;

if ($ret[0] == 0 && $ret[1] == 6)
	{
	print "ok 3 - Setting Constants to local package\n";
	}
else 
	{
	print "not ok 3 - Setting Constants to local package\n";
        }


# EnableRecordContext
SetDeliveredEvents(6,6);
$context = EnableRecordContext;
if ($context) 
	{
	print "ok 4 - Enable Record Context\n"
	}
else 
	{
	print "not ok 4 - Enable Record Context\n";
	die;
	}


DisableRecordContext();
