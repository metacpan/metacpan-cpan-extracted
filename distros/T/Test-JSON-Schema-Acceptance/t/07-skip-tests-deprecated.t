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
use Test2::V0 qw(!bag !bool !warnings), -no_pragmas => 1;
use Test2::Warnings qw(warnings had_no_warnings :no_end_test);
use Test::JSON::Schema::Acceptance;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };

use lib 't/lib';
use SchemaParser;
use Helper;

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

  cmp_result(
    \@warnings,
    [ re(qr/'skip_tests' option is deprecated at /) ],
    'got deprecation warnings for skip_tests feature',
  );
}

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
