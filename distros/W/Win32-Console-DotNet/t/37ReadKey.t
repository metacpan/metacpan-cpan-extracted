# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/ReadKey.cs
# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.
use 5.014;
use warnings;

use Test::More tests => 9;
use Test::Exception;

use IPC::Open3;
use Perl::OSType qw( is_os_type );
use Symbol qw( gensym );

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'System';
  use_ok 'ConsoleKey';
  use_ok 'ConsoleKeyInfo';
}

use constant FALSE => !! '';

subtest 'KeyAvailable' => sub {
  plan tests => 2;
  lives_ok {
    if ( Console->IsInputRedirected ) {
      throws_ok { Console->KeyAvailable } qr/InvalidOperationException/;
    }
    else {
      # Nothing to assert; just validate we can call it.
      my $available = Console->KeyAvailable;
      pass;
    }
  }
};

subtest 'RedirectedConsole_ReadKey' => sub {
  plan tests => 1;

  throws_ok {
    my $pid = open3(my $in, my $out, my $err = gensym,
      perl
        => q{-MWin32::Console::DotNet}
        => q{-e "System::Console->ReadKey()"}
    ) or die $!;
    $@ = join('', $err->getlines());
    waitpid($pid, 0);
    die $@ if $@; # use warnings FATAL => 'all'
  } qr/InvalidOperationException/;
};

subtest 'ConsoleKeyValueCheck' => sub {
  plan tests => 2;
  lives_ok {
    my $info;
    $info = ConsoleKeyInfo->new("\0", 0, FALSE, FALSE, FALSE);
    $info = ConsoleKeyInfo->new("\0", 255, FALSE, FALSE, FALSE);
  };
  throws_ok {
    ConsoleKeyInfo->new("\0", 256, FALSE, FALSE, FALSE);
  } qr/ArgumentOutOfRangeException/;
};

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
subtest 'NumberLock_GetUnix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->NumberLock } qr/PlatformNotSupportedException/;
}}

SKIP: { skip 'Platform specific', 1 unless is_os_type('Unix');
subtest 'CapsLock_GetUnix_ThrowsPlatformNotSupportedException' => sub {
  plan tests => 1;
  throws_ok { Console->CapsLock } qr/PlatformNotSupportedException/;
}}

done_testing;
