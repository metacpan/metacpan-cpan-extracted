use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Script::Async;

plan 5;

is(
  intercept { script_runs(["corpus/exit.pl", 22])->exit_is(22)->exit_isnt(22) },
  array {
    event Ok => sub {
      call pass => T();
    };
    event Ok => sub {
      call pass => T();
      call name => 'script exited with value 22';
    };
    event Ok => sub {
      call pass => F();
      call name => 'script exited with a value other than 22';
    };
    event Diag => sub {
      call message => 'script exited with value 22';
    };
    end;
  },
  "exit_is good",
);

is(
  intercept { script_runs(["corpus/exit.pl", 42])->exit_is(22)->exit_isnt(22) },
  array {
    event Ok => sub {
      call pass => T();
    };
    event Ok => sub {
      call pass => F();
      call name => 'script exited with value 22';
    };
    event Diag => sub {
      call message => 'script exited with value 42';
    };
    event Ok => sub {
      call pass => T();
      call name => 'script exited with a value other than 22';
    };
    end;
  },
  "exit_is bad",
);

is(
  intercept { script_runs(["corpus/exit.pl", 22])->exit_is(22,'custom name')->exit_isnt(42, 'custom name 2') },
  array {
    event Ok => sub {
      call pass => T();
    };
    event Ok => sub {
      call pass => T();
      call name => 'custom name';
    };
    event Ok => sub {
      call pass => T();
      call name => 'custom name 2';
    };
    end;
  },
  "exit_is with custom name"
);

is(
  intercept { script_runs("corpus/bogus.pl")->exit_is(22)->exit_isnt(22) },
  array {
    event Ok => sub {
      call pass => F();
    };
    event Diag => sub {};
    event Ok => sub {
      call pass => F();
      call name => 'script exited with value 22';
    };
    event Diag => sub {
      call message => 'script did not run so did not exit';
    };
    event Ok => sub {
      call pass => F();
      call name => 'script exited with a value other than 22';
    };
    event Diag => sub {
      call message => 'script did not run so did not exit';
    };
    end;
  },
  "exit_is with failed script_runs",
);

my $run = bless { signal => 9, exit => 0 }, 'Test::Script::Async';

is(
  intercept { $run->exit_is(0)->exit_isnt(0) },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'script exited with value 0';
    };
    event Diag => sub {
      call message => 'script killed with signal 9';
    };
    event Ok => sub {
      call pass => F();
      call name => 'script exited with a value other than 0';
    };
    event Diag => sub {
      call message => 'script killed with signal 9';
    };
    end;
  },
  "exit_is with signal",
);
