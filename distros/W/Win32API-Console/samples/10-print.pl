# https://10print.org/
# Implementation of the BASIC one-liner "10 PRINT" from the Commodore 64.

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32;
use Win32API::Console qw(
  :Func
  WriteConsoleW
  CONSOLE_SCREEN_BUFFER_INFO
  :CTRL_EVENT_
  :FOREGROUND_
  :OUTPUT_MODE_
  BACKGROUND_BLUE
  STD_OUTPUT_HANDLE
);

sub Defer::DESTROY { ${$_[0]}->() }

END { warn "$^E\n" if $^E }

sub main {
  # Get a STDOUT console handle
  my $hConsole = GetStdHandle(STD_OUTPUT_HANDLE)
    or return Win32::GetLastError();

  # Intro message
  my $written = 0;
  WriteConsole($hConsole, 
    "'10 PRINT CHR$(205.5+RND(1)); : GOTO 10' -> CTRL-C for exit\n", \$written)
      or return Win32::GetLastError();

  # Inner scope for 'defer'
  {
    # Save original attributes
    my $csbi = CONSOLE_SCREEN_BUFFER_INFO ;
    GetConsoleScreenBufferInfo($hConsole, $csbi) 
      or return Win32::GetLastError();
    my $origAttr = $csbi->{wAttributes};

    # Defer code for resetting the colors to the end of the scope
    my $resetColors = bless \sub { local $^E;
      SetConsoleTextAttribute($hConsole, $origAttr) } => 'Defer';

    # Set colors: blue background, light blue characters
    my $c64attr = BACKGROUND_BLUE 
      | FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_INTENSITY;

    SetConsoleTextAttribute($hConsole, $c64attr)
      or return Win32::GetLastError();

    # Get the current console mode
    my $mode = 0;
    GetConsoleMode($hConsole, \$mode) 
      or return Win32::GetLastError();
    my $originalMode = $mode;

    # Defer code for restore the console mode to the end of scope
    my $restoreMode = bless \sub { local $^E;
      SetConsoleMode($hConsole, $originalMode) } => 'Defer';

    # Set console mode: Wrap + Processed Output
    $mode |= ENABLE_PROCESSED_OUTPUT | ENABLE_WRAP_AT_EOL_OUTPUT;
    SetConsoleMode($hConsole, $mode) 
      or return Win32::GetLastError();

    # Set Ctrl handler for termination
    my $run = 1;  # abort flag
    my $ctrlHandler = sub {
      my ($type) = @_;
      return 0 unless $type == CTRL_C_EVENT;
      $run = 0;
      return 1;
    };
    SetConsoleCtrlHandler($ctrlHandler, 1) 
      or return Win32::GetLastError();

    # Defer code for remove the Ctrl handler to the end of scope
    my $removeHandler = bless \sub { local $^E;
      SetConsoleCtrlHandler(undef, 0) } => 'Defer';

    # Main loop uses Unicode slashes / (U+2571) and \ (U+2572)
    _10_PRINT:
      $run &&= WriteConsoleW($hConsole, pack('v', 9585.5 + rand), \$written);
      Win32::Sleep(1);  # Should grow slowly
      goto _10_PRINT if $run;
  }

  # Outro message
  WriteConsole($hConsole, "\nDone, check out '10print.org'.\n", \$written);

  return 0;
}

exit main(); 

__END__

=pod

Our Windows Console version of C64 Code Art: 

  10 PRINT CHR$(205.5+RND(1)); : GOTO 10

B<See>: L<http://10print.org/> for further information.
