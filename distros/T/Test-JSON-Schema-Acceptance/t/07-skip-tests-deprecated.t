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
use Test::Warnings 'warnings';
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
  my $events = intercept(
    sub {
      @warnings = warnings {
        $accepter->acceptance(
          validate_data => sub ($schema, $data) {
            return $parser->validate_data($data, $schema);
          },
          %$test,
        );
      }
    }
  );

  is(scalar(grep $_->isa('Test2::Event::Skip'), @$events), 0, 'skipped and todo_skipped no tests');
  is(
    scalar(
      grep exists $_->{assert} && (grep $_->{tag} eq 'TODO', @{$_->{amnesty} // []}),
      map $_->facet_data, @$events
    ),
    $todo_count,
    $todo_count.' tests are marked TODO',
  );

  cmp_deeply(
    \@warnings,
    [ re(qr/'skip_tests' option is deprecated at /) ],
    'got deprecation warnings for skip_tests feature',
  );
}

done_testing;
