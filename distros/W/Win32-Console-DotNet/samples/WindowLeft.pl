# https://learn.microsoft.com/en-us/dotnet/api/system.console.windowleft?view=net-8.0
# This example demonstrates the Console->WindowLeft property.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  my $key;
  my $moved = 0;

  Console->BufferWidth(Console->BufferWidth + 4);
  Console->Clear();

  ShowConsoleStatistics();
  do {
    $key = Console->ReadKey(1);
    if ( $key->Key == ConsoleKey->LeftArrow ) {
      my $pos = Console->WindowLeft - 1;
      if ( $pos >= 0 && $pos + Console->WindowWidth <= Console->BufferWidth) {
        Console->WindowLeft( $pos );
        $moved = 1;
      }
    } elsif ( $key->Key == ConsoleKey->RightArrow ) {
      my $pos = Console->WindowLeft + 1;
      if ( $pos + Console->WindowWidth <= Console->BufferWidth ) {
        Console->WindowLeft( $pos );
        $moved = 1;
      }
    }
    if ( $moved ) {
      ShowConsoleStatistics();
      $moved = 0;
    }
    Console->WriteLine();
  } while (1);
  return 0;
}

sub ShowConsoleStatistics {
  Console->WriteLine("Console statistics:");
  Console->WriteLine("   Buffer: %d x %d", Console->BufferHeight, 
    Console->BufferWidth);
  Console->WriteLine("   Window: %d x %d", Console->WindowHeight, 
    Console->WindowWidth);
  Console->WriteLine("   Window starts at %d.", Console->WindowLeft);
  Console->WriteLine("Press <- or -> to move window, Ctrl+C to exit.");
}

exit main();

__END__

=pod

The following example opens an 80-column console window and defines a buffer 
area that is 120 columns wide. It displays information on window and buffer 
size, and then waits for the user to press either the LEFT ARROW key or the 
RIGHT ARROW key. In the former case, it decrements the value of the 
C<WindowLeft> property by one if the result is a legal value. In the latter 
case, it increases the value of the C<WindowLeft> property by one if the result 
would be legal. Note that the example does not have to handle an 
C<ArgumentOutOfRangeException>, because it checks that the value to be assigned 
to the C<WindowLeft> property is not negative and does not cause the sum of the 
C<WindowLeft> and C<WindowWidth> properties to exceed the BufferWidth property 
value.
