# https://learn.microsoft.com/en-us/windows/console/reading-input-buffer-events
# Reading Input Buffer Events

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32;
use Win32API::Console qw(
  :Func
  :Misc
  :Struct
  :BUTTON_PRESSED_
  :EVENT_TYPE_
  :INPUT_MODE_
  :MOUSE_
  :STD_HANDLE_
);

my $hStdin;
my $fdwSaveOldMode;

sub ErrorExit;
sub KeyEventProc;
sub MouseEventProc;
sub ResizeEventProc;

sub main {
  my ($cNumRead, $fdwMode, $i);
  my $irInBuf = {};
  my $counter = 0;

  # Get the standard input handle.

  $hStdin = GetStdHandle(STD_INPUT_HANDLE);
  if ($hStdin == INVALID_HANDLE_VALUE) {
    ErrorExit("GetStdHandle");
  }

  # Save the current input mode, to be restored on exit.

  if (! GetConsoleMode($hStdin, \$fdwSaveOldMode) ) {
    ErrorExit("GetConsoleMode");
  }

  # Enable the window and mouse input events.
  # Disable quick edit mode because it interferes with receiving mouse inputs.

  $fdwMode = (ENABLE_WINDOW_INPUT | ENABLE_MOUSE_INPUT | ENABLE_EXTENDED_FLAGS) 
    & ~ENABLE_QUICK_EDIT_MODE;
  if (! SetConsoleMode($hStdin, $fdwMode) ) {
    ErrorExit("SetConsoleMode");
  }

  # Loop to read and handle the next 100 input events.

  while ($counter++ <= 100)
  {
    # Wait for the events.

    if (! ReadConsoleInput(
            $hStdin,      # input buffer handle
            $irInBuf) )  # buffer to read into
      { ErrorExit("ReadConsoleInput"); }

    SWITCH: for ($irInBuf->{EventType})
    {
      KEY_EVENT == $_ and do { # keyboard input
        KeyEventProc($irInBuf->{Event});
        last;
      };
      MOUSE_EVENT == $_ and do { # mouse input
        MouseEventProc($irInBuf->{Event});
        last;
      };
      WINDOW_BUFFER_SIZE_EVENT == $_ and do { # scrn buf. resizing
        ResizeEventProc($irInBuf->{Event});
        last;
      };
      FOCUS_EVENT == $_ # disregard focus events
        ||
      MENU_EVENT == $_ and # disregard menu events
        last;

      DEFAULT: {
        ErrorExit("Unknown event type");
        last;
      }
    }
  }

  # Restore input mode on exit.

  SetConsoleMode($hStdin, $fdwSaveOldMode);

  return 0;
}

sub ErrorExit {
  my ($lpszMessage) = @_;
  printf(STDERR "%s\n", $lpszMessage);

  # Restore input mode on exit.

  SetConsoleMode($hStdin, $fdwSaveOldMode);

  exit(0);
}

sub KeyEventProc {
  my ($ker) = @_;
  print("Key event: ");

  if ($ker->{bKeyDown}) {
    print("key pressed\n");
  } else {
    print("key released\n");
  }
}

sub MouseEventProc {
  my ($mer) = @_;
  printf("Mouse event: ");

  SWITCH: for ($mer->{dwEventFlags})
  {
    0 == $_ and do {

      if ($mer->{dwButtonState} == FROM_LEFT_1ST_BUTTON_PRESSED)
      {
        print("left button press \n");
      }
      elsif ($mer->{dwButtonState} == RIGHTMOST_BUTTON_PRESSED)
      {
        print("right button press \n");
      }
      else
      {
        print("button press\n");
      }
      last;
    };
    DOUBLE_CLICK == $_ and do {
      print("double click\n");
      last;
    };
    MOUSE_HWHEELED == $_ and do {
      print("horizontal mouse wheel\n");
      last;
    };
    MOUSE_MOVED == $_ and do {
      print("mouse moved\n");
      last;
    };
    MOUSE_WHEELED == $_ and do {
      print("vertical mouse wheel\n");
      last;
    };
    DEFAULT: {
      print("unknown\n");
      last;
    }
  }
}

sub ResizeEventProc {
  my ($wbsr) = @_;
  print("Resize event\n");
  printf("Console screen buffer is %d columns by %d rows.\n", 
    $wbsr->{dwSize}{X}, $wbsr->{dwSize}{Y});
}

exit main();

__END__

=pod

The L<ReadConsoleInput|Win32API::Console/ReadConsoleInput> function can be used 
to directly access a console's input buffer. When a console is created, mouse 
input is enabled and window input is disabled. To ensure that the process 
receives all types of events, this example uses the 
L<SetConsoleMode|Win32API::Console/SetConsoleMode> function to enable window 
and mouse input. Then it goes into a loop that reads and handles 100 console 
input events. For example, the message "Keyboard event" is displayed when the 
user presses a key and the message "Mouse event" is displayed when the user 
interacts with the mouse.
