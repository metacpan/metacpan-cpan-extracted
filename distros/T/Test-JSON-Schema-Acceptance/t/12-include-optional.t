# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::JSON::Schema::Acceptance;

my $accepter = Test::JSON::Schema::Acceptance->new(
  test_dir => 't/tests/include_optional',
  include_optional => 1,
);

cmp_deeply(
  $accepter->_test_data,
  [
    { file => str('foo.json'), json => ignore },
    { file => str('zulu.json'), json => ignore },
    { file => str('extra/foo.json'), json => ignore },
    { file => str('optional/alpha.json'), json => ignore },
    { file => str('optional/beta.json'), json => ignore },
  ],
  'picked up optional files in test_data, in the correct order',
);

done_testing;
