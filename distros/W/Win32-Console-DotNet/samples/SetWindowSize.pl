# https://learn.microsoft.com/en-us/dotnet/api/system.console.windowheight?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.console.windowwidth?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.console.setwindowsize?view=net-8.0
# This example demonstrates the Console->SetWindowSize method,
#                           the Console->WindowWidth property,
#                       and the Console->WindowHeight property.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

sub main {
  my ($origWidth, $width);
  my ($origHeight, $height);
  my $m1 = "The current window width is %d, and the ".
           "current window height is %d.";
  my $m2 = "The new window width is %d, and the new ".
           "window height is %d.";
  my $m4 = "  (Press any key to continue...)";
  #
  # Step 1: Get the current window dimensions.
  #
  $origWidth  = Console->WindowWidth;
  $origHeight = Console->WindowHeight;
  Console->WriteLine($m1, Console->WindowWidth, Console->WindowHeight);
  Console->WriteLine($m4);
  Console->ReadKey(1);
  #
  # Step 2: Cut the window to 1/4 its original size.
  #
  $width  = int($origWidth/2);
  $height = int($origHeight/2);
  Console->SetWindowSize($width, $height);
  Console->WriteLine($m2, Console->WindowWidth, Console->WindowHeight);
  Console->WriteLine($m4);
  Console->ReadKey(1);
  #
  # Step 3: Restore the window to its original size.
  #
  Console->SetWindowSize($origWidth, $origHeight);
  Console->WriteLine($m1, Console->WindowWidth, Console->WindowHeight);
  return 0;
}

exit main();

__END__

=pod

This example produces the following results:

  The current window width is 85, and the current window height is 43.
    (Press any key to continue...)
  The new window width is 42, and the new window height is 21.
    (Press any key to continue...)
  The current window width is 85, and the current window height is 43.
