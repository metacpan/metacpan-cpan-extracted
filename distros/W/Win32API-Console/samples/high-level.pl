# https://learn.microsoft.com/en-us/windows/console/using-the-high-level-input-and-output-functions
# Using the High-Level Input and Output Functions

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32;
use Win32API::Console qw(
  :Func
  :Misc
  :Struct
  :FOREGROUND_
  :INPUT_MODE_
  :STD_HANDLE_
);
use Win32API::File qw(
  ReadFile
  WriteFile
);
use constant MB_OK => 0;

my ($hStdout, $hStdin);
my $csbiInfo = CONSOLE_SCREEN_BUFFER_INFO;

sub NewLine;
sub ScrollScreenBuffer;

sub main {
  my $lpszPrompt1 = "Type a line and press Enter, or q to quit: ";
  my $lpszPrompt2 = "Type any key, or q to quit: ";
  my $chBuffer = "\0" x 256;
  my ($cRead, $cWritten, $fdwMode, $fdwOldMode);
  my $wOldColorAttrs;

  # Get handles to STDIN and STDOUT.

  $hStdout = GetStdHandle(STD_OUTPUT_HANDLE);
  $hStdin  = GetStdHandle(STD_INPUT_HANDLE);
  if ($hStdin == INVALID_HANDLE_VALUE || 
      $hStdout == INVALID_HANDLE_VALUE)
  {
    Win32::MsgBox("GetStdHandle", "Console Error", 
      MB_OK);
    return 1;
  }

  # Save the current text colors.

  if (! GetConsoleScreenBufferInfo($hStdout, $csbiInfo) ) {
    Win32::MsgBox("GetConsoleScreenBufferInfo", 
      "Console Error", MB_OK);
    return 1;
  }

  $wOldColorAttrs = $csbiInfo->{wAttributes};

  # Set the text attributes to draw red text on black background.
  if (! SetConsoleTextAttribute($hStdout, FOREGROUND_RED |
          FOREGROUND_INTENSITY))
  {
    Win32::MsgBox("SetConsoleTextAttribute", 
      "Console Error", MB_OK);
    return 1;
  }

  # Write to STDOUT and read from STDIN by using the default
  # modes. Input is echoed automatically, and ReadFile
  # does not return until a carriage return is typed.
  #
  # The default input modes are line, processed, and echo.
  # The default output modes are processed and wrap at EOL.

  while (1) 
  {
    if (! WriteFile(
      $hStdout,               # output handle
      $lpszPrompt1,           # prompt string
      length($lpszPrompt1),   # string length
      $cWritten = 0,          # bytes written
      []) )                   # not overlapped
    {
      Win32::MsgBox("WriteFile", "Console Error",
        MB_OK);
      return 1;
    }

    if (! ReadFile(
      $hStdin,                # input handle
      $chBuffer = "\0" x 256, # buffer to read into
      256,                    # size of buffer
      $cRead = 0,             # actual bytes read
      []) )                   # not overlapped
    { 
      last; 
    }

    last if substr($chBuffer, 0, 1) eq 'q';
  }

  # Turn off the line input and echo input modes

  if (! GetConsoleMode($hStdin, \$fdwOldMode))
  {
    Win32::MsgBox("GetConsoleMode", "Console Error",
      MB_OK);
    return 1;
  }    

  $fdwMode = $fdwOldMode &
    ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT);
  if (! SetConsoleMode($hStdin, $fdwMode))
  {
    Win32::MsgBox("SetConsoleMode", "Console Error",
      MB_OK);
    return 1;
  }

  # ReadFile returns when any input is available.  
  # WriteFile is used to echo input.

  NewLine();

  while (1) {
    if (! WriteFile(
      $hStdout,               # output handle
      $lpszPrompt2,           # prompt string
      length($lpszPrompt2),   # string length
      $cWritten = 0,          # bytes written
      []) )                   # not overlapped
    {
      Win32::MsgBox("WriteFile", "Console Error",
        MB_OK);
      return 1;
    }

    if (! ReadFile($hStdin, $chBuffer = "\0", 1, $cRead = 0, [])) {
      last;
    }
    if (substr($chBuffer, 0, 1) eq "\r" ) {
      NewLine(); 
    } elsif ( ! WriteFile($hStdout, $chBuffer, $cRead, $cWritten = 0, [])) {
      last; 
    } else { 
      NewLine(); 
    }
    last if substr($chBuffer, 0, 1) eq 'q';
  }

  # Restore the original console mode.

  SetConsoleMode($hStdin, $fdwOldMode);

  # Restore the original text colors.

  SetConsoleTextAttribute($hStdout, $wOldColorAttrs);

  return 0;
}

# The NewLine function handles carriage returns when the processed
# input mode is disabled. It gets the current cursor position
# and resets it to the first cell of the next row.

sub NewLine {
  if (! GetConsoleScreenBufferInfo($hStdout, $csbiInfo))
  {
    Win32::MsgBox("GetConsoleScreenBufferInfo", 
      "Console Error", MB_OK);
    return;
  }

  $csbiInfo->{dwCursorPosition}{X} = 0;

  # If it is the last line in the screen buffer, scroll
  # the buffer up.

  if ($csbiInfo->{dwSize}{Y}-1 == $csbiInfo->{dwCursorPosition}{Y})
  {
    ScrollScreenBuffer($hStdout, 1);
  }

  # Otherwise, advance the cursor to the next line.

  else { $csbiInfo->{dwCursorPosition}{Y} += 1; }

  if (! SetConsoleCursorPosition($hStdout, 
    $csbiInfo->{dwCursorPosition}))
  {
    Win32::MsgBox("SetConsoleCursorPosition", 
      "Console Error", MB_OK);
    return;
  }
}

sub ScrollScreenBuffer {
  my ($h, $x) = @_;
  my ($srctScrollRect, $srctClipRect) = (SMALL_RECT, SMALL_RECT);
  my $chiFill = CHAR_INFO;
  my $coordDest = COORD;

  $srctScrollRect->{Left} = 0;
  $srctScrollRect->{Top} = 1;
  $srctScrollRect->{Right} = $csbiInfo->{dwSize}{X} - $x;
  $srctScrollRect->{Bottom} = $csbiInfo->{dwSize}{Y} - $x;

  # The destination for the scroll rectangle is one row up.

  $coordDest->{X} = 0;
  $coordDest->{Y} = 0;

  # The clipping rectangle is the same as the scrolling rectangle.
  # The destination row is left unchanged.

  %$srctClipRect = %$srctScrollRect;

  # Set the fill character and attributes.

  $chiFill->{Attributes} = FOREGROUND_RED|FOREGROUND_INTENSITY;
  $chiFill->{Char} = ord(' ');

  # Scroll up one line.

  ScrollConsoleScreenBuffer(
    $h,               # screen buffer handle
    $srctScrollRect,  # scrolling rectangle
    $srctClipRect,    # clipping rectangle
    $coordDest,       # top left destination cell
    $chiFill);        # fill character and color
}

exit main();

__END__

=pod

The example assumes that the default I/O modes are in effect initially for the 
first calls to the L<ReadFile|Win32API::File/ReadFile> and 
L<WriteFile|Win32API::File/WriteFile> functions. Then the input mode is changed 
to turn offline input mode and echo input mode for the second calls 
to C<ReadFile> and C<WriteFile>. The 
L<SetConsoleTextAttribute|Win32API::Console/SetConsoleTextAttribute> function 
is used to set the colors in which subsequently written text will be displayed. 
Before exiting, the program restores the original console input mode and color 
attributes.
