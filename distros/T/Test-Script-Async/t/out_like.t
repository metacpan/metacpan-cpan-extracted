use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Script::Async;

plan 9;

my $run = script_runs 'corpus/output.pl';

is(
  intercept { $run->out_like(qr{out thr}) },
  array {
    event Ok => sub {
      call pass => T();
      call name => match qr{^standard output matches};
    };
    end;
  },
  "out_like good",
);

is(
  intercept { $run->out_like(qr{bogus}) },
  array {
    event Ok => sub {
      call pass => F();
      call name => match qr{^standard output matches};
    };
    end;
  },
  "out_like bad",
);

is(
  intercept { $run->out_unlike(qr{out thr}) },
  array {
    event Ok => sub {
      call pass => F();
      call name => match qr{^standard output does not match};
    };
    event Diag => sub {
      call message => 'line 3 of standard output matches: stdout three';
    };
    end;
  },
  "out_unlike bad",
);

is(
  intercept { $run->out_unlike(qr{bogus}) },
  array {
    event Ok => sub {
      call pass => T();
      call name => match qr{^standard output does not match};
    };
    end;
  },
  "out_unlike good",
);


#====================


is(
  intercept { $run->err_like(qr{err thr}) },
  array {
    event Ok => sub {
      call pass => T();
      call name => match qr{^standard error matches};
    };
    end;
  },
  "err_like good",
);

is(
  intercept { $run->err_like(qr{bogus}) },
  array {
    event Ok => sub {
      call pass => F();
      call name => match qr{^standard error matches};
    };
    end;
  },
  "err_like bad",
);

is(
  intercept { $run->err_unlike(qr{err thr}) },
  array {
    event Ok => sub {
      call pass => F();
      call name => match qr{^standard error does not match};
    };
    event Diag => sub {
      call message => 'line 3 of standard error matches: stderr three';
    };
    end;
  },
  "err_unlike bad",
);

is(
  intercept { $run->err_unlike(qr{bogus}) },
  array {
    event Ok => sub {
      call pass => T();
      call name => match qr{^standard error does not match};
    };
    end;
  },
  "err_unlike good",
);


