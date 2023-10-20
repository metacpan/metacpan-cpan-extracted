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

use lib 't/lib';
use SchemaParser;

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/simple-booleans');
my $parser = SchemaParser->new;

my $events = intercept(
  sub {
    $accepter->acceptance(sub ($schema, $input_data) {
      return $parser->validate_data($input_data, $schema);
    });
  }
);

my @bool_tests = grep $_->isa('Test2::Event::Ok'), @$events;
is(@bool_tests, 18, 'found all the tests');

cmp_deeply(
  \@bool_tests,
  array_each(methods(
    pass => 1,
    effective_pass => 1,
  )),
  'all tests pass',
);

cmp_deeply(
  [ map $_->name, @bool_tests ],
  [
    map {
      my $file = $_;
      map {
        my $group = $_;
        map $file.'.json: "'.$group.'" - "'.$_.'"', 'integer', 'boolean false', 'boolean true'
      } 'empty schema', 'false schema', 'true schema'
    } qw(bar foo)
  ],
  'test names are shown correctly',
);

done_testing;
