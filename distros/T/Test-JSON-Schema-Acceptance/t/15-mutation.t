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
use Scalar::Util 'dualvar';
use Tie::Hash;
use Test::JSON::Schema::Acceptance;
use Test::File::ShareDir -share => { -dist => { 'Test-JSON-Schema-Acceptance' => 'share' } };

use lib 't/lib';
use Helper;

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
    },
   "$]" >= 5.035009 ? 'on perls >= 5.35.9, reading the string form of an integer value no longer sets the flag SVf_POK' : '',
  ],
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
  my ($test_name, $mutator, $skip) = @$test;

  foreach my $type (qw(data schema)) {
    if ($skip) {
      SKIP: { skip $test_name.' in '.$type.': '.$skip, 1 }
      next;
    }

    my $accepter = Test::JSON::Schema::Acceptance->new(test_dir => 't/tests/mutation');
    my $events = intercept(
      sub {
        $accepter->acceptance(validate_data => sub ($schema, $data) {
          $mutator->($type eq 'data' ? $data : $type eq 'schema' ? $schema : die "$type?!");

          return 1;
        });
      }
    );

    my $TODO = todo 'JSON::PP may mutate some bignums'
      if Test::JSON::Schema::Acceptance::_JSON_BACKEND eq 'JSON::PP' and $test_name =~ /^big/;

    cmp_result(
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
