#! perl -T

use strict;
use warnings;
use lib 't/lib';

use Test::More tests => 17;
use Test::FitNesse::Slim::ListExecutor;

my $list = Test::FitNesse::Slim::ListExecutor->new;

my @ordinary = $list->execute(
  ['i', 'import', 'fitnesse.slim.test'],
  ['m', 'make', 'sut', 'TestSlim'],
  ['normal', 'call', 'sut', 'throwNormal'],
  ['after-normal', 'call', 'sut', 'returnString'],
);
is($ordinary[2][1], '__EXCEPTION__:java.lang.Exception: This is my exception',
  'ordinary fixture exceptions use the regular SLiM exception response');
is($ordinary[3][1], 'string', 'ordinary exceptions do not stop later statements');

my @stop_test = $list->execute(
  ['i', 'import', 'fitnesse.slim.test'],
  ['m', 'make', 'sut', 'TestSlim'],
  ['stop', 'call', 'sut', 'throwStopping'],
  ['after-stop', 'call', 'sut', 'returnString'],
);
like($stop_test[2][1], qr/^__EXCEPTION__:ABORT_SLIM_TEST:.*StopTestException.*This is a stop test exception/,
  'StopTest exceptions use the abort-test protocol marker and retain details');
is(scalar @stop_test, 3, 'statements after StopTest are not executed in that batch');

my @stop_suite = $list->execute(
  ['i', 'import', 'fitnesse.slim.test'],
  ['stop-constructor', 'make', 'sut', 'ConstructorThrows', 'stop suite'],
  ['after-stop-suite', 'call', 'sut', 'returnString'],
);
like($stop_suite[1][1], qr/^__EXCEPTION__:ABORT_SLIM_SUITE:.*StopSuiteException.*stop suite/,
  'StopSuite constructor exceptions use the abort-suite protocol marker');
is(scalar @stop_suite, 2, 'constructor stop exceptions skip later statements in that batch');

my @next_batch = $list->execute(
  ['i', 'import', 'fitnesse.slim.test'],
  ['m', 'make', 'sut', 'TestSlim'],
  ['ok', 'call', 'sut', 'returnString'],
);
is($next_batch[2][1], 'string', 'a subsequent batch runs after the stop request is reset');

my @ctor_fail = $list->execute(
  ['i', 'import', 'fitnesse.slim.test'],
  ['ctor', 'make', 'bad', 'ConstructorThrows', 'constructor failed'],
  ['missing-method', 'call', 'bad', 'setX', '5'],
  ['after-ctor', 'make', 'ok', 'TestSlim'],
);
like($ctor_fail[1][1], qr/^__EXCEPTION__:message:<<java\.lang\.RuntimeException: constructor failed>>/,
  'ordinary constructor exceptions preserve their message');
like($ctor_fail[2][1], qr/^__EXCEPTION__:message:<<NO_INSTANCE bad\.setX\.>>/,
  'calls after a failed constructor identify the missing actor method');
is($ctor_fail[3][1], 'OK', 'ordinary constructor exceptions do not stop later statements');

my @decision = $list->execute(
  ['i', 'import', 'fitnesse.slim.test'],
  ['d', 'make', 'decision', 'DecisionTableExecuteThrows', 'execute setX getX reset beginTable endTable table'],
  ['set', 'call', 'decision', 'setX', '2'],
  ['get', 'call', 'decision', 'x'],
  ['exec', 'call', 'decision', 'execute'],
  ['reset', 'call', 'decision', 'reset'],
  ['begin', 'call', 'decision', 'beginTable'],
  ['end', 'call', 'decision', 'endTable'],
  ['table', 'call', 'decision', 'table', []],
);
like($decision[2][1], qr/^__EXCEPTION__:fitnesse\.slim\.SlimError: SETX_THROWS/,
  'decision-table setter uses upstream error detail');
for my $index (2 .. 8) {
  like($decision[$index][1], qr/^__EXCEPTION__:fitnesse\.slim\.SlimError: /,
    'decision-table failure is returned as an ordinary SlimError')
    if $index >= 4;
}
is($decision[3][1], '__EXCEPTION__:fitnesse.slim.SlimError: GETX_THROWS',
  'decision-table getter uses upstream error detail');
