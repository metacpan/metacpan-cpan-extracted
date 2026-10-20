#! perl

use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::More;
use Test::FitNesse::Slim::StatementExecutor;
use Fitnesse::Slim::Test::TestSlimWithConverter;

my $executor = Test::FitNesse::Slim::StatementExecutor->new;
my $fixture = Fitnesse::Slim::Test::TestSlimWithConverter->new;
$executor->create('converter', $fixture, []);

is($executor->call('converter', 'set_list_converter'), '/__VOID__/',
  'fixture can register a converter and reports its declared void result');
is($executor->call('converter', 'get_object'), '{a, b, c}',
  'broad declared result type uses runtime-class converter');
is_deeply($executor->call('converter', 'get_list'), ['a', 'b', 'c'],
  'exact List result remains a nested SLiM list');
is($executor->call('converter', 'get_array_list'), '{a, b, c}',
  'concrete collection result uses interface converter');
is($executor->call('converter', 'same_list', '{a, b, c}'), 'true',
  'declared List argument uses registered fromString converter');
$executor->add_converter('java.util.List', DyingConverter->new);
my $bad = $executor->call('converter', 'same_list', '{a, b, c}');
like($bad, qr/EXCEPTION.*conversion error.*Tried to invoke: same_list/s,
  'converter exceptions become SLiM errors with invocation context');
is($executor->call('converter', 'remove_list_converter'), '/__VOID__/',
  'fixture restores the previous standard converter and reports void');
is($executor->call('converter', 'same_list', '[a, b, c]'), 'true',
  'standard collection converter remains active for standard syntax');
$executor->set_symbol('items', [qw(a b c)]);
is($executor->call('converter', 'same_list', '$items'), 'true',
  'an already converted symbol value bypasses string conversion');

my $other = Test::FitNesse::Slim::StatementExecutor->new;
$other->create('converter', Fitnesse::Slim::Test::TestSlimWithConverter->new, []);
is($other->call('converter', 'get_object'), '[a, b, c]',
  'converter registrations are isolated by executor');

my $registry = $executor->{converters};
my ($null, $converted) = $registry->convert_result(
  { return => 'java.util.ArrayList' }, undef
);
ok(!defined($null) && $converted, 'declared return converter receives null results');
my ($void_result) = $registry->convert_result({ return => 'void' }, undef);
is($void_result, '/__VOID__/',
  'void return converter emits the upstream SLiM void marker');
my ($fallback, $used) = $registry->convert_result(
  { return => 'example.Unregistered' }, [qw(x y)]
);
is($fallback, '[x, y]', 'unknown declared return types fall back to runtime class');
ok($used, 'runtime converter is reported as applied');
my ($nested) = $registry->convert_result(
  { return => 'java.util.ArrayList' }, [[qw(a b)], undef]
);
is($nested, '[[a, b], null]', 'collection conversion recursively renders nested lists and nulls');
my @null_args = $registry->convert_arguments(
  { parameters => ['java.util.List'] }, 'nullable', undef
);
ok(!defined($null_args[0]), 'null arguments bypass fromString conversion');
ok(!defined($registry->get_converter('java.lang.Boolean')->from_string('')),
  'boxed Boolean conversion preserves blank as null');
is($registry->get_converter('boolean')->from_string(''), 0,
  'primitive boolean conversion uses its false default');
is($registry->get_converter('boolean')->from_string('yes'), 1,
  'boolean conversion accepts upstream yes syntax');
my $boxed_boolean = $registry->get_converter('java.lang.Boolean');
is($boxed_boolean->to_string(1), 'true', 'boxed Boolean results use lowercase true text');
is($boxed_boolean->to_string(0), 'false', 'boxed Boolean results preserve numeric zero');
ok(!defined($boxed_boolean->to_string(undef)), 'boxed Boolean null results remain null');
my $no_converter = eval {
  $registry->convert_arguments(
    { parameters => ['example.UnknownType'] }, 'unknown_argument', 'value'
  );
  '';
};
like($@, qr/NO_CONVERTER_FOR_ARGUMENT_NUMBER example\.UnknownType/,
  'missing argument converters report the upstream error category');

for my $type (qw(java.lang.Integer int java.lang.Long long java.lang.Double double)) {
  ok($registry->get_converter($type), "$type has a standard converter");
}
is($registry->get_converter('java.lang.Integer')->from_string('-2147483648'),
  -2147483648, 'boxed integer converter accepts the minimum value');
is($registry->get_converter('java.lang.Integer')->from_string('2147483647'),
  2147483647, 'boxed integer converter accepts the maximum value');
ok(!defined($registry->get_converter('java.lang.Integer')->from_string('  ')),
  'boxed integer blank input becomes null');
is($registry->get_converter('int')->from_string(''), 0,
  'primitive integer blank input defaults to zero');
my $integer_error = eval {
  $registry->get_converter('java.lang.Integer')->from_string('2147483648');
  '';
};
like($@, qr/Can't convert 2147483648 to integer/,
  'boxed integer rejects values beyond the Java range');
is($registry->get_converter('java.lang.Long')->from_string('9223372036854775807'),
  9223372036854775807, 'boxed long accepts the maximum Java long');
is($registry->get_converter('java.lang.Long')->from_string('-9223372036854775808'),
  -9223372036854775808, 'boxed long accepts the minimum Java long');
my $long_error = eval {
  $registry->get_converter('long')->from_string('9223372036854775808');
  '';
};
like($@, qr/Can't convert 9223372036854775808 to long/,
  'primitive long rejects values beyond the Java range');
is($registry->get_converter('java.lang.Double')->to_string(
    $registry->get_converter('java.lang.Double')->from_string('2.5e2')),
  '250.0', 'double results use Java-style decimal text');
ok(!defined($registry->get_converter('java.lang.Double')->from_string('')),
  'boxed double blank input becomes null');
is($registry->get_converter('double')->from_string(''), 0,
  'primitive double blank input defaults to zero');
my @typed_numbers = $registry->convert_arguments(
  { parameters => ['java.lang.Integer', 'long', 'java.lang.Double'] },
  'typed_numbers', '12', '-4', '0.125'
);
is_deeply(\@typed_numbers, [12, -4, 0.125],
  'declared numeric fixture parameters receive converted Perl scalars');
my $bad_number = eval {
  $registry->convert_arguments(
    { parameters => ['int'] }, 'bad_number', 'not-a-number'
  );
  '';
};
like($@, qr/Can't convert not-a-number to integer.*Tried to invoke: bad_number/s,
  'numeric conversion errors retain invocation context');
my ($typed_result) = $registry->convert_result(
  { return => 'java.lang.Integer' }, 42
);
is($typed_result, '42', 'declared numeric results use the standard converter');

done_testing;

package DyingConverter;
use strict;
use warnings;
sub new { bless {}, shift }
sub from_string { die "conversion error: test failure\n" }
sub to_string { die "conversion error: test failure\n" }
