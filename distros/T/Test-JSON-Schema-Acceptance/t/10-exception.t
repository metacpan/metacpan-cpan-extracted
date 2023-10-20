# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

use Test2::API 'intercept';
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::JSON::Schema::Acceptance;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/bad');

my $events = intercept(
  sub {
    $accepter->acceptance(
      validate_data => sub ($schema, $data) {
        die 'ach I am slain' if $data->{exception};
        return 1;
      },
      tests => { file => 'invalid-schema.json' },
    );
  }
);

cmp_deeply(
  [ map exists $_->{parent}
      ? {
          details => $_->{assert}{details},
          pass => $_->{assert}{pass},
          children => [ map exists $_->{assert} ? $_->{assert} : (), @{$_->{parent}{children}} ],
        }
      : (),
      map $_->facet_data, @$events ],
  [
    {
      details => 'invalid-schema.json: "exception handling" - "no exception; expect invalid: want test failure"',
      pass => 0,
      children => [
        superhashof({
          details => 'evaluation result is incorrect',
          pass => 0,
        }),
      ],
    },
    {
      details => 'invalid-schema.json: "exception handling" - "no exception; expect valid: want test pass"',
      pass => 1,
      children => [
        superhashof({
          details => 'test passes: data is valid: true',
          pass => 1,
        }),
      ],
    },
    {
      details => 'invalid-schema.json: "exception handling" - "exception; expect invalid: want test failure (via exception)"',
      pass => 0,
      children => [
        superhashof({
          details => re(qr/^died: ach I am slain /),
          pass => 0,
        }),
      ],
    },
    {
      details => 'invalid-schema.json: "exception handling" - "exception; expect valid: want test failure (via exception)"',
      pass => 0,
      children => [
        superhashof({
          details => re(qr/^died: ach I am slain /),
          pass => 0,
        }),
      ],
    },
  ],
  'four tests, all with correct results',
);

done_testing;
