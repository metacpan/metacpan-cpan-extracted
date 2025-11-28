# https://learn.microsoft.com/en-us/windows/console/scrolling-a-screen-buffer-s-contents
# Scrolling a Screen Buffer's Contents

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32;
use Win32API::Console qw(
  :Func
  :Misc
  :Struct
  :BACKGROUND_
  :FOREGROUND_
  :STD_HANDLE_
);

sub main {
  my $hStdout;
  my $csbiInfo = CONSOLE_SCREEN_BUFFER_INFO;
  my ($srctScrollRect, $srctClipRect) = (SMALL_RECT, SMALL_RECT);
  my $chiFill = CHAR_INFO;
  my $coordDest = COORD;
  my $i;

  print("\nPrinting 20 lines for reference. ");
  print("Notice that line 6 is discarded during scrolling.\n");
  for ($i = 0; $i <= 20; $i++) {
    printf("%d\n", $i);
  }
  $hStdout = GetStdHandle(STD_OUTPUT_HANDLE);

  if ($hStdout == INVALID_HANDLE_VALUE)
  {
    printf("GetStdHandle failed with %d\n", Win32::GetLastError());
    return 1;
  }

  # Get the screen buffer size.

  if (!GetConsoleScreenBufferInfo($hStdout, $csbiInfo))
  {
    printf("GetConsoleScreenBufferInfo failed %d\n", Win32::GetLastError());
    return 1;
  }

  # The scrolling rectangle is the bottom 15 rows of the
  # screen buffer.

  $srctScrollRect->{Top} = $csbiInfo->{dwSize}{Y} - 16;
  $srctScrollRect->{Bottom} = $csbiInfo->{dwSize}{Y} - 1;
  $srctScrollRect->{Left} = 0;
  $srctScrollRect->{Right} = $csbiInfo->{dwSize}{X} - 1;

  # The destination for the scroll rectangle is one row up.

  $coordDest->{X} = 0;
  $coordDest->{Y} = $csbiInfo->{dwSize}{Y} - 17;

  # The clipping rectangle is the same as the scrolling rectangle.
  # The destination row is left unchanged.

  %$srctClipRect = %$srctScrollRect;

  # Fill the bottom row with green blanks.

  $chiFill->{Attributes} = BACKGROUND_GREEN | FOREGROUND_RED;
  $chiFill->{Char} = ord(' ');

  # Scroll up one line.

  if(!ScrollConsoleScreenBuffer(  
    $hStdout,        # screen buffer handle
    $srctScrollRect, # scrolling rectangle
    $srctClipRect,   # clipping rectangle
    $coordDest,      # top left destination cell
    $chiFill))       # fill character and color
  {
    printf("ScrollConsoleScreenBuffer failed %d\n", Win32::GetLastError());
    return 1;
  }

  # Restore the original text colors.

  SetConsoleTextAttribute($hStdout, $csbiInfo->{wAttributes});

  return 0;
}

exit main();

__END__

=pod

This example shows the use of a clipping rectangle to scroll only the bottom 
15 rows of the console screen buffer. The rows in the specified rectangle are 
scrolled up one line at a time, and the top row of the block is discarded. The 
contents of the console screen buffer outside the clipping rectangle are left 
unchanged.
