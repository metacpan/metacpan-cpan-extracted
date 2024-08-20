# https://learn.microsoft.com/en-us/dotnet/api/system.console.keyavailable?view=net-8.0
# The following example demonstrates how to use the KeyAvailable property to 
# create a loop that runs until a key is pressed.

use 5.014;
use warnings;
use Time::HiRes;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  my $cki;

  do {
    Console->WriteLine("\nPress a key to display; press the 'x' key to quit.");

    # Your code could perform some useful task in the following loop. However,
    # for the sake of this example we'll merely pause for a quarter second.

    while ( ! Console->KeyAvailable ) {
      Time::HiRes::sleep(250/1000); # Loop until input is entered.
    }

    $cki = Console->ReadKey(1);
    Console->WriteLine("You pressed the '%s' key.", 
      ConsoleKey->get($cki->Key));
  } while($cki->Key != ConsoleKey->X);
  return 0;
}

exit main();

__END__

=pod

This example produces results similar to the following:

  Press a key to display; press the 'x' key to quit.
  You pressed the 'H' key.

  Press a key to display; press the 'x' key to quit.
  You pressed the 'E' key.

  Press a key to display; press the 'x' key to quit.
  You pressed the 'PageUp' key.

  Press a key to display; press the 'x' key to quit.
  You pressed the 'DownArrow' key.

  Press a key to display; press the 'x' key to quit.
  You pressed the 'X' key.
