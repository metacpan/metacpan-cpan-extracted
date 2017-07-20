use Test2::V0 -no_srand => 1;
use Test::Script;

script_runs 't/bin/print.pl';

is(
  intercept { script_stderr_is "Standard Error\nanother line\n" },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stderr matches';
    };
    end;
  },
  'script_stderr_is',
);

is(
  intercept { script_stderr_isnt "XXXX" },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stderr does not match';
    };
    end;
  },
  'script_stderr_isnt',
);

is(
  intercept { script_stderr_is "XXX" },
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
  'script_stderr_is fail',
);

is(
  intercept { script_stderr_isnt "Standard Error\nanother line\n" },
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
  'script_stderr_isnt fail',
);

is(
  intercept { script_stderr_like qr{tandard Er} },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stderr matches';
    };
    end;
  },
  'script_stderr_like',
);

is(
  intercept { script_stderr_like qr{XXXX} },
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
  'script_stderr_like fail',
);

is(
  intercept { script_stderr_unlike qr{XXXX} },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stderr does not match';
    };
    end;
  },
  'script_stderr_unlike',
);

is(
  intercept { script_stderr_unlike qr{tandard Er} },
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
  'script_stderr_unlike fail',
);

done_testing;
