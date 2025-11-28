# https://learn.microsoft.com/en-us/windows/console/clearing-the-screen
# Clearing the Screen

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32;
use Win32API::Console qw(
  :Func
  :Struct
  :STD_HANDLE_
);

sub cls {
  my ($hConsole) = @_;
  my $coordScreen = COORD( 0, 0 );    # home for the cursor
  my $cCharsWritten;
  my $csbi = CONSOLE_SCREEN_BUFFER_INFO;
  my $dwConSize;

  # Get the number of character cells in the current buffer.
  if (!GetConsoleScreenBufferInfo($hConsole, $csbi))
  {
    return;
  }

  $dwConSize = $csbi->{dwSize}{X} * $csbi->{dwSize}{Y};

  # Fill the entire screen with blanks.
  if (!FillConsoleOutputCharacter(
                        $hConsole,        # Handle to console screen buffer
                        ' ',              # Character to write to the buffer
                        $dwConSize,       # Number of cells to write
                        $coordScreen,     # Coordinates of first cell
                        \$cCharsWritten)) # Receive number of characters written
  {
    return;
  }

  # Get the current text attribute.
  if (!GetConsoleScreenBufferInfo($hConsole, $csbi))
  {
    return;
  }

  # Set the buffer's attributes accordingly.
  if (!FillConsoleOutputAttribute(
                    $hConsole,            # Handle to console screen buffer
                    $csbi->{wAttributes}, # Character attributes to use
                    $dwConSize,           # Number of cells to set attribute
                    $coordScreen,         # Coordinates of first cell
                    \$cCharsWritten))     # Receive number of characters written
  {
    return;
  }

  # Put the cursor at its home coordinates.
  SetConsoleCursorPosition($hConsole, $coordScreen);
}

sub main
{
  my $hStdout;

  $hStdout = GetStdHandle(STD_OUTPUT_HANDLE);

  cls($hStdout);

  return 0;
}

exit main();

__END__

=pod

There are three ways to clear the screen in a console application.

The third method is to write a function to programmatically clear the screen 
using the 
L<FillConsoleOutputCharacter|Win32API::Console/FillConsoleOutputCharacter> and 
L<FillConsoleOutputAttribute|Win32API::Console/FillConsoleOutputAttribute>
functions.

This sample code demonstrates this technique.
