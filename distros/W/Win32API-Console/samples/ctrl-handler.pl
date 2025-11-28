# https://learn.microsoft.com/en-us/windows/console/registering-a-control-handler-function
# Basic Control Handler Example
#
# This file contains the 'main' function. Program execution begins and ends 
# there.

use lib '../lib', 'lib';
use Win32::API;
use Win32API::Console qw(
  SetConsoleCtrlHandler
  :CTRL_EVENT_
);

BEGIN {
  Win32::API::More->Import('kernel32', 
    'BOOL Beep(DWORD dwFreq, DWORD dwDuration)'
  ) or die "Import Beep failed: $^E";
}

$SIG{BREAK} = $SIG{INT} = sub { exit 0 };  # default handler

sub CtrlHandler {
  my ($fdwCtrlType) = @_;
  SWITCH: for ($fdwCtrlType)
  {
    # Handle the CTRL-C signal.
    CTRL_C_EVENT == $_ and do {
      print("Ctrl-C event\n\n");
      Beep(750, 300);
      return 1;
    };

    # Pass other signals to the next handler.
    CTRL_BREAK_EVENT == $_ and do {
      Beep(900, 200);
      print("Ctrl-Break event\n\n");
      return 0;
    };

    DEFAULT: {
      return 0;
    }
  }
}

sub main
{
  if (SetConsoleCtrlHandler(\&CtrlHandler, 1))
  {
    print("\nThe Control Handler is installed.\n");
    print("\n -- Now try pressing Ctrl+C or Ctrl+Break");
    print("\n(...waiting in a loop for events...)\n\n");

    while (1) { }
  }
  else
  {
    print("\nERROR: Could not set control handler");
    return 1;
  }
  return 0;
}

exit main();

__END__

=pod

This is an example of the 
L<SetConsoleCtrlHandler|Win32API::Console/SetConsoleCtrlHandler> 
function that is used to install a control handler.

When a CTRL+C signal is received, the control handler returns C<TRUE>, 
indicating that it has handled the signal. Doing this prevents other control 
handlers from being called.

When a C<CTRL_CLOSE_EVENT> signal is received, the control handler returns 
C<TRUE> and the process terminates.

When a C<CTRL_BREAK_EVENT> signal is received, the control handler returns 
C<FALSE>. Doing this causes the signal to be passed to the next control handler 
function. If no other control handlers have been registered or none of the 
registered handlers returns C<TRUE>, the default handler will be used, 
resulting in the process being terminated.
