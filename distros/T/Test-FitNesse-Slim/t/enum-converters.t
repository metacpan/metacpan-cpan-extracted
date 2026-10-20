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
ok(!$registry->get_converter('Color'),
  'enum types are unavailable without fixture declarations');
my $declarations = { Color => [qw(RED red GREEN BLUE)] };
my $enum = $registry->get_converter('Color', $declarations);
ok($enum, 'an explicit fixture enum declaration resolves a converter');
is($enum->from_string('RED'), 'RED', 'exact enum names are accepted');
is($enum->from_string('Red'), 'RED', 'case-insensitive matching uses the first declaration');
is($enum->from_string('red'), 'red', 'exact match wins when names differ only by case');
is($enum->from_string('gReEn'), 'GREEN', 'case-insensitive fallback canonicalizes the value');
my $unicode_enum = $registry->get_converter('Initial', {
  Initial => ['I'],
  SharpS => ["\x{00DF}"],
});
is($unicode_enum->from_string("\x{0131}"), 'I',
  'Unicode case matching follows locale-independent Java character mapping');
my $sharp_s = $registry->get_converter('SharpS', {
  SharpS => ["\x{00DF}"],
});
is($sharp_s->from_string("\x{1E9E}"), "\x{00DF}",
  'case matching uses simple Unicode case mappings without expansions');
my $expanded_case = eval { $sharp_s->from_string('SS'); 1 };
ok(!$expanded_case, 'Java enum matching does not expand one character into two');
ok(!defined($enum->from_string('')),
  'blank enum input converts to null like the Java converter base');
ok(!defined($enum->from_string("\x{2003}")),
  'Java Unicode whitespace-only enum input converts to null');
my $invalid = eval { $enum->from_string(' RED'); 1 };
ok(!$invalid, 'enum input is not trimmed');
like($@, qr/Can't convert  RED to enum value of type Color/,
  'invalid enum errors include the input and declared enum type');
$invalid = eval { $enum->from_string('null'); 1 };
ok(!$invalid, 'the text null is not treated as a null enum value');
like($@, qr/Can't convert null to enum value of type Color/,
  'the text null uses the Java enum conversion error');
is($enum->to_string('gReEn'), 'GREEN', 'enum results normalize to the canonical name');
ok(!defined($enum->to_string(undef)), 'null enum results remain null');
$invalid = eval { $enum->to_string('PURPLE'); 1 };
ok(!$invalid, 'invalid fixture return values are rejected');
like($@, qr/Can't convert PURPLE to enum value of type Color/,
  'invalid enum result reports its declared type');

my $sequence = $registry->get_converter('Color[]', $declarations);
is_deeply($sequence->from_string('[Red, GREEN, blue]'),
  [qw(RED GREEN BLUE)], 'enum array input converts and canonicalizes each element');
is($sequence->to_string([qw(RED GREEN BLUE)]), '[RED, GREEN, BLUE]',
  'enum array results use Java collection text with canonical names');
is_deeply($registry->get_converter('List<Color>', $declarations)
    ->from_string('[red, GREEN]'), [qw(red GREEN)],
  'typed List converts enums while retaining exact declared casing');
is_deeply($registry->get_converter('List<Color>', $declarations)
    ->from_string('[RED, RED, GREEN]'), [qw(RED RED GREEN)],
  'typed enum collections preserve order and duplicates');
is_deeply($registry->get_converter('Collection<Color>', $declarations)
    ->from_string('[]'), [], 'typed enum collections preserve empty values');
ok(!defined($registry->get_converter('Color[]', $declarations)->from_string('')),
  'blank typed enum sequences remain null rather than empty');
is($registry->get_converter('example.types.Color', {
    'example.types.Color' => ['READY'],
  })->to_string('ready'), 'READY',
  'fully qualified enum names can be declared explicitly');
my $bad_sequence = eval { $sequence->from_string('[RED, purple]'); 1 };
ok(!$bad_sequence, 'invalid enum sequence members are rejected');
like($@, qr/Can't convert purple to enum value of type Color/,
  'sequence errors come from the same enum converter');

