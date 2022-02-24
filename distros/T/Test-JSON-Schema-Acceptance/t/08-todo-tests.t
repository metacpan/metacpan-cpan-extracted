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
use Test::Deep;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::JSON::Schema::Acceptance;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };

use lib 't/lib';
use SchemaParser;

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/subset');
my $parser = SchemaParser->new;

# bar contains only failing tests (3x3)
# baz contains only passing tests (3)
# foo contains only passing tests (3x3)

foreach my $test (
  # match tests in this file
  { todo_count => 9, todo_tests => [ { file => 'foo.json' } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 0, fail => 9 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 9, todo_fail => 0, fail => 0 },
    ],
  },

  # match tests in these files
  { todo_count => 9+3, todo_tests => [ { file => [ 'foo.json', 'baz.json' ] } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 0, fail => 9 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 9, todo_fail => 0, fail => 0 },
    ],
  },

  # match tests in any file, with this group description
  { todo_count => 3+3, todo_tests => [ { group_description => 'false schema' } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 3, fail => 6 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 9, todo_fail => 0, fail => 0 },
    ],
  },

  # match tests in this file with this group description
  { todo_count => 3, todo_tests => [ { file => 'foo.json', group_description => 'false schema' } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 0, fail => 9 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 9, todo_fail => 0, fail => 0 },
    ],
  },

  # match tests in this file with these group descriptions
  {
    todo_count => 3+3,
    todo_tests => [ { file => 'foo.json', group_description => [ 'true schema', 'false schema' ] } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 0, fail => 9 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 9, todo_fail => 0, fail => 0 },
    ],
  },

  # match tests in this file with this group description and test description
  { todo_count => 1, todo_tests => [ {
      file => 'foo.json',
      group_description => 'true schema',
      test_description => 'boolean false',
    } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 0, fail => 9 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 9, todo_fail => 0, fail => 0 },
    ],
  },

  # match tests in this file with this group description and these test descriptions
  { todo_count => 2, todo_tests => [ {
      file => 'bar.json',
      group_description => 'false schema',
      test_description => [ 'boolean true', 'boolean false' ],
    } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 2, fail => 7 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 9, todo_fail => 0, fail => 0 },
    ],
  },

  # match tests in any file with this group description and this test description
  { todo_count => 1+1+1, todo_tests => [ {
      group_description => 'empty schema',
      test_description => [ 'boolean true' ],
    } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 1, fail => 8 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 9, todo_fail => 0, fail => 0 },
    ],
  },

  # match tests in any file with any group description with this test description
  { todo_count => 3+3+1, todo_tests => [ { test_description => [ 'boolean true' ] } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 3, fail => 6 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 9, todo_fail => 0, fail => 0 },
    ],
  },

  # match tests with multiple specifications at once
  { todo_count => 9+3, todo_tests => [ { file => 'foo.json' }, { group_description => 'true schema' } ],
    results => [
      { file => str('bar.json'), pass => 0, todo_fail => 3, fail => 6 },
      { file => str('baz.json'), pass => 3, todo_fail => 0, fail => 0 },
      { file => str('foo.json'), pass => 9, todo_fail => 0, fail => 0 },
    ],
  },
) {
  my $todo_count = delete $test->{todo_count};
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

  is(scalar(grep $_->isa('Test2::Event::Skip'), @$events), 0, 'skipped and todo_skipped no tests');
  is(
    scalar(
      grep exists $_->{assert} && (grep $_->{tag} eq 'TODO', @{$_->{amnesty} // []}),
      map $_->facet_data, @$events
    ),
    $todo_count,
    'right number of tests are marked TODO ('.$todo_count.')',
  );

  cmp_deeply(
    $accepter->results,
    $test->{results},
    'result data was populated',
  );
}

done_testing;
