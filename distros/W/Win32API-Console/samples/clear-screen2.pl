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
  my $csbi = CONSOLE_SCREEN_BUFFER_INFO;
  my $scrollRect = SMALL_RECT;
  my $scrollTarget = COORD;
  my $fill = CHAR_INFO;

  # Get the number of character cells in the current buffer.
  if (!GetConsoleScreenBufferInfo($hConsole, $csbi))
  {
    return;
  }

  # Scroll the rectangle of the entire buffer.
  $scrollRect->{Left} = 0;
  $scrollRect->{Top} = 0;
  $scrollRect->{Right} = $csbi->{dwSize}{X};
  $scrollRect->{Bottom} = $csbi->{dwSize}{Y};

  # Scroll it upwards off the top of the buffer with a magnitude of the entire 
  # height.
  $scrollTarget->{X} = 0;
  $scrollTarget->{Y} = 0 - $csbi->{dwSize}{Y};

  # Fill with empty spaces with the buffer's default text attribute.
  $fill->{Char} = ord(' ');
  $fill->{Attributes} = $csbi->{wAttributes};

  # Do the scroll
  ScrollConsoleScreenBuffer($hConsole, $scrollRect, undef, $scrollTarget, 
    $fill);

  # Move the cursor to the top left corner too.
  $csbi->{dwCursorPosition}{X} = 0;
  $csbi->{dwCursorPosition}{Y} = 0;

  SetConsoleCursorPosition($hConsole, $csbi->{dwCursorPosition});
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

The second method is to write a function to scroll the contents of the screen 
or buffer and set a fill for the revealed space.

This matches the behavior of the command prompt C<cmd.exe>.
