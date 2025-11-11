# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';

use Test2::V0 qw(!bag !bool), -no_pragmas => 1;
use if $ENV{AUTHOR_TESTING}, 'Test2::Warnings';
use Test::JSON::Schema::Acceptance;

use lib 't/lib';
use Helper;

my $accepter = Test::JSON::Schema::Acceptance->new(
  test_dir => 't/tests/include_optional',
  include_optional => 1,
);

cmp_result(
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
