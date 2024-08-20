# https://learn.microsoft.com/en-us/dotnet/api/system.console.clear?view=net-9.0
# This example demonstrates the
#     Console->CursorLeft and
#     Console->CursorTop properties, and the
#     Console->SetCursorPosition and
#     Console->Clear methods.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

my $origRow;
my $origCol;

sub WriteAt { # void ($s, $x, $y)
  my ($s, $x, $y) = @_;
  try: eval {
    Console->SetCursorPosition($origCol+$x, $origRow+$y);
    Console->Write($s);
  };
  catch: if ( $@ && $@ =~ /ArgumentOutOfRangeException/ ) {
    Console->Clear();
    Console->WriteLine($@);
  }
  return;
}

sub main {
  # Clear the screen, then save the top and left coordinates.
  Console->Clear();
  $origRow = Console->CursorTop;
  $origCol = Console->CursorLeft;

  # Draw the left side of a 5x5 rectangle, from top to bottom.
  WriteAt("+", 0, 0);
  WriteAt("|", 0, 1);
  WriteAt("|", 0, 2);
  WriteAt("|", 0, 3);
  WriteAt("+", 0, 4);

  # Draw the bottom side, from left to right.
  WriteAt("-", 1, 4); # shortcut: WriteAt("---", 1, 4)
  WriteAt("-", 2, 4); # ...
  WriteAt("-", 3, 4); # ...
  WriteAt("+", 4, 4);

  # Draw the right side, from bottom to top.
  WriteAt("|", 4, 3);
  WriteAt("|", 4, 2);
  WriteAt("|", 4, 1);
  WriteAt("+", 4, 0);

  # Draw the top side, from right to left.
  WriteAt("-", 3, 0); # shortcut: WriteAt("---", 1, 0)
  WriteAt("-", 2, 0); # ...
  WriteAt("-", 1, 0); # ...
  #
  WriteAt("All done!", 0, 6);
  Console->WriteLine();
  return 0;
}

exit main();

__END__

=pod

This example produces the following results:

  +---+
  |   |
  |   |
  |   |
  +---+

  All done!

