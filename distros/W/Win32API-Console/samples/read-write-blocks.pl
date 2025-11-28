# https://learn.microsoft.com/en-us/windows/console/reading-and-writing-blocks-of-characters-and-attributes
# Reading and Writing Blocks of Characters and Attributes

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32;
use Win32API::Console qw(
  :Func
  :Misc
  :Struct
  :FILE_SHARE_
  :GENERIC_
  :INPUT_MODE_
  :STD_HANDLE_
);

sub main {
  my ($hStdout, $hNewScreenBuffer);
  my $srctReadRect  = SMALL_RECT;
  my $srctWriteRect = SMALL_RECT;
  my $chiBuffer     = pack('L*', (0) x 160);    # [2][80];
  my $coordBufSize  = COORD;
  my $coordBufCoord = COORD;
  my $fSuccess;

  # Get a handle to the STDOUT screen buffer to copy from and
  # create a new screen buffer to copy to.

  $hStdout = GetStdHandle(STD_OUTPUT_HANDLE);
  $hNewScreenBuffer = CreateConsoleScreenBuffer(
    GENERIC_READ |           # read/write access
    GENERIC_WRITE,
    FILE_SHARE_READ |
    FILE_SHARE_WRITE);       # shared
  if ($hStdout == INVALID_HANDLE_VALUE ||
      $hNewScreenBuffer == INVALID_HANDLE_VALUE)
  {
    printf("CreateConsoleScreenBuffer failed - (%d)\n", Win32::GetLastError());
    return 1;
  }

  # Make the new screen buffer the active screen buffer.

  if (! SetConsoleActiveScreenBuffer($hNewScreenBuffer) )
  {
    printf("SetConsoleActiveScreenBuffer failed - (%d)\n", 
      Win32::GetLastError());
    return 1;
  }

  # Set the source rectangle.

  $srctReadRect->{Top} = 0;    # top left: row 0, col 0
  $srctReadRect->{Left} = 0;
  $srctReadRect->{Bottom} = 1; # bot. right: row 1, col 79
  $srctReadRect->{Right} = 79;

  # The temporary buffer size is 2 rows x 80 columns.

  $coordBufSize->{Y} = 2;
  $coordBufSize->{X} = 80;

  # The top left destination cell of the temporary buffer is
  # row 0, col 0.

  $coordBufCoord->{X} = 0;
  $coordBufCoord->{Y} = 0;

  # Copy the block from the screen buffer to the temp. buffer.

  $fSuccess = ReadConsoleOutput(
    $hStdout,        # screen buffer to read from
    \$chiBuffer,     # buffer to copy into
    $coordBufSize,   # col-row size of chiBuffer
    $coordBufCoord,  # top left dest. cell in chiBuffer
    $srctReadRect);  # screen buffer source rectangle
  if (! $fSuccess)
  {
    printf("ReadConsoleOutput failed - (%d)\n", Win32::GetLastError());
    return 1;
  }

  # Set the destination rectangle.

  $srctWriteRect->{Top} = 10;    # top lt: row 10, col 0
  $srctWriteRect->{Left} = 0;
  $srctWriteRect->{Bottom} = 11; # bot. rt: row 11, col 79
  $srctWriteRect->{Right} = 79;

  # Copy from the temporary buffer to the new screen buffer.

  $fSuccess = WriteConsoleOutput(
    $hNewScreenBuffer, # screen buffer to write to
    $chiBuffer,        # buffer to copy from
    $coordBufSize,     # col-row size of chiBuffer
    $coordBufCoord,    # top left src cell in chiBuffer
    $srctWriteRect);   # dest. screen buffer rectangle
  if (! $fSuccess)
  {
    printf("WriteConsoleOutput failed - (%d)\n", Win32::GetLastError());
    return 1;
  }
  Win32::Sleep(5000);

  # Restore the original active screen buffer.

  if (! SetConsoleActiveScreenBuffer($hStdout))
  {
    printf("SetConsoleActiveScreenBuffer failed - (%d)\n", 
      Win32::GetLastError());
    return 1;
  }

  return 0;
}

exit main();

__END__

=pod

The following example uses the 
L<CreateConsoleScreenBuffer|Win32API::Console/CreateConsoleScreenBuffer> 
function to create a new screen buffer. After the 
L<SetConsoleActiveScreenBuffer|Win32API::Console/SetConsoleActiveScreenBuffer> 
function makes this the active screen buffer, a block of characters and color 
attributes is copied from the top two rows of the STDOUT screen buffer into a 
temporary buffer. The data is then copied from the temporary buffer into the 
new active screen buffer. When the application is finished using the new screen 
buffer, it calls C<SetConsoleActiveScreenBuffer> to restore the original STDOUT 
screen buffer.
