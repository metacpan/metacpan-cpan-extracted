# https://learn.microsoft.com/en-us/dotnet/api/system.console.backgroundcolor?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.console.foregroundcolor?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.console.resetcolor?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.consolecolor?view=net-8.0
# The following example saves the values of the ConsoleColor enumeration to an 
# array and stores the current values of the BackgroundColor and ForegroundColor 
# properties to variables. It also demonstrates the ResetColor method.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  # Get an array with the values of ConsoleColor enumeration members.
  my @colors = ConsoleColor->values();
  # Save the current background and foreground colors.
  my $currentBackground = Console->BackgroundColor;
  my $currentForeground = Console->ForegroundColor;

  # Display all foreground colors except the one that matches the background.
  Console->WriteLine("All the foreground colors except %s, the background " . 
    "color:", ConsoleColor->get($currentBackground));
  foreach my $color (@colors) {
    next if $color == $currentBackground;

    Console->ForegroundColor($color);
    Console->WriteLine("   The foreground color is %s.", 
      ConsoleColor->get($color));
  }
  Console->WriteLine();
  # Restore the foreground color.
  Console->ForegroundColor($currentForeground);

  # Display each background color except the one that matches the current 
  # foreground color.
  Console->WriteLine("All the background colors except %s, the foreground " . 
    "color:", ConsoleColor->get($currentForeground));
  foreach my $color (@colors) {
    next if $color == $currentForeground;

    Console->BackgroundColor($color);
    Console->WriteLine("   The background color is %s.", 
      ConsoleColor->get($color));
  }

  # Restore the original console colors.
  Console->ResetColor();
  Console->WriteLine("\nOriginal colors restored...");
  return 0;
}

exit main();

__END__

=pod

The example displays output like the following:

  All the foreground colors except DarkCyan, the background color:
      The foreground color is Black.
      The foreground color is DarkBlue.
      The foreground color is DarkGreen.
      The foreground color is DarkRed.
      The foreground color is DarkMagenta.
      The foreground color is DarkYellow.
      The foreground color is Gray.
      The foreground color is DarkGray.
      The foreground color is Blue.
      The foreground color is Green.
      The foreground color is Cyan.
      The foreground color is Red.
      The foreground color is Magenta.
      The foreground color is Yellow.
      The foreground color is White.

  All the background colors except White, the foreground color:
      The background color is Black.
      The background color is DarkBlue.
      The background color is DarkGreen.
      The background color is DarkCyan.
      The background color is DarkRed.
      The background color is DarkMagenta.
      The background color is DarkYellow.
      The background color is Gray.
      The background color is DarkGray.
      The background color is Blue.
      The background color is Green.
      The background color is Cyan.
      The background color is Red.
      The background color is Magenta.
      The background color is Yellow.

  Original colors restored...
