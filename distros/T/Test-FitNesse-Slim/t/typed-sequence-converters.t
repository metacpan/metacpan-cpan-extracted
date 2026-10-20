use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::More;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::ListExecutor;
use Test::FitNesse::Slim::ConverterRegistry;

sub execute_wire {
  my ($executor, @instructions) = @_;
  my $wire = Test::FitNesse::Slim::List->new(\@instructions)->serialize;
  return $executor->execute(Test::FitNesse::Slim::List->new($wire)->list);
}

my $registry = Test::FitNesse::Slim::ConverterRegistry->new;
ok($registry->get_converter('Integer[]'), 'simple-name typed arrays resolve');
ok($registry->get_converter('java.lang.Integer[]'), 'qualified typed arrays resolve');
ok($registry->get_converter('java.util.List<Integer>'), 'generic Lists resolve');
ok($registry->get_converter('java.util.Collection<java.lang.Integer>'),
  'generic Collections resolve');
ok(!$registry->get_converter('java.util.Set<java.lang.Integer>'),
  'Set conversion remains explicitly unsupported');
ok(!$registry->get_converter('java.util.List<java.util.List<java.lang.String>>'),
  'nested generic conversion remains explicitly unsupported');

my $executor = Test::FitNesse::Slim::ListExecutor->new;
my @made = execute_wire($executor,
  ['make', 'make', 'seq', 'Fitnesse::Slim::Test::TypedSequences', '[1, 2, 3]', '[one, two]'],
);
is_deeply(\@made, [['make', 'OK']], 'constructor arguments convert to typed array and List');

my @result = execute_wire($executor,
  ['numbers', 'callAndAssign', 'numbers', 'seq', 'getIntegers'],
  ['same-numbers', 'call', 'seq', 'sameIntegers', '$numbers'],
  ['strings', 'callAndAssign', 'strings', 'seq', 'getStrings'],
  ['same-strings', 'call', 'seq', 'sameStrings', '$strings'],
);
is_deeply(\@result, [
  ['numbers', '[1, 2, 3]'],
  ['same-numbers', 'true'],
  ['strings', '[one, two]'],
  ['same-strings', 'true'],
], 'typed array/List result formatting retains the raw collection in symbols');
my @untyped_result = execute_wire($executor,
  ['untyped', 'callAndAssign', 'untyped', 'seq', 'untypedValues'],
);
is_deeply(\@untyped_result, [['untyped', [11, 12]]],
  'untyped List callAndAssign retains the legacy nested SLiM list value');

my @mutations = execute_wire($executor,
  ['set-integers', 'call', 'seq', 'setIntegers', '[-4, 0, 8]'],
  ['set-strings', 'call', 'seq', 'setStrings', '[alpha, , gamma,]'],
  ['set-flags', 'call', 'seq', 'setFlags', '[yes, true, no]'],
  ['flags', 'callAndAssign', 'flags', 'seq', 'getFlags'],
  ['invalid', 'call', 'seq', 'setIntegers', '[9, not-an-integer]'],
  ['unchanged', 'call', 'seq', 'getIntegers'],
);
is_deeply([@mutations[0 .. 3], $mutations[5]], [
  ['set-integers', '/__VOID__/'],
  ['set-strings', '/__VOID__/'],
  ['set-flags', '/__VOID__/'],
  ['flags', '[true, true, false]'],
  ['unchanged', '[-4, 0, 8]'],
], 'method arrays, collections, booleans, and state isolation behave correctly');
like($mutations[4][1], qr/^__EXCEPTION__:message:<<Can't convert not-an-integer to integer\./,
  'invalid element conversion becomes a SLiM exception');

my @empty_and_null = execute_wire($executor,
  ['empty-array', 'callAndAssign', 'emptyArray', 'seq', 'getEmptyArray'],
  ['empty-collection', 'callAndAssign', 'emptyCollection', 'seq', 'getEmptyCollection'],
  ['null-collection', 'callAndAssign', 'nullCollection', 'seq', 'getNullCollection'],
  ['accept-null', 'call', 'seq', 'acceptsNull', '$nullCollection'],
  ['accept-empty', 'call', 'seq', 'sameIntegers', '$emptyArray'],
);
is_deeply(\@empty_and_null, [
  ['empty-array', '[]'],
  ['empty-collection', '[]'],
  ['null-collection', 'null'],
  ['accept-null', 'true'],
  ['accept-empty', 'false'],
], 'null and explicitly empty typed arrays/collections remain distinct');

my $list_converter = $registry->get_converter('java.util.List<java.lang.Integer>');
is_deeply($list_converter->from_string('[1, 2, 3]'), [1, 2, 3],
  'typed List parses optional brackets and preserves order');
is_deeply($list_converter->from_string('  '), undef,
  'blank typed List input becomes null');
is_deeply($list_converter->from_string('[]'), [],
  'explicit brackets represent an empty typed List');
is($list_converter->to_string([1, 2, 3]), '[1, 2, 3]',
  'typed List result uses Java collection text formatting');

my $string_array = $registry->get_converter('String[]');
is_deeply($string_array->from_string('[a, , c,]'), ['a', '', 'c'],
  'typed String array trims elements and drops trailing empty fields like Java split');
is($string_array->to_string(['a', '', 'c']), '[a, , c]',
  'typed String array result uses Java array text formatting');

my $boolean_array = $registry->get_converter('Boolean[]');
is_deeply($boolean_array->from_string('true, yes, no'), [1, 1, 0],
  'typed Boolean array composes the standard Boolean converter');
is($boolean_array->to_string([1, 1, 0]), '[true, true, false]',
  'typed Boolean array formats values with the standard converter');

my $null_integer_array = $registry->get_converter('Integer[]');
is_deeply($null_integer_array->from_string('[1, , 3]'), [1, undef, 3],
  'blank boxed array elements become null');
is_deeply($registry->get_converter('int[]')->from_string('[1, , 3]'), [1, 0, 3],
  'blank primitive array elements use the Java primitive default');
is($null_integer_array->to_string([1, undef, 3]), '[1, null, 3]',
  'null array elements serialize as null text');

my $bad_collection = eval { $list_converter->from_string('[1, nope]'); 1 };
ok(!$bad_collection && $@ =~ /Can't convert nope to integer/,
  'invalid typed collection element raises the scalar converter error');

done_testing;
