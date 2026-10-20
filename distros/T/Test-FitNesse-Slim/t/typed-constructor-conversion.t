use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::More;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::ListExecutor;

sub execute_wire {
  my ($executor, @instructions) = @_;
  my $wire = Test::FitNesse::Slim::List->new(\@instructions)->serialize;
  return $executor->execute(Test::FitNesse::Slim::List->new($wire)->list);
}

my $executor = Test::FitNesse::Slim::ListExecutor->new;
my @result = execute_wire($executor,
  ['make', 'make', 'typed', 'Fitnesse::Slim::Test::TypedConstructor',
    "\x{1F642}", '29-Feb-2024', ''],
  ['char', 'call', 'typed', 'character'],
  ['date', 'call', 'typed', 'date'],
  ['null-char', 'call', 'typed', 'nullableCharacter'],
);

my $date = $executor->executor->get_converter('java.util.Date');
is_deeply(\@result, [
  ['make', 'OK'],
  ['char', '55357'],
  ['date', $date->from_string('29-Feb-2024')],
  ['null-char', 'null'],
], 'SLiM constructor arguments use declared Character and Date converters');

my @untyped = execute_wire($executor,
  ['raw-make', 'make', 'raw', 'Fitnesse::Slim::Test::UnannotatedConstructor', 'A'],
  ['raw-char', 'call', 'raw', 'value'],
);
is_deeply(\@untyped, [['raw-make', 'OK'], ['raw-char', 'A']],
  'constructor arguments remain untouched when fixture metadata is absent');

my @bad = execute_wire($executor,
  ['bad-make', 'make', 'bad', 'Fitnesse::Slim::Test::TypedConstructor',
    'A', 'not-a-date', undef],
);
like($bad[0][1], qr/^__EXCEPTION__:message:<<Can't convert not-a-date to date.*\nTried to invoke: .* constructor$/s,
  'invalid typed constructor arguments report conversion context');
ok(!$executor->executor->instance('bad'),
  'a constructor conversion failure does not register a partial instance');

done_testing;
