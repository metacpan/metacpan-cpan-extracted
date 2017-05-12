package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	Test::Spelling->import();
    };
    $@ and do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
}

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
Aldo
Amine
API
APIs
Bowes
Calpini
DLL
ExecutablePath
Faylor
GetProcInfo
GetProcInfo's
IDs
infinitum
ISBN
Jenda
Jutta
Klebe
Krynicky
LibWin
MaximumWorkingSetSize
merchantability
MinimumWorkingSetSize
Moulay
NT
NT's
NtQuerySystemInformation
Nemours
OSes
pathname
PIDs
Pitney
PPM
PT
ParentProcessId
Prantl
ProcessId
Pulist
Ramdane
ReactOS
Roth
SID
subclasses
SubProcInfo
Sugalski
cc
clunks
de
dll
exe
exportable
gory
ness
ntdll
pids
ps
psapi
pulist
retrofitted
stime
Urist
Urist's
VCC
username
winpid
winppid
Winternl
WMI
Wyant
xs
