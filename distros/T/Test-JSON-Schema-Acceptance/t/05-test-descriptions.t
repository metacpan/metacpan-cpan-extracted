# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test::Tester 0.108;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };
use Test::JSON::Schema::Acceptance;
use lib 't/lib';
use SchemaParser;

my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/simple-booleans');
my $parser = SchemaParser->new;

my ($premature, @results) = run_tests(
  sub {
    $accepter->acceptance(sub {
      my ($schema, $input_data) = @_;
      return $parser->validate_data($input_data, $schema);
    });
  }
);

cmp_deeply(
  \@results,
  array_each(
    superhashof({
      ok => 1,
      actual_ok => 1,
      diag => '',
      reason => '',
      type => '',
      depth => 1,
    })
  ),
  'all tests pass',
);

cmp_deeply(
  [ map $_->{name}, @results ],
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
