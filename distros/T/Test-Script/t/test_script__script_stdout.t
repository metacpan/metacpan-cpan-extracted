use Test2::V0 -no_srand => 1;
use Test::Script;

script_runs 't/bin/print.pl';

is(
  intercept { script_stdout_is "Standard Out\nsecond line\n" },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stdout matches';
    };
    end;
  },
  'script_stdout_is',
);
  
is(
  intercept { script_stdout_isnt "XXXX" },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stdout does not match';
    };
    end;
  },
  'script_stdout_isnt',
);

is(
  intercept { script_stdout_is "XXX" },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'stdout matches';
    };
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    end;
  },
  'script_stdout_is fail',
);
  
is(
  intercept { script_stdout_isnt "Standard Out\nsecond line\n" },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'stdout does not match';
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
  'script_stdout_isnt fail',
);

is(
  intercept { script_stdout_like qr{tandard Ou} },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stdout matches';
    };
    end;
  },
  'script_stdout_like',
);

is(
  intercept { script_stdout_like qr{XXXX} },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'stdout matches';
    };
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    end;
  },
  'script_stdout_like fail',
);

is(
  intercept { script_stdout_unlike qr{XXXX} },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'stdout does not match';
    };
    end;
  },
  'script_stdout_unlike',
);

is(
  intercept { script_stdout_unlike qr{tandard Ou} },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'stdout does not match';
    };
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    event Diag => sub {};
    end;
  },
  'script_stdout_unlike fail'
);

done_testing;
