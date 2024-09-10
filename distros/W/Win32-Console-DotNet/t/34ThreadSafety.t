# https://github.com/dotnet/runtime/blob/116f5fd624c6981a66c2a03c5ea5f8fa037ef57f/src/libraries/System.Console/tests/ThreadSafety.cs
# Licensed to the .NET Foundation under one or more agreements.
# The .NET Foundation licenses this file to you under the MIT license.
use 5.014;
use warnings;

use Test::More tests => 5;
use Test::Exception;

use Devel::StrictMode;
use threads;
use threads::shared;
use Scalar::Util qw( openhandle );

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'System';
}

use constant NumberOfIterations => STRICT ? 100 : 20;

my $msg = sprintf("Create %d threads...", NumberOfIterations);

subtest 'OpenStandardXXXCanBeCalledConcurrently' => sub {
  plan tests => 3;

  Parallel: {
    note $msg;
    my @threads;
    for (1..NumberOfIterations) {
      push @threads, async {
        my $s = Console->OpenStandardInput();
        return openhandle $s;
      };
    }
    # Several processes access or close at the same time. Surpress warnings:
    # - Warning: unable to close filehandle %s properly: Bad file descriptor ...
    # - Unbalanced saves: %d more saves than restores
    no if Console->IsInputRedirected(), 'warnings', qw( io internal );
    my $defined = grep { $_->join() } @threads;
    is $defined, NumberOfIterations, "NotNull";
  }

  Parallel: {
    diag $msg;
    my @threads;
    for (1..NumberOfIterations) {
      push @threads, async {
        my $s = Console->OpenStandardOutput();
        return openhandle $s;
      };
    }
    no if Console->IsOutputRedirected(), 'warnings', qw( io internal );
    my $defined = grep { $_->join() } @threads;
    is $defined, NumberOfIterations, "NotNull";
  }

  Parallel: {
    diag $msg;
    my @threads;
    for (1..NumberOfIterations) {
      push @threads, async {
        my $s = Console->OpenStandardError();
        return openhandle $s;
      };
    }
    no if Console->IsErrorRedirected(), 'warnings', qw( io );
    my $defined = grep { $_->join() } @threads;
    is $defined, NumberOfIterations, "NotNull";
  }
};

subtest 'SetStandardXXXCanBeCalledConcurrently' => sub {
  plan tests => 4;

  lives_ok {
    using: if ( defined(my $memStream :shared = '') ) {

      using: if ( open(my $sr, '<', \$memStream) ) {

        using: if ( open(my $sw, '>', \$memStream) ) {

          Parallel: {
            diag $msg;
            my @threads;
            for (1..NumberOfIterations) {
              push @threads, async {
                Console->SetIn($sr);
              };
            }
            $_->join() for @threads;
            my $err = grep { $_->error() } @threads;
            ok !$err, "False";
          }

          Parallel: {
            diag $msg;
            my @threads;
            for (1..NumberOfIterations) {
              push @threads, async {
                Console->SetOut($sw);
              };
            }
            $_->join() for @threads;
            my $err = grep { $_->error() } @threads;
            ok !$err, "False";
          }

          Parallel: {
            diag $msg;
            my @threads;
            for (1..NumberOfIterations) {
              push @threads, async {
                Console->SetOut($sw);
              };
            }
            $_->join() for @threads;
            my $err = grep { $_->error() } @threads;
            ok !$err, "False";
          }
        }
      }
    }
  };
};

subtest 'SetStandardXXXCanBeCalledConcurrently' => sub {
  plan tests => 3;

  use constant TestChar => '+';

  lives_ok {
    using: if ( defined(my $memStream :shared = '') ) {

      using: if ( open(my $sw, '>', \$memStream) ) {

        for (my $i = 0; $i < NumberOfIterations; $i++) {
          $sw->print(TestChar);
        }

        $sw->flush();

        $sw->seek(0, 0);

        using: if ( open(my $sr, '<', \$memStream) ) {

          Console->SetIn($sr);

          Parallel: {
            diag $msg;
            my @threads;
            for (1..NumberOfIterations) {
              push @threads, async {
                return Console->Read() == ord(TestChar);
              };
            }
            my $equal = grep { $_->join() } @threads;
            is $equal, NumberOfIterations, "Equal";
          }

          # We should be at EOF now.
          TODO: {
            local $TODO = 'Read is not thread save';
            is Console->Read(), -1, 'Equal';
          }
        }
      }
    }
  };
};

done_testing;
