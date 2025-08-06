# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/ManualTests/ManualTests.cs
# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.
use 5.014;
use warnings;

use Test::More;
use Test::Exception;

use POSIX;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 27;
  }
}

# Fix STDOUT redirection from prove
POSIX::dup2(fileno(STDERR), fileno(STDOUT));

package ConsoleManualTests {
  use 5.014;
  use warnings;

  require bytes;
  use Devel::Assert 'on';
  use Test::More;
  use Time::HiRes;
  use Win32;
  use Win32::Console;
  use Win32API::File;

  BEGIN {
    use_ok 'Win32::Console::DotNet';
    require_ok 'System';
    require_ok 'ConsoleColor';
    require_ok 'ConsoleKey';
    require_ok 'ConsoleModifiers';
    require_ok 'ConsoleKeyInfo';
  }

  use Exporter qw( import );
  our @EXPORT = qw( 
    FALSE
    TRUE
    ManualTestsEnabled
    ReadLine
    ReadLineFromOpenStandardInput
    ReadFromOpenStandardInput
    ConsoleReadSupportsBackspace
    ReadLine_BackSpaceCanMoveAcrossWrappedLines
    InPeek
    Beep
    ReadKey
    ReadKeyNoIntercept
    EnterKeyIsEnterAfterKeyAvailableCheck
    ReadKey_KeyChords
    GetKeyChords
    ConsoleOutWriteLine
    KeyAvailable
    Clear
    Colors
    CursorPositionAndArrowKeys
    EncodingTest
    CursorLeftFromLastColumn
    ResizeTest
  );

  use constant ManualTestsEnabled => exists($ENV{MANUAL_TESTS})
                                  && !$ENV{AUTOMATED_TESTING}
                                  && !$ENV{NONINTERACTIVE_TESTING};
  use constant FALSE  => !!'';
  use constant TRUE   => !!1;

  sub ReadLine { # void ($consoleIn)
    my ($consoleIn) = @_;
    my $expectedLine = "This is a test of Console->". 
      ($consoleIn ? "In->" : "") ."ReadLine.";
    System::Console->WriteLine("Please type the sentence ". 
      "(without the quotes): \"$expectedLine\"");
    my $result = $consoleIn 
      ? System::Console->In->getline() 
      : System::Console->ReadLine();
    assert ( index($result, $expectedLine) == 0 or ~- warn 'Equal' );
    AssertUserExpectedResults("the characters you typed properly echoed as ". 
      "you typed");
    return;
  }

  sub ReadLineFromOpenStandardInput { # void ()
    my $expectedLine = "aab";

    # Use Console->ReadLine
    System::Console->WriteLine("Please type 'a' 3 times, press 'Backspace' ".
      " to erase 1, then type a single 'b' and press 'Enter'.");
    my $result = System::Console->ReadLine();
    assert ( index($result, $expectedLine) == 0 or ~- warn 'Equal' );
    AssertUserExpectedResults("the characters you typed properly echoed as ". 
      "you typed");

    # getline from Console->OpenStandardInput
    System::Console->WriteLine("Please type 'a' 3 times, press 'Backspace' ". 
      "to erase 1, then type a single 'b' and press 'Enter'.");
    my $reader = System::Console->OpenStandardInput();
    $result = $reader->getline();
    assert ( index($result, $expectedLine) == 0 or ~- warn 'Equal' );
    AssertUserExpectedResults("the characters you typed properly echoed as ". 
      "you typed");
  }

  sub ReadFromOpenStandardInput { # void ()
    # The implementation in StdInReader uses a StringBuilder for caching. We 
    # want this builder to use multiple chunks. So the expectedLine is longer 
    # than 16 characters (StringBuilder.DefaultCapacity).
    my $expectedLine = "This is a test for ReadFromOpenStandardInput.";
    assert ( length($expectedLine) > 16 or ~- warn 'True' );
    System::Console->WriteLine("Please type the sentence ". 
      "(without the quotes): \"$expectedLine\"");
    my $inputStream = System::Console->OpenStandardInput();
    for (my $i = 0; $i < length($expectedLine); $i++) {
      assert ( bytes::substr($expectedLine, $i, 1) 
        eq ($inputStream->sysread($_, 1) ? $_ : '') or ~- warn 'Equal' );
    }
    assert ( "\n" eq ($inputStream->read($_, 1) ? $_ : '') or ~- warn 'Equal' );
    AssertUserExpectedResults("the characters you typed properly echoed as ". 
      "you typed");
  }

  sub ConsoleReadSupportsBackspace { # void ()
    my $expectedLine = "aab\n";

    System::Console->WriteLine("Please type 'a' 3 times, press 'Backspace' ". 
      "to erase 1, then type a single 'b' and press 'Enter'.");
    foreach my $c ( split //, $expectedLine ) {
      my $ch = System::Console->Read();
      assert ( $c eq chr $ch or ~- warn 'Equal' );
    }
    AssertUserExpectedResults("the characters you typed properly echoed as ". 
      "you typed");
  }

  sub ReadLine_BackSpaceCanMoveAcrossWrappedLines { # void ()
    System::Console->WriteLine("Please press 'a' until it wraps to the next ". 
      "terminal line, then press 'Backspace' until the input is erased, ". 
      "and then type a single 'a' and press 'Enter'.");
    System::Console->Write("Input: ");
    System::Console->Out->flush();

    my $result = System::Console->ReadLine();
    assert ( "a" eq $result or ~- warn 'Equal' );
    AssertUserExpectedResults("the previous line is 'Input: a'");
  }

  sub InPeek { # void ()
    System::Console->WriteLine("Please type \"peek\" (without the quotes). ". 
      "You should see it as you type:");
    foreach my $c ( 'p', 'e', 'e', 'k' ) {
      assert ( $c eq System::Console->In->Peek() or ~- warn 'Equal' );
      assert ( $c eq System::Console->In->Peek() or ~- warn 'Equal' );
      assert ( $c eq System::Console->In->Peek() or ~- warn 'Equal' );
    }
    System::Console->In->getline(); # enter
    AssertUserExpectedResults("the characters you typed properly echoed as ". 
      "you typed");
  }

  sub Beep { # void ()
    System::Console->Beep();
    AssertUserExpectedResults("hear a beep");
  }

  sub ReadKey { # void ()
    System::Console->WriteLine("Please type \"console\" ". 
      "(without the quotes). You shouldn't see it as you type:");
    foreach my $k ( qw{ C O N S O L E } ) {
      assert ( $k eq chr System::Console->ReadKey(TRUE())->Key 
        or ~- warn 'Equal' 
      );
    }
    AssertUserExpectedResults("\"console\" correctly not echoed as you ". 
      "typed it");
  }

  sub ReadKeyNoIntercept { # void ()
    System::Console->WriteLine("Please type \"console\" ". 
      "(without the quotes). You should see it as you type:");
    foreach my $k ( qw{ C O N S O L E } ) {
      assert ( $k eq chr System::Console->ReadKey(FALSE())->Key 
        or ~- warn 'Equal' 
      );
    }
    AssertUserExpectedResults("\"console\" correctly echoed as you typed it");
  }

  sub EnterKeyIsEnterAfterKeyAvailableCheck() { # void ()
    System::Console->WriteLine("Please hold down the 'Enter' key for some ". 
      "time. You shouldn't see new lines appear:");
    my $keysRead = 0;
    while ($keysRead < 50) {
      if (System::Console->KeyAvailable) {
        my $keyInfo = System::Console->ReadKey(FALSE);
        assert ( ConsoleKey->Enter == $keyInfo->Key or ~- warn 'Equal' );
        $keysRead++;
      }
    }
    while (System::Console->KeyAvailable) {
      my $keyInfo = System::Console->ReadKey(TRUE);
      assert ( ConsoleKey->Enter == $keyInfo->Key or ~- warn 'Equal' );
    }
    AssertUserExpectedResults("no empty newlines appear");
  }

  sub ReadKey_KeyChords { # void ($requestedKeyChord, \%expected)
    my ($requestedKeyChord, $expected) = @_;
    System::Console->Write("Please type key chord $requestedKeyChord: ");
    my $actual = System::Console->ReadKey(TRUE);
    System::Console->WriteLine();

    assert ( $expected->Key == $actual->Key or ~- warn 'Equal' );
    assert ( $expected->{Modifiers} == $actual->{Modifiers} 
      or ~- warn 'Equal' 
    );
    assert ( $expected->{KeyChar} eq $actual->{KeyChar} or ~- warn 'Equal' );
  }

  sub GetKeyChords { # \@ ()
    state $MkConsoleKeyInfo = sub {
      my ($requestedKeyChord, $keyChar, $consoleKey, $modifiers) = @_;
      return {
        $requestedKeyChord => bless({
          Key => $consoleKey,
          KeyChar => $keyChar,
          Modifiers => $modifiers,
        }, 'ConsoleKeyInfo'),
      };
    };

    my @yield = (
      $MkConsoleKeyInfo->("Ctrl+B", "\x02", ord('B'), 
        ConsoleModifiers->Control),
      $MkConsoleKeyInfo->("Ctrl+Alt+B", "\x00", ord('B'), 
        ConsoleModifiers->Control | ConsoleModifiers->Alt),
      $MkConsoleKeyInfo->("Enter", "\r", ConsoleKey->Enter, 0),
    );

    if ( $^O eq 'MSWin32' ) {
      push @yield, $MkConsoleKeyInfo->("Ctrl+J", "\n", ord('J'), 
        ConsoleModifiers->Control);
    } else {
      # Ctrl+J is mapped by every Unix Terminal as Ctrl+Enter with new line 
      # character
      push @yield, $MkConsoleKeyInfo->("Ctrl+J", "\n", ConsoleKey->Enter, 
        ConsoleModifiers->Control);
    }

    return @yield;
  }

  sub ConsoleOutWriteLine { # void ()
    System::Console->Out->say("abcdefghijklmnopqrstuvwxyz");
    AssertUserExpectedResults("the alphabet above");
  }

  sub KeyAvailable { # void ()
    System::Console->WriteLine("Wait a few seconds, then press any key...");
    while ( System::Console->KeyAvailable ) {
      System::Console->ReadKey();
    }
    while ( !System::Console->KeyAvailable ) {
      Time::HiRes::sleep(500/1000);
      System::Console->WriteLine("\t...waiting...");
    }
    System::Console->ReadKey();
    AssertUserExpectedResults("several wait messages get printed out");
  }

  sub Clear { # void ()
    System::Console->Clear();
    AssertUserExpectedResults("the screen get cleared");
  }

  sub Colors { # void ()
    use constant squareSize => 20;
    my @colors = ( ConsoleColor->Red, ConsoleColor->Green, ConsoleColor->Blue,
      ConsoleColor->Yellow );
    for (my $row = 0; $row < 2; $row++) {
      for (my $i = 0; $i < int(squareSize / 2); $i++) {
        System::Console->WriteLine();
        System::Console->Write("  ");
        for (my $col = 0; $col < 2; $col++) {
          System::Console->BackgroundColor( $colors[$row * 2 + $col] );
          System::Console->ForegroundColor( $colors[$row * 2 + $col] );
          for (my $j = 0; $j < squareSize; $j++) { 
            System::Console->Write('@');
          }
          System::Console->ResetColor();
        }
      }
    }
    System::Console->WriteLine();

    AssertUserExpectedResults("a Microsoft flag in solid color");
  }

  sub CursorPositionAndArrowKeys { # void ()
    System::Console->WriteLine("Use the up, down, left, and right arrow keys ". 
      "to move around.  When done, press enter.");

    while (TRUE) {
      my $k = System::Console->ReadKey(TRUE);
      if ( $k->Key == ConsoleKey->Enter ) {
        last;
      }

      my $left = System::Console->CursorLeft; 
      my $top = System::Console->CursorTop;
      switch: for ($k->Key) {
        case: $_ == ConsoleKey->UpArrow and do {
          System::Console->CursorTop( $top - 1 ) if $top > 0;
          last;
        };
        case: $_ == ConsoleKey->LeftArrow and do {
          System::Console->CursorLeft( $left - 1 ) if $left > 0;
          last;
        };
        case: $_ == ConsoleKey->RightArrow and do {
          System::Console->CursorLeft( $left + 1 );
          last;
        };
        case: $_ == ConsoleKey->DownArrow and do {
          System::Console->CursorTop( $top + 1 );
          last;
        };
      }
    }

    AssertUserExpectedResults("the arrow keys move around the screen as ". 
      "expected with no other bad artifacts");
  }

  sub EncodingTest {
    System::Console->WriteLine(ref System::Console->OutputEncoding);
    System::Console->WriteLine("'\x{03A0}\x{03A3}'.");
    AssertUserExpectedResults("Pi and Sigma or question marks");
  }

  sub CursorLeftFromLastColumn {
    System::Console->WriteLine();
    System::Console->CursorLeft( System::Console->BufferWidth - 1 );
    System::Console->Write("2");
    System::Console->CursorLeft( 0 );
    System::Console->Write("1");
    System::Console->WriteLine();
    AssertUserExpectedResults("single line with '1' at the start and '2' at ". 
      "the end.");
  }

  sub ResizeTest { # void ()
    my $wasResized = FALSE;

    my $widthBefore = System::Console->WindowWidth;
    my $heightBefore = System::Console->WindowHeight;

    assert ( !$wasResized or ~- warn 'False' );

    System::Console->SetWindowSize(int($widthBefore / 2), 
      int($heightBefore / 2));

    my $manualResetEvent = eval {
      Time::HiRes::sleep(50/1000);
      my $hConsoleOutput = Win32::Console::_GetStdHandle(STD_OUTPUT_HANDLE)//-1;
      assert ( $hConsoleOutput > 0 );
      my $uFileType = Win32API::File::GetFileType($hConsoleOutput) // 0;
      assert ( $uFileType == Win32API::File::FILE_TYPE_CHAR );
      my @ir = Win32::Console::_GetConsoleScreenBufferInfo($hConsoleOutput);
      assert ( @ir > 1 );
      my $width = $ir[7] - $ir[5] + 1;
      my $height = $ir[8] - $ir[6] + 1;
      $wasResized = $widthBefore != $width || $heightBefore != $height;
      1;
    };
    assert ( $manualResetEvent or ~- warn 'True' );
    assert ( $wasResized or ~- warn 'True' );
    assert ( int($widthBefore / 2) == System::Console->WindowWidth 
      or ~- warn 'Equal' 
    );
    assert ( int($heightBefore / 2) == System::Console->WindowHeight 
      or ~- warn 'Equal' 
    );

    System::Console->SetWindowSize($widthBefore, $heightBefore);
    return;
  }

  sub AssertUserExpectedResults { # void ($expected)
    my ($expected) = @_;
    System::Console->Write("Did you see $expected? [y/n] ");
    my $info = System::Console->ReadKey();
    System::Console->WriteLine();
  
    switch: for (chr $info->Key) {
      case: /^[YN]$/ and do {
        assert ( 'Y' eq chr $info->Key or ~- warn 'Equal' );
        last
      };
      default: {
        AssertUserExpectedResults($expected);
        last;
      }
    }
    return;
  }

  $INC{__PACKAGE__ .'.pm'} = 1;
}

