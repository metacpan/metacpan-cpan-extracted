# https://learn.microsoft.com/en-us/windows/console/scrolling-a-screen-buffer-s-window
# Scrolling a Screen Buffer's Window

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32;
use Win32API::Console qw(
  :Func
  :Struct
  :STD_HANDLE_
);

my $hStdout;

sub ScrollByAbsoluteCoord {
  my ($iRows) = @_;
  my $csbiInfo = CONSOLE_SCREEN_BUFFER_INFO;
  my $srctWindow = SMALL_RECT;

  # Get the current screen buffer size and window position.

  if (! GetConsoleScreenBufferInfo($hStdout, $csbiInfo))
  {
    printf("GetConsoleScreenBufferInfo (%d)\n", Win32::GetLastError());
    return 0;
  }

  # Set srctWindow to the current window size and location.

  %$srctWindow = %{ $csbiInfo->{srWindow} };

  # Check whether the window is too close to the screen buffer top

  if ( $srctWindow->{Top} >= $iRows )
  {
    $srctWindow->{Top} -= $iRows;     # move top up
    $srctWindow->{Bottom} -= $iRows;  # move bottom up

    if (! SetConsoleWindowInfo(
            $hStdout,          # screen buffer handle
            1,                 # absolute coordinates
            $srctWindow))      # specifies new location
    {
      printf("SetConsoleWindowInfo (%d)\n", Win32::GetLastError());
      return 0;
    }
    return $iRows;
  }
  else
  {
    print("\nCannot scroll; the window is too close to the top or run in a Terminal.\n");
    return 0;
  }
}

sub ScrollByRelativeCoord {
  my ($iRows) = @_;
  my $csbiInfo = CONSOLE_SCREEN_BUFFER_INFO;
  my $srctWindow = SMALL_RECT;

  # Get the current screen buffer window position.

  if (! GetConsoleScreenBufferInfo($hStdout, $csbiInfo))
  {
    printf("GetConsoleScreenBufferInfo (%d)\n", Win32::GetLastError());
    return 0;
  }

  # Check whether the window is too close to the screen buffer top

  if ($csbiInfo->{srWindow}{Top} >= $iRows)
  {
    $srctWindow->{Top} -= $iRows;     # move top up
    $srctWindow->{Bottom} -= $iRows;  # move bottom up
    $srctWindow->{Left} = 0;          # no change
    $srctWindow->{Right} = 0;         # no change

    if (! SetConsoleWindowInfo(
            $hStdout,         # screen buffer handle
            0,                # relative coordinates
            $srctWindow))     # specifies new location
    {
      printf("SetConsoleWindowInfo (%d)\n", Win32::GetLastError());
      return 0;
    }
    return $iRows;
  }
  else
  {
    print("\nCannot scroll; the window is too close to the top or run in a Terminal.\n");
    return 0;
  }
}

sub main {
  my $i;

  print("\nPrinting twenty lines, then scrolling up five lines.\n");
  print("Press any key to scroll up ten lines; ");
  print("then press another key to stop the demo.\n");
  for ($i = 0; $i <= 20; $i++) {
    printf("%d\n", $i);
  }
  $hStdout = GetStdHandle(STD_OUTPUT_HANDLE);

  if (ScrollByAbsoluteCoord(5)) {
    getc();
  } else { return 0; }

  if (ScrollByRelativeCoord(10)) {
    getc();
  } else { return 0; }
  0;
}

exit main();

__END__

=pod

This example scrolls the view of the console screen buffer up by modifying the 
window coordinates returned by the 
L<GetConsoleScreenBufferInfo|Win32API::Console/GetConsoleScreenBufferInfo> 
function. The C<ScrollByAbsoluteCoord> function demonstrates how to specify 
absolute coordinates, while the C<ScrollByRelativeCoord> function demonstrates 
how to specify relative coordinates.
