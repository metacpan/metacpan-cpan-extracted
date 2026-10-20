use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::More;
use Scalar::Util qw(refaddr);
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::ListExecutor;

sub execute_wire {
  my ($executor, @instructions) = @_;
  my $wire = Test::FitNesse::Slim::List->new(\@instructions)->serialize;
  return $executor->execute(Test::FitNesse::Slim::List->new($wire)->list);
}

my $executor = Test::FitNesse::Slim::ListExecutor->new;
my @setup = execute_wire($executor,
  ['make-old', 'make', 'actor', 'Fitnesse::Slim::Test::CreationLifecycle', 'ok', 'actor', 'old'],
  ['keep-reference', 'callAndAssign', 'oldActor', 'actor', 'self'],
  ['hook-registered', 'call', 'actor', 'hookSawRegistration'],
);
is($setup[0][1], 'OK', 'initial actor construction succeeds');
ok(ref($setup[1][1]), 'callAndAssign keeps the object-valued result');
is(refaddr($setup[1][1]), refaddr($executor->executor->get_symbol('oldActor')),
  'object-valued symbol retains the constructed actor reference');
is($setup[2][1], 'true', 'successful initialization sees the actor in executor state');

my @constructor_failure = execute_wire($executor,
  ['constructor-fail', 'make', 'actor', 'Fitnesse::Slim::Test::CreationLifecycle',
    'constructor-failure', 'actor', 'replacement'],
  ['old-value', 'call', 'actor', 'value'],
  ['old-identity', 'call', 'actor', 'sameAs', '$oldActor'],
);
like($constructor_failure[0][1], qr/^__EXCEPTION__:message:<<ConstructorFailure:/,
  'constructor exception is returned as a SLiM error');
is_deeply([@constructor_failure[1, 2]], [
  ['old-value', 'old'], ['old-identity', 'same'],
], 'constructor failure preserves the previous actor and object-valued symbol');

my @hook_failure = execute_wire($executor,
  ['hook-fail', 'make', 'actor', 'Fitnesse::Slim::Test::CreationLifecycle',
    'hook-failure', 'actor', 'replacement'],
  ['old-value-after-hook', 'call', 'actor', 'value'],
  ['old-identity-after-hook', 'call', 'actor', 'sameAs', '$oldActor'],
);
like($hook_failure[0][1], qr/^__EXCEPTION__:message:<<HookFailure:/,
  'initialization hook exception is returned as a SLiM error');
is_deeply([@hook_failure[1, 2]], [
  ['old-value-after-hook', 'old'], ['old-identity-after-hook', 'same'],
], 'failed actor replacement restores the prior object and identity');

my @new_actor_failure = execute_wire($executor,
  ['new-actor-fail', 'make', 'orphan', 'Fitnesse::Slim::Test::CreationLifecycle',
    'hook-failure', 'orphan', 'unusable'],
  ['orphan-call', 'call', 'orphan', 'value'],
  ['recover-actor', 'make', 'orphan', 'Fitnesse::Slim::Test::CreationLifecycle',
    'ok', 'orphan', 'usable'],
  ['recovered-value', 'call', 'orphan', 'value'],
);
like($new_actor_failure[0][1], qr/^__EXCEPTION__:message:<<HookFailure:/,
  'failed initialization of a new actor reports its hook exception');
like($new_actor_failure[1][1], qr/^__EXCEPTION__:message:<<NO_INSTANCE orphan\.value\./,
  'failed new actor is not reachable through actor lookup');
is_deeply([@new_actor_failure[2, 3]], [
  ['recover-actor', 'OK'], ['recovered-value', 'usable'],
], 'the same actor ID can be created and used after hook failure');

my @library = execute_wire($executor,
  ['make-good-library', 'make', 'library1', 'Fitnesse::Slim::Test::CreationLifecycle',
    'ok', 'library1', 'good'],
  ['library-base', 'call', 'missingActor', 'identify'],
  ['fail-library-replacement', 'make', 'library1', 'Fitnesse::Slim::Test::CreationLifecycle',
    'hook-failure', 'library1', 'bad-replacement'],
  ['library-after-replacement', 'call', 'missingActor', 'identify'],
  ['fail-new-library', 'make', 'libraryOrphan', 'Fitnesse::Slim::Test::CreationLifecycle',
    'hook-failure', 'libraryOrphan', 'bad-new'],
  ['library-after-new-failure', 'call', 'missingActor', 'identify'],
  ['make-newest-library', 'make', 'library2', 'Fitnesse::Slim::Test::CreationLifecycle',
    'ok', 'library2', 'newest'],
  ['library-hook-registered', 'call', 'library2', 'hookSawRegistration'],
  ['library-after-success', 'call', 'missingActor', 'identify'],
);
is_deeply([map { $library[$_][1] } (0, 1, 3, 5, 6, 7, 8)],
  ['OK', 'good', 'good', 'good', 'OK', 'true', 'newest'],
  'failed library hooks preserve registration and successful precedence');
like($library[2][1], qr/^__EXCEPTION__:message:<<HookFailure:/,
  'failed library replacement reports initialization error');
like($library[4][1], qr/^__EXCEPTION__:message:<<HookFailure:/,
  'failed new library reports initialization error');

my $typed = Test::FitNesse::Slim::ListExecutor->new;
my $date_converter = $typed->executor->get_converter('java.util.Date');
my $old_date = $date_converter->from_string('29-Feb-2024');
my @typed_replacement = execute_wire($typed,
  ['typed-make', 'make', 'typed', 'Fitnesse::Slim::Test::TypedConstructor',
    'A', '29-Feb-2024', ''],
  ['bad-conversion-replacement', 'make', 'typed', 'Fitnesse::Slim::Test::TypedConstructor',
    'B', 'not-a-date', ''],
  ['typed-char-after-conversion', 'call', 'typed', 'character'],
  ['typed-date-after-conversion', 'call', 'typed', 'date'],
  ['bad-arity-replacement', 'make', 'typed', 'Fitnesse::Slim::Test::TypedConstructor', 'C'],
  ['typed-char-after-arity', 'call', 'typed', 'character'],
);
like($typed_replacement[1][1], qr/^__EXCEPTION__:message:<<Can't convert not-a-date to date/s,
  'typed constructor conversion failure is reported');
is_deeply([@typed_replacement[2, 3]], [
  ['typed-char-after-conversion', '65'],
  ['typed-date-after-conversion', $old_date],
], 'conversion failure preserves the prior typed actor');
like($typed_replacement[4][1], qr/^__EXCEPTION__:message:<<NO_CONSTRUCTOR\b/s,
  'typed constructor arity failure is reported');
is($typed_replacement[5][1], '65',
  'arity failure also preserves the prior typed actor');

done_testing;
