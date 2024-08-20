# https://learn.microsoft.com/en-us/dotnet/api/system.consolekey?view=net-9.0
# The following example uses the ConsoleKey enumeration to indicate to the 
# user which key the user had pressed.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

use constant TRUE => !! 1;
use constant FALSE => !! '';

my $ToString = sub { 
  $_[0] > 4 ? ConsoleKey->get($_[0]) 
            : ConsoleModifiers->get($_[0])
};

sub main {
  my $input;
  do {
    Console->WriteLine("Press a key, together with Alt, Ctrl, or Shift.");
    Console->WriteLine("Press Esc to exit.");
    $input = Console->ReadKey(1);

    my $output = sprintf("You pressed %s", $input->Key->$ToString());
    my $modifiers = FALSE;

    if ( $input->Modifiers & ConsoleModifiers->Alt ) {
      $output .= ", together with " . ConsoleModifiers->Alt->$ToString();
      $modifiers = TRUE;
    }
    if ( $input->Modifiers & ConsoleModifiers->Control ) {
      if ($modifiers) {
        $output .= " and ";
      } else {
        $output .= ", together with ";
        $modifiers = TRUE;
      }
      $output .= ConsoleModifiers->Control->$ToString();
    }
    if ( $input->Modifiers & ConsoleModifiers->Shift ) {
      if ( $modifiers ) {
        $output .= " and ";
      } else {
        $output .= ", together with ";
        $modifiers = TRUE;
      }
      $output .= ConsoleModifiers->Shift->$ToString();
    }
    $output .= ".";
    Console->WriteLine($output);
    Console->WriteLine();
  } while ( $input->Key != ConsoleKey->Escape );
  return 0;
}

exit main();

__END__

=pod

The output from a sample console session might appear as follows:

  Press a key, together with Alt, Ctrl, or Shift.
  Press Esc to exit.
  You pressed D.

  Press a key, together with Alt, Ctrl, or Shift.
  Press Esc to exit.
  You pressed X, together with Shift.

  Press a key, together with Alt, Ctrl, or Shift.
  Press Esc to exit.
  You pressed L, together with Control and Shift.

  Press a key, together with Alt, Ctrl, or Shift.
  Press Esc to exit.
  You pressed P, together with Alt and Control and Shift.

  Press a key, together with Alt, Ctrl, or Shift.
  Press Esc to exit.
  You pressed Escape.

