# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

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
$accepter->acceptance(sub {
  my ($schema, $data_string) = @_;
  return $parser->validate_data($data_string, $schema);
});

is(Test::Builder->new->current_test, 1, 'no tests run when test directory is empty');

done_testing;
