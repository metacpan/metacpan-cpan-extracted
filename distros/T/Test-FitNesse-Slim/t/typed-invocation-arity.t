use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::More;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::ListExecutor;
use Fitnesse::Slim::Test::InvocationArity;
use Fitnesse::Slim::Test::ZeroArityConstructor;

sub execute_wire {
  my ($executor, @instructions) = @_;
  my $wire = Test::FitNesse::Slim::List->new(\@instructions)->serialize;
  return $executor->execute(Test::FitNesse::Slim::List->new($wire)->list);
}

$Fitnesse::Slim::Test::InvocationArity::CALLS = 0;
$Fitnesse::Slim::Test::InvocationArity::Sut::CALLS = 0;
$Fitnesse::Slim::Test::InvocationArity::Library::CALLS = 0;
$Fitnesse::Slim::Test::InvocationArity::CONSTRUCTIONS = 0;

my $executor = Test::FitNesse::Slim::ListExecutor->new;
my @first = execute_wire($executor,
  ['make', 'make', 'actor', 'Fitnesse::Slim::Test::InvocationArity', '7'],
  ['ok', 'call', 'actor', 'typed', 'hello'],
  ['few', 'call', 'actor', 'typed'],
  ['many', 'call', 'actor', 'typed', 'one', 'two'],
  ['zero-ok', 'call', 'actor', 'noArgs'],
  ['zero-many', 'call', 'actor', 'noArgs', 'extra'],
  ['dynamic', 'call', 'actor', 'dynamic', 'one', 'two'],
  ['untyped', 'call', 'actor', 'untyped', 'one', 'two', 'three'],
  ['color', 'call', 'actor', 'color', 'green'],
  ['sequence', 'call', 'actor', 'sequence', '[1, 2]'],
  ['stored', 'call', 'actor', 'value'],
);

is($first[1][1], 'hello', 'correct typed argument count invokes method');
like($first[2][1], qr/^__EXCEPTION__:message:<<NO_METHOD_IN_CLASS\b.*typed\[0\]/s,
  'too few typed arguments produce a structured arity error');
like($first[3][1], qr/^__EXCEPTION__:message:<<NO_METHOD_IN_CLASS\b.*typed\[2\]/s,
  'too many typed arguments produce a structured arity error');
is($first[4][1], 'zero', 'explicit empty parameters declare zero arguments');
like($first[5][1], qr/^__EXCEPTION__:message:<<NO_METHOD_IN_CLASS\b.*noArgs\[1\]/s,
  'explicit zero-argument signature rejects supplied arguments');
is($first[6][1], 'one|two', 'missing parameter metadata preserves dynamic arity');
is($first[7][1], 'one|two|three', 'a method without signature metadata remains dynamic');
is($first[8][1], 'GREEN', 'typed enum arguments convert through fixture metadata');
is($first[9][1], '1,2', 'typed sequence arguments use the shared converter path');
is($first[10][1], '7', 'actor remains usable after rejected invocations');
is($Fitnesse::Slim::Test::InvocationArity::CALLS, 4,
  'arity failures do not invoke the actor method');

my @delegated = execute_wire($executor,
  ['sut-ok', 'call', 'actor', 'sutTyped', '12'],
  ['sut-conversion', 'call', 'actor', 'sutTyped', 'not-an-integer'],
  ['sut-few', 'call', 'actor', 'sutTyped'],
  ['sut-again', 'call', 'actor', 'sutTyped', '13'],
);
is($delegated[0][1], '12', 'typed SUT delegation accepts matching arity');
like($delegated[1][1], qr/^__EXCEPTION__:message:<<Can't convert not-an-integer to integer\./,
  'matching arity reaches conversion and reports its conversion error');
like($delegated[2][1], qr/^__EXCEPTION__:message:<<NO_METHOD_IN_CLASS\b.*sutTyped\[0\]/s,
  'typed SUT delegation rejects mismatched arity');
is($delegated[3][1], '13', 'session continues after conversion and arity errors');
is($Fitnesse::Slim::Test::InvocationArity::Sut::CALLS, 2,
  'a rejected SUT call has no side effect');

