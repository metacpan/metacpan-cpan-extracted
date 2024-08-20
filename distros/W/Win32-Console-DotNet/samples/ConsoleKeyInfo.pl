# https://learn.microsoft.com/en-us/dotnet/api/system.console.treatcontrolcasinput?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.consolekeyinfo?view=net-9.0
# https://learn.microsoft.com/en-us/dotnet/api/system.console.readkey?view=net-8.0
# The following example uses the ReadKey() method to display information about 
# which key the user pressed and demonstrates using a ConsoleKeyInfo object in 
# a read operation.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  my $cki;
  # Prevent example from ending if CTL+C is pressed.
  Console->TreatControlCAsInput(1);

  Console->WriteLine("Press any combination of CTL, ALT, and SHIFT, and a " . 
    "console key.");
  Console->WriteLine("Press the Escape (Esc) key to quit: \n");
  do {
    $cki = Console->ReadKey();
    Console->Write(" --- You pressed ");
    Console->Write("ALT+") if $cki->Modifiers & ConsoleModifiers->Alt;
    Console->Write("SHIFT+") if $cki->Modifiers & ConsoleModifiers->Shift;
    Console->Write("CTL+") if $cki->Modifiers & ConsoleModifiers->Control;
    Console->WriteLine(ConsoleKey->get($cki->Key));
  } while ( $cki->Key != ConsoleKey->Escape );
  return 0;
}

exit main();

__END__

=pod

This example displays output similar to the following:

  Press any combination of CTL, ALT, and SHIFT, and a console key.
  Press the Escape (Esc) key to quit:

  a --- You pressed A
  k --- You pressed ALT+K
  ► --- You pressed CTL+P
    --- You pressed RightArrow
  R --- You pressed SHIFT+R
            --- You pressed CTL+I
  j --- You pressed ALT+J
  O --- You pressed SHIFT+O
  § --- You pressed CTL+U
