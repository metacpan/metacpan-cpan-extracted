# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/ConsoleEncoding.Windows.cs
# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.
use 5.014;
use warnings;

use Test::More;
use Test::Exception;

use Config;
use Encode ();
use Encode::Alias ();
use List::Util qw( first );

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 10;
  }
}

BEGIN {
  use_ok 'Win32';
  use_ok 'Win32::Console';
  use_ok 'Win32::Console::DotNet';
  use_ok 'System';
}

# Create singleton Encode::Encoding objects
sub Encoding::Latin1 {
  # Use already existing alias from Perl
  state $instance = Encode::find_encoding('cp28591');
}
sub Encoding::ASCII {
  # Use alias from Win32::Console::DotNet
  state $instance = Encode::find_encoding('cp20127');
}
sub Encoding::Unicode {
  # Use alias from Win32::Console::DotNet
  state $instance = Encode::find_encoding('cp120'. ($Config{byteorder} & 0b1));
}

sub OnLeaveScope::DESTROY { ${$_[0]}->() }

# Gets the code page identifier of the current Encoding.
my $CodePage = sub {
  my $self = shift;
  return if @_ || !ref($self) || !$self->isa('Encode::Encoding');

  my $regex = qr/^cp(\d+)$/;
  my @aliases = grep { 
    /$regex/ && $Encode::Alias::Alias{$_} eq $self;
  } keys(%Encode::Alias::Alias);
  my $element = first { /$regex/ } ( $self->name, @aliases );
  return $element && $element =~ $regex ? 0+ $1 : 0;
};

subtest 'InputEncoding_SetDefaultEncoding_Success' => sub {
  plan tests => 3;
  lives_ok {
    my $encoding = Encode::find_encoding('cp'. Win32::GetConsoleCP());
    Console->InputEncoding($encoding);
    is Console->InputEncoding->name, $encoding->name, 'Equal';
    is Win32::GetConsoleCP(), $encoding->$CodePage, 'Equal';
  };
};

subtest 'InputEncoding_SetUnicodeEncoding_SilentlyIgnoredInternally' => sub {
  plan tests => 4;
  lives_ok {
    my $unicodeEncoding = Encoding::Unicode;
    my $oldEncoding = Console->InputEncoding;
    isnt $oldEncoding->name, $unicodeEncoding->name, 'NotEqual';

    Console->InputEncoding($unicodeEncoding);
    is Console->InputEncoding->name, $unicodeEncoding->name, 'Equal';
    is Win32::GetConsoleCP(), $oldEncoding->$CodePage, 'Equal';
  };
};

subtest 'InputEncoding_SetEncodingWhenDetached_ErrorIsSilentlyIgnored' => sub {
  plan tests => 4;
  my $oldEncoding = Win32::GetConsoleCP();
  lives_ok {
    my $dispose = bless \sub {
      # Restore the console
      Win32::Console::Alloc();
      Win32::SetConsoleCP($oldEncoding);
    }, 'OnLeaveScope';
    my $encoding = Console->InputEncoding->$CodePage != Encoding::ASCII->$CodePage
                 ? Encoding::ASCII
                 : Encoding::Latin1;
    
    # use FreeConsole to detach the current console - simulating a process 
    # started with the "DETACHED_PROCESS" flag
    Win32::Console::Free();

    # Setting the input encoding should not throw an exception
    Console->InputEncoding($encoding);
    # The internal state of Console should have updated, despite the failure 
    # to change the console's input encoding
    is Console->InputEncoding->name, $encoding->name, 'Equal';
    # Operations on the console are no longer valid - GetConsoleCP fails.
    is Win32::GetConsoleCP(), 0, 'Equal';
  };
  ok Win32::GetConsoleCP();
};

subtest 'OutputEncoding_SetDefaultEncoding_Success' => sub {
  plan tests => 3;
  lives_ok {
    my $encoding = Encode::find_encoding('cp'. Win32::GetConsoleOutputCP());
    Console->OutputEncoding($encoding);
    is Console->OutputEncoding->name, $encoding->name, 'Equal';
    is Win32::GetConsoleOutputCP(), $encoding->$CodePage, 'Equal';
  };
};

subtest 'OutputEncoding_SetUnicodeEncoding_SilentlyIgnoredInternally' => sub {
  plan tests => 4;
  lives_ok {
    my $unicodeEncoding = Encoding::Unicode;
    my $oldEncoding = Console->OutputEncoding;
    isnt $oldEncoding->name, $unicodeEncoding->name, 'NotEqual';
    Console->OutputEncoding($unicodeEncoding);
    is Console->OutputEncoding->name, $unicodeEncoding->name, 'Equal';

    is Win32::GetConsoleOutputCP(), $oldEncoding->$CodePage, 'Equal';
  };
};

subtest 'OutputEncoding_SetEncodingWhenDetached_ErrorIsSilentlyIgnored' => sub {
  plan tests => 4;
  my $oldEncoding = Win32::GetConsoleOutputCP();
  lives_ok {
    my $dispose = bless \sub {
      # Restore the console
      Win32::Console::Alloc();
      Win32::SetConsoleOutputCP($oldEncoding);
    }, 'OnLeaveScope';
    my $encoding = Console->OutputEncoding->$CodePage 
      != Encoding::ASCII->$CodePage
                 ? Encoding::ASCII
                 : Encoding::Latin1;
    
    # use FreeConsole to detach the current console - simulating a process 
    # started with the "DETACHED_PROCESS" flag
    Win32::Console::Free();

    # Setting the output encoding should not throw an exception
    Console->OutputEncoding($encoding);
    # The internal state of Console should have updated, despite the failure 
    # to change the console's output encoding
    is Console->OutputEncoding->name, $encoding->name, 'Equal';
    # Operations on the console are no longer valid - GetConsoleOutputCP fails.
    is Win32::GetConsoleOutputCP(), 0, 'Equal';
  };
  is Win32::GetConsoleOutputCP(), $oldEncoding;
};

done_testing;
