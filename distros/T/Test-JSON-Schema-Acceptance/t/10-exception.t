# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test::Tester 0.108;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::JSON::Schema::Acceptance;

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/bad');

my ($premature, @results) = run_tests(
  sub {
    $accepter->acceptance(
      validate_data => sub {
        my ($schema, $data) = @_;
        die 'ach I am slain' if $data->{exception};
        return 1;
      },
      tests => { file => 'invalid-schema.json' },
    );
  }
);

cmp_deeply(
  \@results,
  [
    superhashof({
      name => 'invalid-schema.json: "exception handling" - "no exception; expect invalid: want test failure"',
      ok => 0,
    }),
    superhashof({
      name => 'invalid-schema.json: "exception handling" - "no exception; expect valid: want test pass"',
      ok => 1,
    }),
    superhashof({
      name => re(qr/^\Qinvalid-schema.json: "exception handling" - "exception; expect invalid: want test failure (via exception)" died: ach I am slain\E/),
      ok => 0,
    }),
    superhashof({
      name => re(qr/^\Qinvalid-schema.json: "exception handling" - "exception; expect valid: want test failure (via exception)" died: ach I am slain\E/),
      ok => 0,
    }),
  ],
  'four tests, all with correct results',
);

done_testing;
