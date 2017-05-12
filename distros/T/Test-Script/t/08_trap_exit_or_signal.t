use strict;
use warnings;
use Test::Tester;
use Test::More tests => 2;
use Test::Script;

subtest 'non-zero exit' => sub {
  check_test( sub {
      script_runs 't/bin/four.pl', { exit => 4 };
    }, {
      ok => 1,
    },
    'script_runs',
  );
};

subtest 'signal' => sub {
  plan skip_all => 'not for windows' if $^O eq 'MSWin32';
  my(undef, $r) = check_test( sub {
      script_runs 't/bin/signal.pl', { signal => 9 };
    }, {
      ok => 1,
    },
    'script_runs',
  );
};
