# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test2::API 'intercept';
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::JSON::Schema::Acceptance;
use lib 't/lib';
use SchemaParser;

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/subset');
my $parser = SchemaParser->new;

foreach my $test (
  # match tests in this file
  { todo_count => 9, todo_tests => [ { file => 'foo.json' } ] },

  # match tests in these files
  { todo_count => 9+3, todo_tests => [ { file => [ 'foo.json', 'baz.json' ] } ] },

  # match tests in any file, with this group description
  { todo_count => 3+3, todo_tests => [ { group_description => 'false schema' } ] },

  # match tests in this file with this group description
  { todo_count => 3, todo_tests => [ { file => 'foo.json', group_description => 'false schema' } ] },

  # match tests in this file with these group descriptions
  {
    todo_count => 3+3,
    todo_tests => [ { file => 'foo.json', group_description => [ 'true schema', 'false schema' ] } ],
  },

  # match tests in this file with this group description and test description
  { todo_count => 1, todo_tests => [ {
      file => 'foo.json',
      group_description => 'true schema',
      test_description => 'boolean false',
    } ]
  },

  # match tests in this file with this group description and these test descriptions
  { todo_count => 2, todo_tests => [ {
      file => 'bar.json',
      group_description => 'false schema',
      test_description => [ 'boolean true', 'boolean false' ],
    } ]
  },

  # match tests in any file with this group description and this test description
  { todo_count => 1+1+1, todo_tests => [ {
      group_description => 'empty schema',
      test_description => [ 'boolean true' ],
    } ]
  },

  # match tests in any file with any group description with this test description
  { todo_count => 3+3+1, todo_tests => [ { test_description => [ 'boolean true' ] } ] },

  # match tests with multiple specifications at once
  { todo_count => 9+3, todo_tests => [ { file => 'foo.json' }, { group_description => 'true schema' } ] },
) {
  my $todo_count = delete $test->{todo_count};
  my $events = intercept(
    sub {
      $accepter->acceptance(
        validate_data => sub {
          my ($schema, $data) = @_;
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
    'right number of tests are marked TODO',
  );
}

done_testing;
