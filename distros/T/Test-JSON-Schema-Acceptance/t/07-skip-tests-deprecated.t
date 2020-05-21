# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test::Tester 0.108;
use Test::More 0.88;
use Test::Warnings qw(warnings had_no_warnings :no_end_test);
use Test::Deep;
use Test::JSON::Schema::Acceptance;
use lib 't/lib';
use SchemaParser;

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/subset');
my $parser = SchemaParser->new;

foreach my $test (
  # match tests by group description
  { todo_count => 3+3, skip_tests => [ 'true schema' ] },
  { todo_count => 2*(3+3), skip_tests => [ 'true schema', 'false schema' ] },

  # match tests by regexp on test description
  { todo_count => 2*(3+3), skip_tests => [ '(true|false) schema' ] },

  # match tests on both descriptions
  { todo_count => 2*(1+3+1) + 1, skip_tests => [ 'false' ] },

  # match tests on group description and test description
  { todo_count => 3*2, skip_tests => [ 'empty schema.*boolean' ] },
) {
  my $todo_count = delete $test->{todo_count};
  my @warnings;
  my ($premature, @results) = run_tests(
    sub {
      @warnings = warnings {
        $accepter->acceptance(
          validate_data => sub {
            my ($schema, $data) = @_;
            return $parser->validate_data($data, $schema);
          },
          %$test,
        );
      }
    }
  );

  is(scalar(grep $_->{type} eq 'skip', @results), 0, 'skipped no tests');
  is(scalar(grep $_->{type} eq 'todo_skip', @results), 0, 'todo_skipped no tests');
  is(scalar(grep $_->{type} eq 'todo', @results), $todo_count, $todo_count.' tests marked TODO');

  cmp_deeply(
    \@warnings,
    [ re(qr/'skip_tests' option is deprecated at /) ],
    'got deprecation warnings for skip_tests feature',
  );
}

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
