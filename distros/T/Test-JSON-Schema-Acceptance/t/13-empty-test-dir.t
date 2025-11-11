# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.020;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';

use Test2::API 'intercept';
use Test2::V0 -no_pragmas => 1;
use if $ENV{AUTHOR_TESTING}, 'Test2::Warnings';
use Test::JSON::Schema::Acceptance;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };

use lib 't/lib';
use SchemaParser;

my $accepter = Test::JSON::Schema::Acceptance->new(
  test_dir => 't/tests/empty',
  include_optional => 1,
);

is(@{$accepter->_test_data}, 0, 'an empty test directory means no test data');

my $parser = SchemaParser->new;
my $events = intercept(
  sub {
    $accepter->acceptance(sub ($schema, $data) {
      return $parser->validate_data($data, $schema);
    });
  }
);

is(
  scalar(grep exists $_->{assert}, map $_->facet_data, @$events),
  0,
  'no tests are run when test directory is empty',
);

done_testing;
