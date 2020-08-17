# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test2::API 'intercept';
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;

use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use Test::JSON::Schema::Acceptance;
use lib 't/lib';
use SchemaParser;

# this is just like t/01-basic.t only it uses the non-deprecated form of the "validate as a
# json string" interface.

my $accepter = Test::JSON::Schema::Acceptance->new(specification => 'draft7');

my $parser = SchemaParser->new;
my $events = intercept(
  sub {
    $accepter->acceptance(validate_json_string => sub {
      my ($schema, $data_string) = @_;
      return $parser->validate_json_string($data_string, $schema);
    });
  }
);

my @bool_tests = grep $_->isa('Test2::Event::Ok') && $_->name =~ /boolean type matches booleans/,
  @$events;
is(@bool_tests, 10, 'found all the tests that check for boolean type');

cmp_deeply(
  \@bool_tests,
  array_each(methods(
    pass => 1,
    effective_pass => 1,
  )),
  'tests pass for checking schemas that test for boolean type',
);

done_testing;
