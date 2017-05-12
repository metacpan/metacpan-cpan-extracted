use Test::More skip_all => " *** NOT IMPLEMENTED";
# (c) 1995 Microsoft Corporation. All rights reserved.
#	Developed by ActiveWare Internet Corp., http://www.ActiveWare.com

# eventlog.t - Event Logging tests

BEGIN {
    require Win32 unless defined &Win32::IsWin95;
    if (Win32::IsWin95()) {
        print"1..0\n";
        print STDERR "# EventLog is not supported on Windows 95 or Win32s\n";
    }
}

use strict;
use Win32::EventLog;

my $bug = 1;

# accounting for the test harness
open ME, $0 or die $!;
my $bugs = grep /^\$bug\+\+;\n$/, <ME>;
close ME;

print "1..$bugs\n";

Win32::EventLog::Open(my $EventObj, 'WinApp', '') or print "not ";
print "ok $bug\n";
$bug++;

$EventObj->GetNumber(my $number) or print "not ";
print "ok $bug\n";
$bug++;

my $Event = {Category => 50,
	     EventType => EVENTLOG_INFORMATION_TYPE,
	     EventID => 100,
	     Strings => "Windows is good",
	     Data => 'unix',
	    };

$EventObj->Report($Event) or print "not ";
print "ok $bug\n";
$bug++;

$EventObj->GetNumber($number) or print "not ";
print "ok $bug\n";
$bug++;

$EventObj->GetOldest(my $oldNumber) or print "not ";
print "ok $bug\n";
$bug++;

$number += $oldNumber - 1;

$EventObj->Read((EVENTLOG_SEEK_READ | EVENTLOG_FORWARDS_READ),
		$number, my $EventInfo) or print "not ";
print "ok $bug\n";
$bug++;

$EventInfo->{EventID} == 100 or print "not ";
print "ok $bug\n";
$bug++;

$EventInfo->{Category} == 50 or print "not ";
print "ok $bug\n";
$bug++;

$EventInfo->{EventType} == EVENTLOG_INFORMATION_TYPE or print "not ";
print "ok $bug\n";
$bug++;

$EventInfo->{Strings} =~/Windows is good/ or print "not ";
print "ok $bug\n";
$bug++;

$EventInfo->{Data} eq 'unix' or print "not ";
print "ok $bug\n";
$bug++;



