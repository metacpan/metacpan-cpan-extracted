use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Script::Async;

plan 8;

is(
  intercept { script_runs "corpus/good.pl" },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'Script corpus/good.pl runs';
    };
    end;
  },
  "runs good without arguments",
);

is(
  intercept { script_runs "corpus/good.pl", 'my name' },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'my name';
    };
    end;
  },
  "runs good with name",
);

is(
  intercept { script_runs ["corpus/good.pl", 'one', 'two'] },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'Script corpus/good.pl runs with arguments one two';
    };
    end;
  },
  "runs good with arguments",
);

is(
  intercept { script_runs "corpus/bogus.pl" },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'Script corpus/bogus.pl runs';
    };
    event Diag => sub {
      call message => 'script does not exist';
    };
    end;
  },
  "fails on script does not exist",
);

my $run = script_runs "corpus/args.pl";
is $run->out, ['no arguments'], 'no arguments passed';

$run = script_runs ["corpus/args.pl", qw( one two three )];
is $run->out, [qw( arg0=one arg1=two arg2=three )], 'arguments passed';
