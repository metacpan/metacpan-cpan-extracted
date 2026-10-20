use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::More;
use POSIX ();
use Test::FitNesse::Slim::ConverterRegistry;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::ListExecutor;

sub bits {
  return unpack('H*', pack('d>', $_[0]));
}

sub execute_wire {
  my ($executor, @instructions) = @_;
  my $wire = Test::FitNesse::Slim::List->new(\@instructions)->serialize;
  return $executor->execute(Test::FitNesse::Slim::List->new($wire)->list);
}

my $registry = Test::FitNesse::Slim::ConverterRegistry->new;
my $boxed = $registry->get_converter('java.lang.Double');
my $primitive = $registry->get_converter('double');

my @reference_values = (
  ['0x1.8p1', '3.0', '4008000000000000'],
  ['0X.8P-1', '0.25', '3fd0000000000000'],
  ['1d', '1.0', '3ff0000000000000'],
  ['1e-3', '0.001', '3f50624dd2f1a9fc'],
  ['1e-4', '1.0E-4', '3f1a36e2eb1c432d'],
  ['1e6', '1000000.0', '412e848000000000'],
  ['1e7', '1.0E7', '416312d000000000'],
  ['1e20', '1.0E20', '4415af1d78b58c40'],
  ['4.9e-324', '4.9E-324', '0000000000000001'],
  ['0x1p-1075', '0.0', '0000000000000000'],
  ['1.7976931348623157e308', '1.7976931348623157E308', '7fefffffffffffff'],
  ['-0', '-0.0', '8000000000000000'],
  ['-0x1.0p-1074', '-4.9E-324', '8000000000000001'],
  ['0.1', '0.1', '3fb999999999999a'],
  ['1.2345678901234567', '1.2345678901234567', '3ff3c0ca428c59fb'],
);
for my $case (@reference_values) {
  my ($input, $java_text, $java_bits) = @$case;
  my $number = $boxed->from_string($input);
  is(bits($number), $java_bits, "$input parses to the Java binary64 value");
  is($boxed->to_string($number), $java_text, "$input formats like Java Double.toString");
  is(bits($boxed->from_string($boxed->to_string($number))), $java_bits,
    "$input formatted text round-trips the binary64 value");
}

for my $input ('NaN', '+NaN', '-NaN') {
  my $number = $boxed->from_string($input);
  ok(POSIX::isnan($number), "$input is accepted as Java NaN");
  is($boxed->to_string($number), 'NaN', "$input formats as Java NaN");
}
for my $input ('Infinity', '+Infinity', '-Infinity') {
  my $number = $boxed->from_string($input);
  ok(POSIX::isinf($number), "$input is accepted as infinity");
  is($boxed->to_string($number), $input =~ /^-/ ? '-Infinity' : 'Infinity',
    "$input formats with Java infinity spelling and sign");
}
is($boxed->to_string($boxed->from_string('1e309')), 'Infinity',
  'decimal overflow maps to positive infinity like Java');
is($boxed->to_string($boxed->from_string('-1e-9999')), '-0.0',
  'negative decimal underflow preserves signed zero');
is($boxed->to_string($boxed->from_string("\x001.5\x00")), '1.5',
  'Java ASCII trim characters are accepted around a number');
ok(!defined($boxed->from_string("\x{2003}")),
  'Java blank Unicode whitespace maps to boxed null');
is($primitive->from_string("\x{2003}"), 0,
  'Java blank Unicode whitespace maps to primitive zero');
is($primitive->from_string('  '), 0,
  'primitive whitespace-only input defaults to zero');
ok(!defined($boxed->from_string('  ')),
  'boxed whitespace-only input defaults to null');

for my $invalid ('nan', 'infinity', 'Infinityf', '1e', '0x1.0', '1_0', '0x1p0x') {
  my $ok = eval { $boxed->from_string($invalid); 1 };
  ok(!$ok, "$invalid is rejected");
  like($@, qr/Can't convert \Q$invalid\E to double/,
    "$invalid has the Java-compatible conversion error");
}

my $executor = Test::FitNesse::Slim::ListExecutor->new;
my @constructed = execute_wire($executor,
  ['make-double', 'make', 'numbers', 'Fitnesse::Slim::Test::DoubleValues',
    '0x1.8p1', '-0'],
  ['constructor-primitive', 'call', 'numbers', 'getPrimitive'],
  ['constructor-boxed', 'call', 'numbers', 'getBoxed'],
);
is_deeply(\@constructed, [
  ['make-double', 'OK'],
  ['constructor-primitive', '3.0'],
  ['constructor-boxed', '-0.0'],
], 'typed constructor arguments use the Double converters');

my @calls = execute_wire($executor,
  ['echo', 'callAndAssign', 'assigned', 'numbers', 'echoPrimitive', '0x1p-2'],
  ['echo-assigned', 'call', 'numbers', 'echoPrimitive', '$assigned'],
  ['boxed', 'call', 'numbers', 'echoBoxed', '-Infinity'],
  ['null', 'callAndAssign', 'nullValue', 'numbers', 'getNull'],
  ['boxed-null', 'call', 'numbers', 'echoBoxed', '$nullValue'],
);
is_deeply(\@calls, [
  ['echo', '0.25'],
  ['echo-assigned', '0.25'],
  ['boxed', '-Infinity'],
  ['null', 'null'],
  ['boxed-null', 'null'],
], 'typed scalar methods, assigned symbols, and boxed null compose conversion');

my @sequences = execute_wire($executor,
  ['set-sequences', 'call', 'numbers', 'setSequences',
    '[0x1p-1, NaN, -Infinity]', '[1d, -0, 1e309]', '[0.1, 4.9e-324]'],
  ['array', 'callAndAssign', 'array', 'numbers', 'getArray'],
  ['same-array', 'call', 'numbers', 'sameArray', '$array'],
  ['list', 'callAndAssign', 'list', 'numbers', 'getList'],
  ['collection', 'callAndAssign', 'collection', 'numbers', 'getCollection'],
  ['invalid-element', 'call', 'numbers', 'setSequences', '[1, bad]', '[2]', '[3]'],
  ['list-after-invalid', 'callAndAssign', 'list-after-invalid', 'numbers', 'getList'],
);
is_deeply([@sequences[0 .. 4]], [
  ['set-sequences', '/__VOID__/'],
  ['array', '[0.5, NaN, -Infinity]'],
  ['same-array', 'true'],
  ['list', '[1.0, -0.0, Infinity]'],
  ['collection', '[0.1, 4.9E-324]'],
], 'Double[]/List<Double>/Collection<Double> use the same scalar conversion');
like($sequences[5][1], qr/^__EXCEPTION__:message:<<Can't convert bad to double\./,
  'invalid Double sequence elements use the scalar conversion exception');
is_deeply($sequences[6], ['list-after-invalid', '[1.0, -0.0, Infinity]'],
  'invalid sequence conversion does not invoke or corrupt the fixture');

done_testing;
