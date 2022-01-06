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
use Test::Deep;

use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use Test::JSON::Schema::Acceptance;
use lib 't/lib';
use SchemaParser;

my $accepter = Test::JSON::Schema::Acceptance->new(7);

my $line;
my $parser = SchemaParser->new;
my $events = intercept(
  sub {
    $accepter->acceptance(sub ($schema, $data_string) {
      return $parser->validate_json_string($data_string, $schema);
    # we didn't adjust level, so test appears to originate where the subref ends
    }); $line = __LINE__;
  }
);

cmp_deeply(
  $events->[0],
  all(
    isa('Test2::Event::Note'),
    methods(message => 'running tests in '.$accepter->test_dir.' against draft7...'),
  ),
  'first test event is the note',
);

my @bool_tests = grep $_->isa('Test2::Event::Ok') && $_->name =~ /boolean type matches booleans/,
  @$events;
is(@bool_tests, 10, 'found all the tests that check for boolean type');

cmp_deeply(
  \@bool_tests,
  array_each(methods(
    pass => 1,
    effective_pass => 1,
    trace => methods(
      frame => [ 'main', __FILE__, $line, 'Test::JSON::Schema::Acceptance::acceptance' ],
    ),
  )),
  'tests pass for checking schemas that test for boolean type',
);

done_testing;
