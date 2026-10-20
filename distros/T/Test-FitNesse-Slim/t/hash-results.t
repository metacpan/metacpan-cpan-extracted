#! perl -T

use strict;
use utf8;
use warnings;

use lib 't/lib';

use Test::More tests => 10;
use Test::FitNesse::Slim::StatementExecutor;
use Test::FitNesse::Slim::List;
use Fitnesse::Fixtures::HashFixture;
use Fitnesse::Slim::Test::TestSlim;

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
$executor->add_import('Fitnesse::Fixtures');
is($executor->create('hash_fixture', 'HashFixture', []), 'OK',
  'create the upstream hash fixture');

my $fixture = $executor->instance('hash_fixture');
$fixture->send_as_hash({ name => 'bob', address => 'here' });
my $result = $executor->call('hash_fixture', 'hash');
my $expected = <<'HTML';
<table class="hash_table">
	<tr class="hash_row">
		<td class="hash_key">address</td>
		<td class="hash_value">here</td>
	</tr>
	<tr class="hash_row">
		<td class="hash_key">name</td>
		<td class="hash_value">bob</td>
	</tr>
</table>
HTML
chomp $expected;
is($result, $expected, 'hash results use FitNesse MapConverter table markup');

$fixture->send_as_hash({
  markup => '<em><b>bold</b></em>',
  escaped => 'a < b & c',
  nothing => undef,
  rows => ['first', undef, 'last'],
  nested => { child => 'value' },
  unicode => 'café 雪',
});
$result = $executor->call('hash_fixture', 'hash');
like($result, qr{<td class="hash_value"><em><b>bold</b></em></td>},
  'valid HTML map cell content is retained');
like($result, qr{a &lt; b &amp; c}, 'ordinary map text is HTML escaped');
like($result, qr{<td class="hash_value">null</td>}, 'undefined map values use the SLiM null text');
like($result, qr{<td class="hash_value">\[first, null, last\]</td>},
  'nested array values use collection-style text');
like($result, qr{<td class="hash_value"><table class="hash_table">},
  'nested maps use the map converter recursively');
my $wire = Test::FitNesse::Slim::List->new([$result])->serialize;
my @decoded = Test::FitNesse::Slim::List->new($wire)->list;
is($decoded[0], $result, 'Unicode map output survives SLiM list serialization');

my $actor = Fitnesse::Slim::Test::TestSlim->new(7);
$fixture->send_as_hash({ actor => $actor });
$result = $executor->call('hash_fixture', 'hash');
like($result, qr{<td class="hash_value">TestSlim: 7, null</td>},
  'object values use the fixture string representation, not a Perl pointer');
is($fixture->{HASH}{actor}, $actor, 'map conversion leaves stored object identity intact');