my $executor = Test::FitNesse::Slim::ListExecutor->new;
my @made = execute_wire($executor,
  ['make-enum', 'make', 'color', 'Fitnesse::Slim::Test::EnumValues', 'gReEn'],
  ['get', 'call', 'color', 'getColor'],
  ['constructor', 'call', 'color', 'echoColor', 'rEd'],
  ['fully-qualified', 'call', 'color', 'echoMode', 'safe'],
  ['null-return', 'call', 'color', 'getNull'],
);
is_deeply(\@made, [
  ['make-enum', 'OK'],
  ['get', 'GREEN'],
  ['constructor', 'RED'],
  ['fully-qualified', 'SAFE'],
  ['null-return', 'null'],
], 'constructor, method argument, and enum result conversion run through SLiM');

my @invocations = execute_wire($executor,
  ['assigned', 'callAndAssign', 'choice', 'color', 'echoColor', 'blue'],
  ['assigned-call', 'call', 'color', 'echoColor', '$choice'],
  ['plain', 'call', 'color', 'plainEcho', 'blue'],
  ['set', 'call', 'color', 'setColor', 'green'],
  ['current', 'call', 'color', 'getColor'],
  ['invalid', 'call', 'color', 'setColor', 'PURPLE'],
  ['still-current', 'call', 'color', 'getColor'],
  ['blank', 'call', 'color', 'echoColor', ''],
  ['invalid-result', 'call', 'color', 'badResult'],
);
is_deeply([@invocations[0 .. 4], $invocations[6], @invocations[7 .. 8]], [
  ['assigned', 'BLUE'],
  ['assigned-call', 'BLUE'],
  ['plain', 'blue'],
  ['set', '/__VOID__/'],
  ['current', 'GREEN'],
  ['still-current', 'GREEN'],
  ['blank', 'null'],
  ['invalid-result', q{__EXCEPTION__:message:<<Can't convert PURPLE to enum value of type Color.>>}],
], 'enum conversion stays signature-scoped, handles symbols, and rejects before invocation');
like($invocations[5][1], qr/^__EXCEPTION__:message:<<Can't convert PURPLE to enum value of type Color\./,
  'invalid invocation becomes the standard structured SLiM exception');

my @sequences = execute_wire($executor,
  ['set-sequences', 'call', 'color', 'setSequences', '[Red, BLUE]', '[green, RED]', '[BLUE, red]'],
  ['array', 'callAndAssign', 'array', 'color', 'getArray'],
  ['same-array', 'call', 'color', 'sameArray', '$array'],
  ['list', 'callAndAssign', 'list', 'color', 'getList'],
  ['same-list', 'call', 'color', 'sameList', '$list'],
  ['collection', 'callAndAssign', 'collection', 'color', 'getCollection'],
  ['invalid-sequence', 'call', 'color', 'setSequences', '[RED, nope]', '[GREEN]', '[BLUE]'],
  ['list-after-invalid', 'callAndAssign', 'list-after-invalid', 'color', 'getList'],
);
is_deeply([@sequences[0 .. 5]], [
  ['set-sequences', '/__VOID__/'],
  ['array', '[RED, BLUE]'],
  ['same-array', 'true'],
  ['list', '[GREEN, RED]'],
  ['same-list', 'true'],
  ['collection', '[BLUE, red]'],
], 'typed enum arrays and collections convert arguments and serialize results');
like($sequences[6][1], qr/^__EXCEPTION__:message:<<Can't convert nope to enum value of type Color/,
  'invalid typed sequence member is a structured error');
is_deeply($sequences[7], ['list-after-invalid', '[GREEN, RED]'],
  'failed enum sequence conversion does not invoke the fixture');

my @isolated = execute_wire($executor,
  ['other', 'make', 'other', 'Fitnesse::Slim::Test::OtherEnumValues'],
  ['other-exact', 'call', 'other', 'echoColor', 'cyan'],
  ['other-invalid', 'call', 'other', 'echoColor', 'RED'],
  ['original', 'call', 'color', 'echoColor', 'GREEN'],
);
is_deeply([@isolated[0 .. 1, 3]], [
  ['other', 'OK'],
  ['other-exact', 'CYAN'],
  ['original', 'GREEN'],
], 'separate fixtures can declare the same type name without registry leakage');
like($isolated[2][1], qr/Can't convert RED to enum value of type Color/,
  'another fixture declaration does not expand this enum domain');

for my $bad_declaration (
  [],
  { '' => ['VALUE'] },
  { Color => 'RED' },
  { Color => ['RED', 'RED'] },
  { String => ['VALUE'] },
  { 'java.util.ArrayList' => ['VALUE'] },
) {
  my $ok = eval { $registry->validate_enum_types($bad_declaration); 1 };
  ok(!$ok, 'invalid or colliding enum metadata is rejected');
}

done_testing;
