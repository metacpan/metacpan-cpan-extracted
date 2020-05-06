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

# this is similar to t/01-basic.t only it uses the new option to pass a "validate as inflated
# data" subref.

my $accepter = Test::JSON::Schema::Acceptance->new(specification => 'draft7');

my $parser = SchemaParser->new;
my ($premature, @results) = run_tests(
  sub {
    $accepter->acceptance(validate_data => sub {
      my ($schema, $data) = @_;
      return $parser->validate_data($data, $schema);
    });
  }
);

cmp_deeply(
  [ grep $_->{name} =~ /^boolean type matches booleans/, @results ],
  array_each(superhashof({ ok => 1 })),
  'tests pass for checking schemas that test for boolean type',
);

done_testing;
