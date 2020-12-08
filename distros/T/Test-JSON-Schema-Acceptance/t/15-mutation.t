# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
no if "$]" >= 5.031009, feature => 'indirect';

use Test2::API 'intercept';
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::JSON::Schema::Acceptance;

my $key = 'a';

foreach my $test (
  [ 'autovivification' => sub {
    my ($thing) = shift;
    $thing->{(keys %$thing)[0]}{$key++} = 'this should not be here';
  } ],
  [ 'string->integer type mutation' => sub {
    my ($thing) = shift;
    $thing->{foo}{string} += 0;
  } ],
  [ 'integer->string type mutation' => sub {
    my ($thing) = shift;
    $thing->{foo}{int} .= '';
  } ],
  [ 'blessed hash replacement' => sub {
    my ($thing) = shift;
    $thing->{foo} = bless($thing->{foo}, 'MyHash');
  } ],
  [ 'tied hash replacement' => sub {
    my ($thing) = shift;
    my %hash;
    tie(%hash, 'Tie::StdHash');
    @hash{keys %{$thing->{foo}}} = values %{$thing->{foo}};
    $thing->{foo} = \%hash;
  } ],
)
{
  my ($test_name, $mutator) = @$test;

  foreach my $type (qw(data schema)) {
    my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/mutation');
    my $events = intercept(
      sub {
        $accepter->acceptance(validate_data => sub {
          my ($schema, $data) = @_;
          $mutator->($type eq 'data' ? $data : $type eq 'schema' ? $schema : die "$type?!");

          return 1;
        });
      }
    );

    cmp_deeply(
      [ map exists $_->{parent}
          ? {
              details => $_->{assert}{details},
              pass => $_->{assert}{pass},
              children => [ map exists $_->{assert} ? $_->{assert} : (), @{$_->{parent}{children}} ],
            }
          : (),
          map $_->facet_data, @$events ],
      [
        {
          details => 'hash.json: "mutation of hashes" - "object of integers"',
          pass => 0,
          children => [
            superhashof({
              details => 'test passes: data is valid: true',
              pass => 1,
            }),
            superhashof({
              details => 'evaluator did not mutate '.$type,
              pass => 0,
            }),
          ],
        },
      ],
      $test_name.' in '.$type,
    );
  }
}

done_testing;
