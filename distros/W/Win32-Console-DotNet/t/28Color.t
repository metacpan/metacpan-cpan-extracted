# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/Color.cs
# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.
use 5.014;
use warnings;

use Test::More tests => 9;
use Test::Exception;

use Perl::OSType qw( :all );

use constant CAPTURE_TINY => eval { require Capture::Tiny };
use if CAPTURE_TINY, 'Capture::Tiny', qw( capture_stdout );

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'System';
  use_ok 'ConsoleColor';
}

use constant Esc => chr 0x1b;

SKIP: { skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 if 
  os_type eq 'iphoneos';
subtest 'InvalidColors' => sub {
  plan tests => 2;
  throws_ok { Console->BackgroundColor(42) } qr/ArgumentException/;
  throws_ok { Console->BackgroundColor(42) } qr/ArgumentException/;
}}

SKIP: { skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 if 
  os_type eq 'iphoneos';
subtest 'RoundtrippingColor' => sub {
  plan tests => 2;
  lives_ok { Console->BackgroundColor( Console->BackgroundColor ) };
  lives_ok { Console->ForegroundColor( Console->ForegroundColor ) };

  # Changing color on Windows doesn't have effect in some testing environments
  # when there is no associated console, such as when run under a profiler like
  # our code coverage tools, so we don't assert that the change took place and
  # simply ensure that getting/setting doesn't throw.
}}

subtest 'ForegroundColor' => sub {
  plan tests => 2;
  lives_ok { Console->ForegroundColor };
  lives_ok { Console->ForegroundColor( ConsoleColor->Red ) };
};

subtest 'BackgroundColor' => sub {
  plan tests => 2;
  lives_ok { Console->BackgroundColor };
  lives_ok { Console->BackgroundColor( ConsoleColor->Red ) };
};

SKIP: { skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 if 
  os_type eq 'iphoneos';
skip 'Capture::Tiny not installed', 1 unless CAPTURE_TINY;
subtest 'RedirectedOutputDoesNotUseAnsiSequences' => sub {
  plan tests => 3;
  # Make sure that redirecting to a memory stream causes Console not to write 
  # out the ANSI sequences

  my $data = capture_stdout( sub {
    lives_ok {
      Console->Write('1');
      Console->ForegroundColor( ConsoleColor->Blue );
      Console->Write('2');
      Console->BackgroundColor( ConsoleColor->Red );
      Console->Write('3');
      Console->ResetColor();
      Console->Write('4');
    }
  });
  is index($data, Esc), -1;
  is $data, "1234";
}}

use constant TermIsSetAndRemoteExecutorIsSupported => !!$ENV{"TERM"};

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
skip 'Not supported iOS, MacCatalyst, or tvOS.', 1 if os_type eq 'iphoneos';
skip 'TERM is not set', 1 unless TermIsSetAndRemoteExecutorIsSupported;
subtest 'RedirectedOutput_EnvVarSet_EmitsAnsiCodes' => sub {
  plan tests => 6;
  for my $envVar (undef, '1', 'true', 'tRuE', '0', 'false') {
    TODO: {
      local $TODO = 'Action not implemented';
      fail;
    }
  }
}}

done_testing;
