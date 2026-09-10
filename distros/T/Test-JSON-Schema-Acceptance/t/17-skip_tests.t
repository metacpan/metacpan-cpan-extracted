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
use Test2::V0 qw(!bag !bool), -no_pragmas => 1;
use if $ENV{AUTHOR_TESTING}, 'Test2::Warnings';
use Test::JSON::Schema::Acceptance;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };

use lib 't/lib';
use SchemaParser;
use Helper;

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/subset');
my $parser = SchemaParser->new;

foreach my $test (
  # match tests in this file
  { todo_count => 0, skip_tests => [ { file => 'foo.json' } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 0, fail => 9 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 0, todo_fail => 0, fail => 0 },
    ],
  },
) {
  my $events = intercept(
    sub {
      $accepter->acceptance(
        validate_data => sub ($schema, $data) {
          return $parser->validate_data($data, $schema);
        },
        %$test,
      );
    }
  );

  is(scalar(grep $_->isa('Test2::Event::Skip'), @$events), 3, 'skipped some tests');

  cmp_result(
    $accepter->results,
    $test->{results},
    'result data was populated',
  );
}

done_testing;
