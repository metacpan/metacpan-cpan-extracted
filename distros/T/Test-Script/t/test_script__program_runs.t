use Test2::V0 -no_srand => 1;
use Test::Script;
use File::Temp qw( tempdir );
use Data::Dumper qw( Dumper );
use Probe::Perl;

# Use the Perl interpreter as the program since it's the only one we know
# exists.  The files in t/bin do not use any modules, so we don't have
# to worry about passing @INC down.
my $perl = Probe::Perl->find_perl_interpreter() or die "Can't find perl";

subtest 'no interpreter_options' => sub {
  like(
    dies { program_runs $perl, { interpreter_options => 1 } },
    qr{interpreter_options},
    'program_runs rejects {interpreter_options => ...}'
  );
};

subtest 'good' => sub {

  subtest 'default name' => sub {

    my $rv;
    my $events;

    is(
      $events = intercept { $rv = program_runs [$perl, 't/bin/good.pl'] },
      array {
        event Ok => sub {
          call pass => T();
          call name => "Program $perl runs";
        };
        end;
      },
      'program_runs: perl t/bin/good.pl',
    );

    diag Dumper($events) unless $rv;

    is $rv, T(), 'program_runs returns true as convenience';

  };

  subtest 'custom name' => sub {

    my $rv;
    my $events;

    is(
      $events = intercept { $rv = program_runs [$perl, 't/bin/good.pl'], 'It worked' },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'It worked';
        };
        end;
      },
      'program_runs perl t/bin/good.pl It worked',
    );

    diag Dumper($events) unless $rv;

    is $rv, T(), 'program_runs returns true as convenience';

  };

};

subtest 'bad: returns 4' => sub {

  subtest 'default name' => sub {

    my $rv;
    my $events;

    my $rv2 = is(
      $events = intercept { $rv = program_runs [$perl, 't/bin/four.pl'] },
      array {
        event Ok => sub {
          call pass => F();
          call name => "Program $perl runs";
        };
        event Diag => sub {};
        event Diag => sub {
          call message => match qr{4 - (?:Using.*\n# )?Standard Error\n};
        };
        end;
      },
      'program_runs perl t/bin/good.pl',
    );

    diag Dumper($events) unless $rv2;

    is $rv, F(), 'program_runs returns false as convenience';

  };

  subtest 'custom name' => sub {

    my $rv;
    my $events;

    my $rv2 = is(
      $events = intercept { $rv = program_runs [$perl, 't/bin/four.pl'], 'It worked' },
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
      'program_runs perl t/bin/good.pl It worked',
    );

    diag Dumper($events) unless $rv2;

    is $rv, F(), 'program_runs returns false as convenience';

  };

};

subtest 'stdin' => sub {

  # see https://github.com/plicease/Test-Script/issues/23

  subtest 'filename' => sub {

    program_runs     [$perl, 't/bin/stdin.pl'], { stdin => 't/bin/stdin.txt' };
    program_stdout_like qr{fbbbaz};

  };

  subtest 'scalar ref' => sub {

    program_runs     [$perl, 't/bin/stdin.pl'], { stdin => \'helloooo there' };
    program_stdout_like qr{hellbbbb there};

  };

};

subtest exception => sub {

  my $events;

  is(
    $events = intercept { program_runs( [$perl, 't/bin/missing.pl'] ) },
    array {
      event Ok => sub {
        call pass => F();
        call name => "Program $perl runs";
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
    $events = intercept { program_runs( [$perl, 't/bin/signal.pl'] ) },
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
    intercept { program_runs [$perl, 't/bin/four.pl'], { exit => 4 } },
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
    intercept { program_runs [$perl, 't/bin/signal.pl'], { signal => 9 } },
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

  program_runs [$perl, 't/bin/print.pl'], { stdout => \$stdout, stderr => \$stderr };

  is $stdout, "Standard Out\nsecond line\n";
  is $stderr, "Standard Error\nanother line\n";

};

done_testing;
