# https://learn.microsoft.com/en-us/dotnet/api/system.console.setbuffersize?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.console.setwindowposition?view=net-8.0
# https://learn.microsoft.com/en-us/dotnet/api/system.console.windowtop?view=net-8.0
# The following example demonstrates the WindowLeft, WindowTop, WindowWidth, 
# WindowHeight, BufferWidth, BufferHeight, and CursorVisible properties; and 
# the SetWindowPosition, SetBufferSize, and ReadKey methods. 

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

use constant TRUE => !! 1;
use constant FALSE => !! '';

my $saveBufferWidth;
my $saveBufferHeight;
my $saveWindowHeight;
my $saveWindowWidth;
my $saveCursorVisible;
#
sub main {
  my $m1 = "1) Press the cursor keys to move the console window.\n" .
           "2) Press any key to begin. When you're finished...\n" .
           "3) Press the Escape key to quit.";
  my $g1 = "+----";
  my $g2 = "|    ";
  my $grid1;
  my $grid2;
  my $sbG1 = '';
  my $sbG2 = '';
  my $cki;
  my $y;
  #
  try: eval {
    $saveBufferWidth  = Console->BufferWidth;
    $saveBufferHeight = Console->BufferHeight;
    $saveWindowHeight = Console->WindowHeight;
    $saveWindowWidth  = Console->WindowWidth;
    $saveCursorVisible = Console->CursorVisible;
    #
    Console->Clear();
    Console->WriteLine($m1);
    Console->ReadKey(TRUE);

    # Set the smallest possible window size before setting the buffer size.
    Console->SetWindowSize(1, 1);
    Console->SetBufferSize(80, 80);
    Console->SetWindowSize(40, 20);

    # Create grid lines to fit the buffer. (The buffer width is 80, but
    # this same technique could be used with an arbitrary buffer width.)
    for ($y = 0; $y < int(Console->BufferWidth/length($g1)); $y++) {
      $sbG1 .= $g1;
      $sbG2 .= $g2;
    }

    $sbG1 .= substr($g1, 0, Console->BufferWidth % length($g1));
    $sbG2 .= substr($g2, 0, Console->BufferWidth % length($g2));
    $grid1 = $sbG1;
    $grid2 = $sbG2;

    Console->CursorVisible(FALSE);
    Console->Clear();
    for ($y = 0; $y < Console->BufferHeight-1; $y++) {
      if ( $y%3 == 0 ) {
        Console->Write($grid1);
      } else {
        Console->Write($grid2);
      }
    }

    Console->SetWindowPosition(0, 0);
    do {
      $cki = Console->ReadKey(TRUE);
      switch: for ( $cki->Key ) {
        case: $_ == ConsoleKey->LeftArrow and do {
          if ( Console->WindowLeft > 0 ) {
            Console->SetWindowPosition(
              Console->WindowLeft-1, Console->WindowTop);
          }
          last;
        };
        case: $_ == ConsoleKey->UpArrow and do {
          if ( Console->WindowTop > 0 ) {
            Console->SetWindowPosition(
              Console->WindowLeft, Console->WindowTop-1);
          }
          last;
        };
        case: $_ ==  ConsoleKey->RightArrow and do {
          if ( Console->WindowLeft 
            < (Console->BufferWidth - Console->WindowWidth) 
          ) {
            Console->SetWindowPosition(
              Console->WindowLeft+1, Console->WindowTop);
          }
          last;
        };
        case: $_ ==  ConsoleKey->DownArrow and do {
          if ( Console->WindowTop 
            < (Console->BufferHeight - Console->WindowHeight)
          ) {
            Console->SetWindowPosition(
              Console->WindowLeft, Console->WindowTop+1);
          }
          last;
        };
      }
    } while ( $cki->Key != ConsoleKey->Escape ); # end do-while

  }; # end try
  catch: if ( $@ ) {
    Console->WriteLine( $@ );
  }
  finally: {
    Console->Clear();
    Console->SetWindowSize(1, 1);
    Console->SetBufferSize($saveBufferWidth, $saveBufferHeight);
    Console->SetWindowSize($saveWindowWidth, $saveWindowHeight);
    Console->CursorVisible($saveCursorVisible);
  }

  return 0;
}

exit main();

__END__

=pod

This example produces results similar to the following:

  1) Press the cursor keys to move the console window.
  2) Press any key to begin. When you're finished...
  3) Press the Escape key to quit.

  ...

  +----+----+----+-
  |    |    |    |
  |    |    |    |
  +----+----+----+-
  |    |    |    |
  |    |    |    |
  +----+----+----+-

