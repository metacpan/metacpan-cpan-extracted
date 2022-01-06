# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.020;
use experimental qw(signatures postderef);
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

use Test2::API 'intercept';
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::JSON::Schema::Acceptance;
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
