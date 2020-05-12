# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use Test::Deep;
use Test::JSON::Schema::Acceptance;

my $accepter = Test::JSON::Schema::Acceptance->new(specification => 'draft2019-09', include_optional => 1);

cmp_deeply(
  $accepter->_test_data,
  supersetof(
    superhashof({ file => str('optional/bignum.json') }),
    superhashof({ file => str('optional/format/uri.json') }),
  ),
  'picked up optional files in test_data',
);

done_testing;
