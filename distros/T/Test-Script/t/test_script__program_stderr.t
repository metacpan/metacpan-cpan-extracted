use Test2::V0 -no_srand => 1;
use Test::Script;
use Probe::Perl;

my $perl = Probe::Perl->find_perl_interpreter() or die "Can't find perl";

program_runs [$perl, 't/bin/print.pl'];

is(
  intercept { program_stderr_is "Standard Error\nanother line\n" },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stderr matches';
    };
    end;
  },
  'program_stderr_is',
);

is(
  intercept { program_stderr_isnt "XXXX" },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stderr does not match';
    };
    end;
  },
  'program_stderr_isnt',
);

is(
  intercept { program_stderr_is "XXX" },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'stderr matches';
    };
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    end;
  },
  'program_stderr_is fail',
);

is(
  intercept { program_stderr_isnt "Standard Error\nanother line\n" },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'stderr does not match';
    };
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    end;
  },
  'program_stderr_isnt fail',
);

is(
  intercept { program_stderr_like qr{tandard Er} },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stderr matches';
    };
    end;
  },
  'program_stderr_like',
);

is(
  intercept { program_stderr_like qr{XXXX} },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'stderr matches';
    };
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    end;
  },
  'program_stderr_like fail',
);

is(
  intercept { program_stderr_unlike qr{XXXX} },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stderr does not match';
    };
    end;
  },
  'program_stderr_unlike',
);

is(
  intercept { program_stderr_unlike qr{tandard Er} },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'stderr does not match';
    };
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    end;
  },
  'program_stderr_unlike fail',
);

done_testing;
