# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/RedirectedStream.cs
# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.
use 5.014;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use IPC::Open3;
use Symbol qw( gensym );

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'System';
}

use constant TRUE => !! 1;

subtest 'InputRedirect' => sub {
  plan tests => 2;

  lives_ok {
    my $pid = open3(my $in, my $out = gensym, my $err,
      perl
      => q{-X}
      => q{-MWin32::Console::DotNet}
      => q{-e "print 0+System::Console->IsInputRedirected"}
    ) or die $!;
    is $out->getline(), TRUE;
    waitpid($pid, 0);
  };
};

subtest 'OutputRedirect' => sub {
  plan tests => 2;

  lives_ok {
    my $pid = open3(my $in, my $out = gensym, my $err,
      perl
      => q{-X}
      => q{-MWin32::Console::DotNet}
      => q{-e "print 0+System::Console->IsOutputRedirected"}
    ) or die $!;
    is $out->getline(), TRUE;
    waitpid($pid, 0);
  };
};

subtest 'ErrorRedirect' => sub {
  plan tests => 2;

  lives_ok {
    my $pid = open3(my $in, my $out = gensym, my $err,
      perl
      => q{-X}
      => q{-MWin32::Console::DotNet}
      => q{-e "print 0+System::Console->IsErrorRedirected"}
    ) or die $!;
    is $out->getline(), TRUE;
    waitpid($pid, 0);
  };
};

subtest 'InvokeRedirected' => sub {
  plan tests => 1;
  # We can't be sure of the state of stdin/stdout/stderr redirects, so we can't 
  # validate the results of the Redirected properties one way or the other, but 
  # we can at least invoke them to ensure that no exceptions are thrown.
  lives_ok {
    no warnings 'uninitialized';
    my $result;
    note 'stdin : ', $result = 0+ Console->IsInputRedirected;
    note 'stdout: ', $result = 0+ Console->IsOutputRedirected;
    note 'stderr: ', $result = 0+ Console->IsErrorRedirected;
  };
};

done_testing;
