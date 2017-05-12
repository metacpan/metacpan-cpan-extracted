use strict;
use warnings;

use Test;

BEGIN {
    require Win32 unless defined &Win32::IsWin95;
    if (Win32::IsWin95()) {
        print"1..0 # skip Win32::EventLog is not supported on Windows 95\n";
	exit 0;
    }
}

use Win32::EventLog;

plan tests => 11;

ok(Win32::EventLog::Open(my $EventObj, "WinApp", ""));

ok($EventObj->GetNumber(my $number));

my $Event = {
    Category  => 50,
    EventType => EVENTLOG_INFORMATION_TYPE,
    EventID   => 100,
    Strings   => "Windows is good",
    Data      => "unix",
};

ok($EventObj->Report($Event));

ok($EventObj->GetNumber($number));

ok($EventObj->GetOldest(my $oldNumber));

$number += $oldNumber - 1;

ok($EventObj->Read((EVENTLOG_SEEK_READ | EVENTLOG_FORWARDS_READ), $number, my $EventInfo));

ok($EventInfo->{EventID}, 100);

ok($EventInfo->{Category}, 50);

ok($EventInfo->{EventType}, EVENTLOG_INFORMATION_TYPE);

ok($EventInfo->{Strings}, qr/Windows is good/);

ok($EventInfo->{Data}, 'unix');
