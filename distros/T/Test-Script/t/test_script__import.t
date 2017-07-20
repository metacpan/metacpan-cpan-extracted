use Test2::V0 -no_srand => 1;
use Test::Script ();

is(
  intercept { Test::Script->import(tests => 42) },
  array {
    event Plan => sub {
      call directive => '';
      call max => 42;
    };
  },
  'with tests',
);

is(
  intercept { Test::Script->import(skip_all => 'foo') },
  array {
    event Plan => sub {
      call directive => 'SKIP';
      call reason => 'foo';
    };
  },
  'with skip',
);

is(
  intercept { Test::Script->import('no_plan'); done_testing },
  array {
    event Plan => sub {
    };
  },
  'with no plan',
);

done_testing;