use_ok 'ConsoleManualTests';

SKIP: {
  skip 'Manual test not enabled', 20 unless ManualTestsEnabled();

  lives_ok { ReadLine(FALSE())                } 'ReadLine(FALSE)';
  lives_ok { ReadLine(TRUE())                 } 'ReadLine(TRUE)';
  lives_ok { ReadLineFromOpenStandardInput()  } 'ReadLineFromOpenStandardInput';
  lives_ok { ReadFromOpenStandardInput()      } 'ReadFromOpenStandardInput';
  lives_ok { ConsoleReadSupportsBackspace()   } 'ConsoleReadSupportsBackspace';
  lives_ok { ReadLine_BackSpaceCanMoveAcrossWrappedLines() } 
    'ReadLine_BackSpaceCanMoveAcrossWrappedLines';
  SKIP: {
    skip 'Peek() not implemented', 1, unless System::Console->In->can('Peek');
    lives_ok { InPeek() } 'InPeek';
  };
  lives_ok { Beep()                           } 'Beep';
  lives_ok { ReadKey()                        } 'ReadKey';
  lives_ok { ReadKeyNoIntercept()             } 'ReadKeyNoIntercept';
  lives_ok { EnterKeyIsEnterAfterKeyAvailableCheck() } 
    'EnterKeyIsEnterAfterKeyAvailableCheck';
  lives_ok { ReadKey_KeyChords(each %$_) for GetKeyChords() } 
    'ReadKey_KeyChords';
  lives_ok { ConsoleOutWriteLine()            } 'ConsoleOutWriteLine';
  lives_ok { KeyAvailable()                   } 'KeyAvailable';
  lives_ok { diag ''; Clear()                 } 'Clear';
  lives_ok { diag ''; Colors()                } 'Colors';
  lives_ok { CursorPositionAndArrowKeys()     } 'CursorPositionAndArrowKeys';
  lives_ok { EncodingTest()                   } 'EncodingTest';
  lives_ok { CursorLeftFromLastColumn()       } 'CursorLeftFromLastColumn';
  lives_ok { ResizeTest()                     } 'ResizeTest';
};

done_testing;

__END__

=pod

=head1 System->Console manual tests

For verifying console functionality that cannot be run as fully automated. To 
run the suite, follow these steps:

=over

=item 1. Install the nesessary test libraries.

=item 2. Using a terminal, navigate to the current folder.

=item 3. Enable manual testing by defining the C<MANUAL_TESTS> environment 
variable (e.g. on cmd C<set MANUAL_TESTS=1>).

=item 4. Deactivate all standard environment variables for automated tests such 
as C<AUTOMATED_TESTING> or C<NONINTERACTIVE_TESTING> (e.g. with cmd 
C<set AUTOMATED_TESTING=>).

=item 5. Run C<prove> and follow the instructions in the command prompt.

=back

=head2 Instructions for Windows testers

Test on Windows prints to console output, so in order to properly execute the 
manual tests, C<prove> must be invoked with argument C<-q> or C<-Q>. To do this 
run

  prove -l -q xt\*tests.t