my @library = execute_wire($executor,
  ['library-make', 'make', 'library_math', 'Fitnesse::Slim::Test::InvocationArity::Library'],
  ['library-ok', 'call', 'actor', 'libraryTyped', '3.5'],
  ['library-many', 'call', 'actor', 'libraryTyped', '3.5', '4.5'],
);
is($library[1][1], '3.5', 'typed library call accepts matching arity');
like($library[2][1], qr/^__EXCEPTION__:message:<<NO_METHOD_IN_CLASS\b.*libraryTyped\[2\]/s,
  'typed library call rejects mismatched arity');
is($Fitnesse::Slim::Test::InvocationArity::Library::CALLS, 1,
  'a rejected library call has no side effect');
my @precedence = execute_wire($executor,
  ['actor-wins', 'call', 'actor', 'typed', 'one', 'two'],
);
like($precedence[0][1], qr/^__EXCEPTION__:message:<<NO_METHOD_IN_CLASS\b.*typed\[2\]/s,
  'actor signature mismatch does not retry a matching SUT or library method');
is($Fitnesse::Slim::Test::InvocationArity::Sut::CALLS, 2,
  'actor arity failure does not invoke its matching SUT fallback');
is($Fitnesse::Slim::Test::InvocationArity::Library::CALLS, 1,
  'actor arity failure does not invoke its matching library fallback');

my @constructor = execute_wire($executor,
  ['constructor-few', 'make', 'retry', 'Fitnesse::Slim::Test::InvocationArity'],
  ['constructor-many', 'make', 'retry', 'Fitnesse::Slim::Test::InvocationArity', '1', '2'],
);
like($constructor[0][1], qr/^__EXCEPTION__:message:<<NO_CONSTRUCTOR\b.*\[0\]/s,
  'typed constructor rejects too few arguments');
like($constructor[1][1], qr/^__EXCEPTION__:message:<<NO_CONSTRUCTOR\b.*\[2\]/s,
  'typed constructor rejects too many arguments');
ok(!$executor->executor->instance('retry'),
  'constructor arity failures do not register an instance');
is($Fitnesse::Slim::Test::InvocationArity::CONSTRUCTIONS, 1,
  'failed constructors do not run');
my @retry = execute_wire($executor,
  ['constructor-retry', 'make', 'retry', 'Fitnesse::Slim::Test::InvocationArity', '9'],
  ['retry-value', 'call', 'retry', 'value'],
);
is_deeply(\@retry, [['constructor-retry', 'OK'], ['retry-value', '9']],
  'valid construction can reuse an ID after rejected constructors');

my @zero_constructor = execute_wire($executor,
  ['zero-ctor-few', 'make', 'zero_retry', 'Fitnesse::Slim::Test::ZeroArityConstructor', 'unexpected'],
);
like($zero_constructor[0][1], qr/^__EXCEPTION__:message:<<NO_CONSTRUCTOR\b.*\[1\]/s,
  'explicit zero-argument constructor rejects an argument');
ok(!$executor->executor->instance('zero_retry'),
  'zero-argument constructor mismatch does not register an instance');
is($Fitnesse::Slim::Test::ZeroArityConstructor::CONSTRUCTIONS, 0,
  'zero-argument constructor mismatch does not run');
my @zero_valid = execute_wire($executor,
  ['zero-ctor-ok', 'make', 'zero_retry', 'Fitnesse::Slim::Test::ZeroArityConstructor'],
  ['zero-ready', 'call', 'zero_retry', 'ready'],
);
is_deeply(\@zero_valid, [['zero-ctor-ok', 'OK'], ['zero-ready', 'ready']],
  'an explicitly zero-argument constructor succeeds with no arguments');

my @untyped_constructor = execute_wire($executor,
  ['untyped-ctor-zero', 'make', 'loose0', 'Fitnesse::Slim::Test::UnannotatedConstructor'],
  ['untyped-ctor-many', 'make', 'loose2', 'Fitnesse::Slim::Test::UnannotatedConstructor', 'first', 'second'],
  ['untyped-zero-value', 'call', 'loose0', 'value'],
  ['untyped-many-value', 'call', 'loose2', 'value'],
);
is_deeply(\@untyped_constructor, [
  ['untyped-ctor-zero', 'OK'],
  ['untyped-ctor-many', 'OK'],
  ['untyped-zero-value', 'null'],
  ['untyped-many-value', 'first'],
], 'constructors without signature metadata retain Perl argument flexibility');

done_testing;
