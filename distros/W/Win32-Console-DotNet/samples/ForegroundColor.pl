# https://learn.microsoft.com/en-us/dotnet/api/system.console.foregroundcolor?view=net-8.0
# The following example checks whether the console's background color is black 
# and, if it is, it changes the background color to red and the foreground color 
# to black.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  if ( Console->BackgroundColor == ConsoleColor->Black ) {
    Console->BackgroundColor( ConsoleColor->Red );
    Console->ForegroundColor( ConsoleColor->Black );
    Console->Clear();
  }
  return 0;
}

exit main();
