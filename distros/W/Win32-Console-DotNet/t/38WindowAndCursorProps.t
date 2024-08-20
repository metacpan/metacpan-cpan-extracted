# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/WindowAndCursorProps.cs
# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.
use 5.014;
use warnings;

use Test::More tests => 53;
use Test::Exception;

use IPC::Open3;
use Perl::OSType qw( :all );
use POSIX;
use Symbol qw( gensym );

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'System';
  use_ok 'ConsoleColor';
}

BEGIN {
  if ( eval { require Win32::Console } ) {
    our $title = Win32::Console::_GetConsoleTitle();
  }
}
END {
  our $title;
  if ( eval { require Win32::Console } ) {
    Win32::Console::_SetConsoleTitle($title) if defined $title;
  }
}

# Fix STDOUT redirection from prove
POSIX::dup2(fileno(STDERR), fileno(STDOUT));

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix') 
  && os_type ne 'iphoneos'; 
# Expected behavior specific to Unix
subtest 'BufferWidth_GetUnix_ReturnsWindowWidth' => sub {
  plan tests => 1;
  is Console->WindowWidth, Console->BufferWidth, 'Equal';
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
# Expected behavior specific to Unix
subtest 'BufferWidth_SetUnix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->BufferWidth(1) } qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix') 
  && os_type ne 'iphoneos'; 
# Expected behavior specific to Unix
subtest 'BufferHeight_GetUnix_ReturnsWindowHeight' => sub {
  plan tests => 1;
  is Console->WindowHeight, Console->BufferHeight, 'Equal';
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
# Expected behavior specific to Unix
subtest 'BufferHeight_SetUnix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->BufferHeight(1) } qr/PlatformNotSupportedException/;
}}

SKIP: {skip 'Platform specific', 1 unless is_os_type('Unix');
# Expected behavior specific to Unix
subtest 'SetBufferSize_Unix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->SetBufferSize(0, 0) } qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows') 
  || is_os_type('Unix') && os_type ne 'iphoneos';
subtest 'WindowWidth_SetInvalid_ThrowsArgumentOutOfRangeException' => sub {
  plan tests => 2;
  for my $value (0, -1) {
    if ( Console->IsOutputRedirected ) {
      dies_ok { Console->WindowWidth($value) } 'Throws';
    } else {
      throws_ok { Console->WindowWidth($value) } qr/WindowWidth/;
    }
  }
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix') 
  && os_type ne 'iphoneos';
subtest 'WindowWidth_GetUnix_Success' => sub {
  plan tests => 1;
  # Validate that Console->WindowWidth returns some value in a 
  # non-redirected o/p.
  my $name = Console->IsOutputRedirected ? 'RunInRedirectedOutput' 
                                         : 'RunInNonRedirectedOutput';
  ok Console->WindowWidth, $name;
}}

SKIP: { skip 'Platform specific', 1 unless os_type eq 'iphoneos';
# Expected behavior specific to Unix
subtest 'WindowWidth_SetUnix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->WindowWidth( 100 ) } qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows') 
  || is_os_type('Unix') && os_type ne 'iphoneos';
