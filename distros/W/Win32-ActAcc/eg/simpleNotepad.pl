# Copyright 2001, 2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

# This script runs Notepad (which must be on the Path) and immediately
# closes it with File|Exit.

use Win32::OLE;
use Win32::ActAcc;

Win32::OLE->Initialize();

sub StartNotepad
{
    my $eh = Win32::ActAcc::createEventMonitor(1);
    Win32::ActAcc::clearEvents();
    sleep(3);
    system("start notepad");
    my $aoNotepad = Win32::ActAcc::waitForEvent(
	+{ 
      'event'=>Win32::ActAcc::EVENT_OBJECT_SHOW(),
	  'name'=>qr/Notepad/,
	  'role'=>Win32::ActAcc::ROLE_SYSTEM_WINDOW()
     },
     +{
      'trace'=>1
     });
    die unless defined($aoNotepad);
    return $aoNotepad;
}

$aoNotepad = StartNotepad();
$aoNotepad->menuPick(+["File", "Exit"]);
