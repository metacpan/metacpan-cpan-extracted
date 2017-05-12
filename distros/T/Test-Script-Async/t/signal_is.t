use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Script::Async;

plan 11;

my $run = bless { signal => 9, exit => 0 }, 'Test::Script::Async';

is(
  intercept { $run->signal_is(9) },
  array {
    event Ok => sub {
      call pass => T();
      call name => "script killed by signal 9";
    };
    end;
  },
  "signal_is good",
);

is(
  intercept { $run->signal_is(10) },
  array {
    event Ok => sub {
      call pass => F();
      call name => "script killed by signal 10";
    };
    event Diag => sub {
      call message => 'script killed with signal 9';
    };
    end;
  },
  "signal_is bad",
);


is(
  intercept { $run->signal_isnt(9) },
  array {
    event Ok => sub {
      call pass => F();
      call name => "script not killed by signal 9";
    };
    event Diag => sub {
      call message => 'script killed with signal 9';
    };
    end;
  },
  "signal_isnt bad",
);


is(
  intercept { $run->signal_isnt(10) },
  array {
    event Ok => sub {
      call pass => T();
      call name => "script not killed by signal 10";
    };
    end;
  },
  "signal_isnt good",
);

is(
  intercept { $run->signal_is(9, 'custom') },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'custom';
    };
    end;
  },
  "signal_is custom name",
);
  
is(
  intercept { $run->signal_isnt(10, 'custom') },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'custom';
    };
    end;
  },
  "signal_isnt custom name",
);
  
$run = script_runs(['corpus/exit.pl',22]);

is(
  intercept { $run->signal_is(9) },
  array {
    event Ok => sub {
      call pass => F();
    };
    event Diag => sub {
      call message => 'script exited with value 22';
    };
    end;
  },
  "signal_is with exit",
);

is(
  intercept { $run->signal_isnt(9) },
  array {
    event Ok => sub {
      call pass => F();
    };
    event Diag => sub {
      call message => 'script exited with value 22';
    };
    end;
  },
  "signal_isnt with exit",
);

intercept { $run = script_runs('corpus/bogus.pl') };

is(
  intercept { $run->signal_is(9) },
  array {
    event Ok => sub {
      call pass => F();
    };
    event Diag => sub {
      call message => 'script did not run so was not killed';
    };
    end;
  },
  'signal_is with bogus'
);

is(
  intercept { $run->signal_isnt(9) },
  array {
    event Ok => sub {
      call pass => F();
    };
    event Diag => sub {
      call message => 'script did not run so was not killed';
    };
    end;
  },
  'signal_isnt with bogus'
);
