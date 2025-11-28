# https://learn.microsoft.com/en-us/windows/console/clearing-the-screen
# Clearing the Screen

use 5.014;
use warnings;

use Encode;
use lib '../lib', 'lib';
use Win32;
use Win32API::Console qw(
  :Func
  :FuncW
  :OUTPUT_MODE_
  :STD_HANDLE_
);

sub L ($) { Encode::encode('UTF-16LE', $_[0]) }

END { warn "$^E\n" if $^E }

sub main {
  my $hStdOut;

  $hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);

  # Fetch existing console mode so we correctly add a flag and not turn off 
  # others
  my $mode = 0;
  if (!GetConsoleMode($hStdOut, \$mode))
  {
    return Win32::GetLastError();
  }

  # Hold original mode to restore on exit to be cooperative with other 
  # command-line apps.
  my $originalMode = $mode;
  $mode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;

  # Try to set the mode.
  if (!SetConsoleMode($hStdOut, $mode))
  {
    return Win32::GetLastError();
  }

  # Write the sequence for clearing the display.
  my $written = 0;
  my $sequence = L"\x1b[2J";
  if (!WriteConsoleW($hStdOut, $sequence, \$written))
  {
    # If we fail, try to restore the mode on the way out.
    SetConsoleMode($hStdOut, $originalMode);
    return Win32::GetLastError();
  }

  # To also clear the scroll back, emit L"\x1b[3J" as well.
  # 2J only clears the visible window and 3J only clears the scroll back.

  # Restore the mode on the way out to be nice to other command-line applications.
  SetConsoleMode($hStdOut, $originalMode);

  return 0;
}

exit main();

__END__

=pod

With this method, the console is set up for the output sequences of the virtual 
terminal and then the "clear screen" command is sent.

B<Tip>: This is the recommended method using virtual terminal sequences for all 
new development. For more information, see the discussion of classic console 
APIs versus virtual terminal sequences on MSDN.