subtest 'WindowHeight_SetInvalid_ThrowsArgumentOutOfRangeException' => sub {
  plan tests => 2;
  for my $value (0, -1) {
    if ( Console->IsOutputRedirected ) {
      dies_ok { Console->WindowHeight($value) } 'Throws';
    } else {
      throws_ok { Console->WindowHeight($value) } qr/WindowHeight/;
    }
  }
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix') 
  && os_type ne 'iphoneos';
# Expected behavior specific to Unix
subtest 'WindowHeight_GetUnix_Success' => sub {
  plan tests => 1;
  # Validate that Console->WindowHeight returns some value in a 
  # non-redirected o/p.
  my $name = Console->IsOutputRedirected ? 'RunInRedirectedOutput' 
                                         : 'RunInNonRedirectedOutput';
  ok Console->WindowHeight, $name;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix') 
  && os_type ne 'iphoneos';
# Expected behavior specific to Unix
subtest 'LargestWindowWidth_UnixGet_ReturnsExpected' => sub {
  plan tests => 1;
  my $name = Console->IsOutputRedirected ? 'RunInRedirectedOutput' 
                                         : 'RunInNonRedirectedOutput';
  is Console->LargestWindowWidth, Console->WindowWidth, $name;
}}

SKIP: { skip 'Platform specific', 1 unless os_type eq 'iphoneos';
# Expected behavior specific to Unix
subtest 'WindowHeight_SetUnix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->WindowHeight( 100 ) } qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix') 
  && os_type ne 'iphoneos';
# Expected behavior specific to Unix
subtest 'LargestWindowHeight_UnixGet_ReturnsExpected' => sub {
  plan tests => 1;
  my $name = Console->IsOutputRedirected ? 'RunInRedirectedOutput' 
                                         : 'RunInNonRedirectedOutput';
  is Console->LargestWindowHeight, Console->WindowHeight, $name;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
# Expected behavior specific to Unix
subtest 'WindowLeft_GetUnix_ReturnsZero' => sub {
  is Console->WindowLeft, 0, 'Equal';
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
# Expected behavior specific to Unix
subtest 'WindowLeft_SetUnix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->WindowLeft( 0 ) } qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
# Expected behavior specific to Unix
subtest 'WindowTop_GetUnix_ReturnsZero' => sub {
  plan tests => 1;
  is Console->WindowTop, 0, 'Equal';
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
# Expected behavior specific to Unix
subtest 'WindowTop_SetUnix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->WindowTop(0) } qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
# Expected behavior specific to Windows
subtest 'WindowLeftTop_Windows' => sub {
  plan tests => 2;
  if ( Console->IsOutputRedirected ) {
    TODO: {
      local $TODO = 'Exception if Output is redirected';
      throws_ok { Console->WindowLeft } qr/IOException/;
      throws_ok { Console->WindowTop  } qr/IOException/;
    }
  } else {
    lives_ok { note Console->WindowLeft };
    lives_ok { note Console->WindowTop  };
  }
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
# Expected behavior specific to Unix
subtest 'CursorVisible_GetUnix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->CursorVisible } qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix') 
  && os_type ne 'iphoneos';
# Expected behavior specific to Unix
subtest 'CursorVisible_SetUnixRedirected_Nop' => sub {
  plan tests => 2;
  for my $value (1, 0) {
    note Console->IsOutputRedirected ? 'RunInRedirectedOutput' 
                                    : 'RunInNonRedirectedOutput';
    dies_ok { Console->CursorVisible($value) };
  }
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
# Expected behavior specific to Unix
subtest 'Title_GetUnix_ThrowPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->Title } qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
# Expected behavior specific to Unix
subtest 'Title_SetUnix_Success' => sub {
  plan tests => 1;
  lives_ok {
    Console->Title("Title set by unit test")
  }
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'Title_GetWindows_ReturnsNonNull' => sub {
  plan tests => 1;
  ok Console->Title, 'NotNull';
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'Title_Set_Windows' => sub {
  for my $lengthOfTitle (0, 1, 254, 255, 256, 257, 511, 512, 513, 1024) {
    # Try to set the title to some other value.
    lives_ok { 
      my $newTitle = 'a' x $lengthOfTitle;
      Console->Title($newTitle);
      # Win32::Console::_GetConsoleTitle() only supports 1024 characters
      is Console->Title, $lengthOfTitle > 1024 ? '' : $newTitle, 'Equal';
    };
  }
}}

subtest 'Title_SetNull_ThrowsArgumentNullException' => sub {
  plan tests => 1;
  throws_ok { Console->Title(undef) } qr/ArgumentNullException/;
};

subtest 'Beep_Invoke_Success' => sub {
  plan tests => 1;
  lives_ok { 
    # Nothing to verify; just run the code.
    Console->Beep() 
  };
};

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'BeepWithFrequency_Invoke_Success' => sub {
  plan tests => 1;
  lives_ok { 
    # Nothing to verify; just run the code.
    Console->Beep(800, 200) 
  };
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'BeepWithFrequency_InvalidFrequency_ThrowsArgumentOutOfRangeException,', 
sub {
  plan tests => 2;
  for my $frequency (36, 32768) {
    throws_ok { Console->Beep($frequency, 200) } qr/frequency/;
  }
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'BeepWithFrequency_InvalidDuration_ThrowsArgumentOutOfRangeException', 
sub {
  plan tests => 2;
  for my $duration (0, -1) {
    throws_ok { Console->Beep(800, $duration) } qr/duration/;
  }
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
subtest 'BeepWithFrequency_Unix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->Beep(800, 200) } qr/PlatformNotSupportedException/;
}}

subtest 'Clear_Invoke_Success' => sub {
  if ( !is_os_type('Windows') 
    || !Console->IsInputRedirected && !Console->IsOutputRedirected 
  ) {
    lives_ok { 
      # Nothing to verify; just run the code.
      Console->Clear() 
    }
  }
  pass;
};

SKIP: { skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 if 
  os_type eq 'iphoneos';
subtest 'SetCursorPosition_Invoke_Success' => sub {
  if ( !is_os_type('Windows') 
    || !Console->IsInputRedirected && !Console->IsOutputRedirected 
  ) {
    lives_ok { 
      my $origLeft = Console->CursorLeft;
      my $origTop = Console->CursorTop;

      # Nothing to verify; just run the code.
      # On windows, we might end of throwing IOException, since the handles are 
      # redirected.
      Console->SetCursorPosition(0, 0);
      Console->SetCursorPosition(1, 2);

      Console->SetCursorPosition($origLeft, $origTop);
    };
  }
  pass;
}}

subtest 'SetCursorPosition_InvalidPosition_ThrowsArgumentOutOfRangeException', 
sub {
  plan tests => 4;
  for my $value (-1, 0x7fff+1) {
    throws_ok { Console->SetCursorPosition($value, 100) } qr/left/;
    throws_ok { Console->SetCursorPosition(100, $value) } qr/top/;
  }
};

SKIP: { skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 if 
  os_type eq 'iphoneos';
subtest 'GetCursorPosition_Invoke_ReturnsExpected' => sub {
  if ( !Console->IsInputRedirected && !Console->IsOutputRedirected ) {
    lives_ok{
      my $origLeft = Console->CursorLeft; my $origTop = Console->CursorTop;
      my $origTuple = Console->GetCursorPosition();

      TODO: {
        local $TODO = 'Get position in test situation';
        Console->SetCursorPosition(10, 12);
        is Console->CursorLeft, 10, 'Equal';
        is Console->CursorTop, 12, 'Equal';
        is_deeply Console->GetCursorPosition(), [10, 12], 'Equal';

        Console->SetCursorPosition($origLeft, $origTop);
        is Console->CursorLeft, $origLeft, 'Equal';
        is Console->CursorTop, $origTop, 'Equal';
        is_deeply Console->GetCursorPosition(), [$origLeft, $origTop], 'Equal';
      }
    }
  }
  elsif ( !is_os_type('Windows') ) {
    is Console->CursorLeft, 0, 'Equal';
    is Console->CursorTop, 0, 'Equal';
    is_deeply Console->GetCursorPosition(), [0,0], 'Equal';
  }
  pass;
}}

SKIP: { skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 if 
  os_type eq 'iphoneos';
subtest 'CursorLeft_Set_GetReturnsExpected' => sub {
  if ( !Console->IsInputRedirected && !Console->IsOutputRedirected ) {
    lives_ok{
      my $origLeft = Console->CursorLeft;

      TODO: {
        local $TODO = 'Get position in test situation';
        Console->CursorLeft( 10 );
        is Console->CursorLeft, 10, 'Equal';

        Console->CursorLeft( $origLeft );
        is Console->CursorLeft, $origLeft, 'Equal';
      }
    }
  }
  elsif ( !is_os_type('Windows') ) {
    is Console->CursorLeft, 0, 'Equal';
  }
  pass;
}}

SKIP: { skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 if 
  os_type eq 'iphoneos';
subtest 'CursorLeft_SetInvalid_ThrowsArgumentOutOfRangeException' => sub {
  plan tests => 2;
  for my $value (-1, 0x7fff+1) {
    if ( is_os_type('Windows') && Console->IsOutputRedirected ) {
      dies_ok { Console->CursorLeft( $value ) } 'Throws';
    } else {
      throws_ok { Console->CursorLeft( $value ) } qr/left/;
    }
  }
}}

SKIP: { skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 if 
  os_type eq 'iphoneos';
subtest 'CursorTop_Set_GetReturnsExpected' => sub {
  if ( !Console->IsInputRedirected && !Console->IsOutputRedirected ) {
    lives_ok{
      my $origTop = Console->CursorTop;

      TODO: {
        local $TODO = 'Get position in test situation';
        Console->CursorTop( 10 );
        is Console->CursorTop, 10, 'Equal';

        Console->CursorTop( $origTop );
        is Console->CursorTop, $origTop, 'Equal';
      }
    }
  }
  elsif ( !is_os_type('Windows') ) {
    is Console->CursorTop, 0, 'Equal';
  }
  pass;
}}

SKIP: { skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 if 
  os_type eq 'iphoneos';
subtest 'CursorTop_SetInvalid_ThrowsArgumentOutOfRangeException' => sub {
  plan tests => 2;
  for my $value (-1, 0x7fff+1) {
    if ( is_os_type('Windows') && Console->IsOutputRedirected ) {
      dies_ok { Console->CursorTop( $value ) } 'Throws';
    } else {
      throws_ok { Console->CursorTop( $value ) } qr/top/;
    }
  }
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'CursorSize_Set_GetReturnsExpected' => sub {
  if ( !Console->IsInputRedirected && !Console->IsOutputRedirected ) {
    lives_ok { 
      my $orig = Console->CursorSize;
      Console->CursorSize( 50 );
      is Console->CursorSize, 50, 'Equal';
      Console->CursorSize( $orig );
    }
  }
  pass;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'CursorSize_SetInvalidValue_ThrowsArgumentOutOfRangeException' => sub {
  plan tests => 2;
  for my $value (0, 101) {
    throws_ok { Console->CursorSize( $value ) } qr/value/;
  }
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix') 
  && os_type ne 'iphoneos'; 
subtest 'CursorSize_GetUnix_ReturnsExpected' => sub {
  plan tests => 1;
  is Console->CursorSize, 100, 'Equal';
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
subtest 'CursorSize_SetUnix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->CursorSize( 1 ) } qr/top/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'SetWindowPosition_GetWindowPosition_ReturnsExpected' => sub {
  if ( !Console->IsInputRedirected && !Console->IsOutputRedirected )  {
    throws_ok { Console->SetWindowPosition(-1, Console->WindowTop) } qr/left/;
    throws_ok { Console->SetWindowPosition(Console->WindowLeft, -1) } qr/top/;
    throws_ok { Console->SetWindowPosition(
      Console->BufferWidth - Console->WindowWidth + 2, Console->WindowTop)
    } qr/left/;
    throws_ok { Console->SetWindowPosition(
      Console->WindowHeight, Console->BufferHeight - Console->WindowHeight + 2)
    } qr/left/;

    lives_ok {
      my $origTop = Console->WindowTop;
      my $origLeft = Console->WindowLeft;

      Console->SetWindowPosition(0, 0);
      is Console->WindowTop, 0, 'Equal';
      is Console->WindowLeft, 0, 'Equal';

      Console->WindowTop( $origTop );
      Console->WindowLeft( $origLeft );
    }
  }
  pass;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
subtest 'SetWindowPosition_Unix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->SetWindowPosition(50, 50) } 
    qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'SetWindowSize_GetWindowSize_ReturnsExpected' => sub {
  if ( !Console->IsInputRedirected && !Console->IsOutputRedirected )  {
    throws_ok { Console->SetWindowSize(-1, Console->WindowHeight) } qr/width/;
    throws_ok { Console->SetWindowSize(Console->WindowHeight, -1) } qr/height/;
    throws_ok { Console->SetWindowSize(
      0x7fff - Console->WindowLeft, Console->WindowHeight)
    } qr/width/;
    throws_ok {
      Console->SetWindowSize(
        Console->WindowWidth, 0x7fff - Console->WindowTop)
    } qr/height/;

    lives_ok {
      my $origWidth = Console->WindowWidth;
      my $origHeight = Console->WindowHeight;

      Console->SetWindowSize(10, 10);
      is Console->WindowWidth, 10, 'Equal';
      is Console->WindowHeight, 10, 'Equal';

      Console->WindowWidth( $origWidth );
      Console->WindowHeight( $origHeight );
    }
  }
  pass;
}}

SKIP: { skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 unless 
  os_type eq 'iphoneos';
subtest 'SetWindowSize_Unix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->SetWindowSize(50, 50) } 
    qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'MoveBufferArea_DefaultChar' => sub {
  if ( !Console->IsInputRedirected && !Console->IsOutputRedirected ) {
    throws_ok { Console->MoveBufferArea(-1, 0, 0, 0, 0, 0) } qr/sourceLeft/;
    throws_ok { Console->MoveBufferArea(0, -1, 0, 0, 0, 0) } qr/sourceTop/;
    throws_ok { Console->MoveBufferArea(0, 0, -1, 0, 0, 0) } qr/sourceWidth/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, -1, 0, 0) } qr/sourceHeight/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, 0, -1, 0) } qr/targetLeft/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, 0, 0, -1) } qr/targetTop/;
    throws_ok { Console->MoveBufferArea(Console->BufferWidth + 1, 0, 0, 0, 0, 0
      ) } qr/sourceLeft/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, 0, Console->BufferWidth+1, 0
      ) } qr/targetLeft/;
    throws_ok { Console->MoveBufferArea(0, Console->BufferHeight +1, 0, 0, 0, 0
      ) } qr/sourceTop/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, 0, 0, Console->BufferHeight +1
      ) } qr/targetTop/;
    throws_ok { Console->MoveBufferArea(0, 1, 0, Console->BufferHeight, 0, 0
      ) } qr/sourceHeight/;
    throws_ok { Console->MoveBufferArea(1, 0, Console->BufferWidth, 0, 0, 0
      ) } qr/sourceWidth/;

    # Nothing to verify; just run the code.
    lives_ok { Console->MoveBufferArea(0, 0, 1, 1, 2, 2) };
  }
  pass;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'MoveBufferArea' => sub {
  if ( !Console->IsInputRedirected && !Console->IsOutputRedirected ) {
    throws_ok { Console->MoveBufferArea(-1, 0, 0, 0, 0, 0, 
      '0', ConsoleColor->Black, ConsoleColor->White) } qr/sourceLeft/;
    throws_ok { Console->MoveBufferArea(0, -1, 0, 0, 0, 0, 
      '0', ConsoleColor->Black, ConsoleColor->White) } qr/sourceTop/;
    throws_ok { Console->MoveBufferArea(0, 0, -1, 0, 0, 0, 
      '0', ConsoleColor->Black, ConsoleColor->White) } qr/sourceWidth/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, -1, 0, 0, 
      '0', ConsoleColor->Black, ConsoleColor->White) } qr/sourceHeight/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, 0, -1, 0, 
      '0', ConsoleColor->Black, ConsoleColor->White) } qr/targetLeft/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, 0, 0, -1, 
      '0', ConsoleColor->Black, ConsoleColor->White) } qr/targetTop/;
    throws_ok { Console->MoveBufferArea(Console->BufferWidth + 1, 0, 0, 0, 0, 0, 
      '0', ConsoleColor->Black, ConsoleColor->White) } qr/sourceLeft/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, 0, Console->BufferWidth + 1, 0, 
      '0', ConsoleColor->Black, ConsoleColor->White) } qr/targetLeft/;
    throws_ok { Console->MoveBufferArea(0, Console->BufferHeight+1, 0, 0, 0, 0, 
      '0', ConsoleColor->Black, ConsoleColor->White)} qr/sourceTop/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, 0, 0, Console->BufferHeight +1, 
      '0', ConsoleColor->Black, ConsoleColor->White)} qr/targetTop/;
    throws_ok { Console->MoveBufferArea(0, 1, 0, Console->BufferHeight, 0, 0, 
      '0', ConsoleColor->Black, ConsoleColor->White) } qr/sourceHeight/;
    throws_ok { Console->MoveBufferArea(1, 0, Console->BufferWidth, 0, 0, 0, 
      '0', ConsoleColor->Black, ConsoleColor->White)} qr/sourceWidth/;

    # Nothing to verify; just run the code.
    lives_ok { Console->MoveBufferArea(0, 0, 1, 1, 2, 2, 
      'a', ConsoleColor->Black, ConsoleColor->White) 
    };
  }
  pass;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Windows');
subtest 'MoveBufferArea_InvalidColor_ThrowsException' => sub {
  plan tests => 4;
  for my $color (ConsoleColor->Black - 1, ConsoleColor->White + 1) {
    throws_ok { Console->MoveBufferArea(0, 0, 0, 0, 0, 0, 'a', $color, 
      ConsoleColor->Black) } qr/sourceForeColor/;
    throws_ok { Console->MoveBufferArea(0, 0, 0, 0, 0, 0, 'a', 
      ConsoleColor->Black, $color) } qr/sourceBackColor/;
  }
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
subtest 'MoveBufferArea_Unix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 2;
  throws_ok { Console->MoveBufferArea(0, 0, 0, 0, 0, 0) } 
    qr/PlatformNotSupportedException/;
  throws_ok {
    Console->MoveBufferArea(0, 0, 0, 0, 0, 0, 'c', ConsoleColor->White, 
      ConsoleColor->Black) } qr/PlatformNotSupportedException/;
}}

done_testing;
