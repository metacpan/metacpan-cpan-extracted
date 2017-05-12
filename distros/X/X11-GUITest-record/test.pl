#!/usr/bin/perl

my $ver;
BEGIN {
      unless (length $ENV{'DISPLAY'}) 
         {
         warn "Not able to open display\n";
         exit 0;
         } 
      }

END { 
    print "1..0 # Skip Record extension is not enabled\n" unless $ver;
    exit 0;
    }

use X11::GUITest::record qw/:ALL :CONST/;

my $VERSION_REC = QueryVersion;
exit 0 unless ($VERSION_REC) ;
$ver = 1;

print "5. --> Please move your mouse for next 3 seconds\n";

my $res = SetRecordContext(MotionNotify);
#SetDeliveredEvents(2,3);
$res = EnableRecordContext;

sleep(3);
DisableRecordContext();
if (GetRecordInfo)
	{
	print "ok 5 - Some movements\n";
	}
else
	{
	print "not ok 5 - No mouse movements \n";
	}

print "6. --> Please press some keys for next 3 seconds\n";

SetRecordContext(KeyRelease, KeyPress);
#SetDeliveredEvents(2,3);
EnableRecordContext;
sleep(3);
DisableRecordContext();

if (GetRecordInfo)
	{
	print "ok 6\n";
	}
else
	{
	print "not ok 6\n";
	}

