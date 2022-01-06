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
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Scalar::Util 'dualvar';
use Test::Deep;
use Test::JSON::Schema::Acceptance;

my $key = 'a';

foreach my $test (
  [ 'autovivification' => sub ($thing) {
    $thing->{(keys %$thing)[0]}{$key++} = 'this should not be here';
  } ],
  [ 'string->integer type mutation, explicit numification' => sub ($thing) {
    $thing->{foo}{string} += 0;
  } ],
  [ 'integer->string type mutation, explicit stringification' => sub ($thing) {
    $thing->{foo}{int} .= '';
  } ],
  [ 'string->integer type mutation, used as a number' => sub ($thing) {
    my $str = sprintf('%d', $thing->{foo}{string});
  } ],
  [ 'integer->string type mutation, used as a string' => sub ($thing) {
    my $str = sprintf('%s', $thing->{foo}{int});
  } ],
  [ 'string->dualvar' => sub ($thing) {
    $thing->{foo}{string} = dualvar(1, 'one');
  } ],
  [ 'integer->dualvar' => sub ($thing) {
    $thing->{foo}{int} = dualvar(1, 'one');
  } ],
  [ 'blessed hash replacement' => sub ($thing) {
    $thing->{foo} = bless($thing->{foo}, 'MyHash');
  } ],
  [ 'tied hash replacement' => sub ($thing) {
    my %hash;
    tie(%hash, 'Tie::StdHash');
    @hash{keys %{$thing->{foo}}} = values %{$thing->{foo}};
    $thing->{foo} = \%hash;
  } ],
  [ 'bigint' => sub ($thing) {
    $thing->{foo}{bigint} += 1;
  } ],
  [ 'bignum' => sub ($thing) {
    $thing->{foo}{bignum} += 1;
  } ],
)
{
  my ($test_name, $mutator) = @$test;

  foreach my $type (qw(data schema)) {
    my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/mutation');
    $accepter->json_decoder->allow_bignum;
    my $events = intercept(
      sub {
        $accepter->acceptance(validate_data => sub ($schema, $data) {
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
