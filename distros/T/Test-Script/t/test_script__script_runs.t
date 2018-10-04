use Test2::V0 -no_srand => 1;
use Test::Script;
use File::Temp qw( tempdir );
use Data::Dumper qw( Dumper );

# the first subtest replaces t/04_runs_good.t

subtest 'good' => sub {

  subtest 'default name' => sub {

    my $rv;
    my $events;

    is(
      $events = intercept { $rv = script_runs 't/bin/good.pl' },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'Script t/bin/good.pl runs';
        };
        end;
      },
      'script_runs t/bin/good.pl',
    );
    
    diag Dumper($events) unless $rv;

    is $rv, T(), 'script_compiles_ok returns true as convenience';

  };

  subtest 'custom name' => sub {

    my $rv;
    my $events;

    is(
      $events = intercept { $rv = script_runs 't/bin/good.pl', 'It worked' },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'It worked';
        };
        end;
      },
      'script_runs t/bin/good.pl It worked',
    );

    diag Dumper($events) unless $rv;

    is $rv, T(), 'script_compiles_ok returns true as convenience';
    
  };


};

subtest 'bad: returns 4' => sub {

  subtest 'default name' => sub {

    my $rv;
    my $events;

    my $rv2 = is(
      $events = intercept { $rv = script_runs 't/bin/four.pl' },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'Script t/bin/four.pl runs';
        };
        event Diag => sub {};
        event Diag => sub {
          call message => match qr{4 - (?:Using.*\n# )?Standard Error\n};
        };
        end;
      },
      'script_runs t/bin/good.pl',
    );

    diag Dumper($events) unless $rv2;

    is $rv, F(), 'script_compiles_ok returns false as convenience';
    
  };
  
  subtest 'custom name' => sub {

    my $rv;
    my $events;

    my $rv2 = is(
      $events = intercept { $rv = script_runs 't/bin/four.pl', 'It worked' },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'It worked';
        };
        event Diag => sub {};
        event Diag => sub {
          call message => match qr{4 - (?:Using.*\n# )?Standard Error\n};
        };
        end;
      },
      'script_runs t/bin/good.pl It worked',
    );

    diag Dumper($events) unless $rv2;

    is $rv, F(), 'script_compiles_ok returns false as convenience';
    
  };


};

subtest 'unreasonable number of libs' => sub {

  skip_all 'developer only test' unless $ENV{TEST_SCRIPT_DEV_TEST};

  local @INC = @INC;
  my $dir = tempdir( CLEANUP => 1 );
  for(map { File::Spec->catfile($dir, $_) } 1..1000000)
  {
    #mkdir;
    push @INC, $_;
  }

  script_runs 't/bin/good.pl';

};

subtest 'stdin' => sub {

  script_compiles 't/bin/stdin.pl';

  # see https://github.com/plicease/Test-Script/issues/23

  subtest 'filename' => sub {

    script_runs     't/bin/stdin.pl', { stdin => 't/bin/stdin.txt' };
    script_stdout_like qr{fbbbaz};
  
  };

  subtest 'scalar ref' => sub {

    script_runs     't/bin/stdin.pl', { stdin => \'helloooo there' };
    script_stdout_like qr{hellbbbb there};
  
  };
  
};

subtest exception => sub {

  my $events;
  
  is(
    $events = intercept { script_runs( 't/bin/missing.pl' ) },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'Script t/bin/missing.pl runs';
      };
      event Diag => sub {};
      event Diag => sub { call message => match(qr{^2 - })};
      end;
    },
  );

};

subtest 'signal' => sub {

  skip_all 'not on Winows' if $^O eq 'MSWin32';

  my $events;
  
  is(
    $events = intercept { script_runs( 't/bin/signal.pl' ) },
    array {
      event Ok => sub {
        call pass => F();
      };
      event Diag => sub {};
      event Diag => sub { call message => '0 - ' };
      event Diag => sub { call message => 'signal: 9' };
      end;
    },
  );

};

subtest 'non-zero exit' => sub {

  is(
    intercept { script_runs 't/bin/four.pl', { exit => 4 } },
    array {
      event Ok => sub {
        call pass => T();
      };
      end;
    },
  );

};

subtest 'signal' => sub {

  skip_all 'not for windows' if $^O eq 'MSWin32';

  is(
    intercept { script_runs 't/bin/signal.pl', { signal => 9 } },
    array {
      event Ok => sub {
        call pass => T();
      };
      end;
    },
  );

};

subtest 'scalar ref' => sub {

  my $stdout = '';
  my $stderr = '';

  script_runs 't/bin/print.pl', { stdout => \$stdout, stderr => \$stderr };

  is $stdout, "Standard Out\nsecond line\n";
  is $stderr, "Standard Error\nanother line\n";

};

subtest 'interpreter_options' => sub {

  script_runs 't/bin/warnon.pl', { interpreter_options => [ '-w' ] }, 'as array reference';
  script_runs 't/bin/warnon.pl', { interpreter_options => '-w' }, 'as string';

};

script_runs 't/bin/taint.pl';

done_testing;
