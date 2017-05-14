use Test::Most 'die';

use lib 'lib';
use Unknown::Values;

my $value = unknown;
throws_ok { $value + 1 }
qr/Math cannot be performed on unknown values/,
  'Addition cannot be performed with unknown values';
throws_ok { 1 + $value }
qr/Math cannot be performed on unknown values/,
  'Addition cannot be performed with unknown values';
throws_ok { $value - 1 }
qr/Math cannot be performed on unknown values/,
  'Subtraction cannot be performed with unknown values';
throws_ok { $value * 1 }
qr/Math cannot be performed on unknown values/,
  'Multiplication cannot be performed with unknown values';
throws_ok { $value / 1 }
qr/Math cannot be performed on unknown values/,
  'Division cannot be performed with unknown values';
throws_ok { $value**1 }
qr/Math cannot be performed on unknown values/,
  'Exponentiation cannot be performed with unknown values';
throws_ok { $value++ }
qr/Math cannot be performed on unknown values/,
  'Post-increment cannot be performed with unknown values';
throws_ok { ++$value }
qr/Math cannot be performed on unknown values/,
  'Pre-increment cannot be performed with unknown values';
throws_ok { $value-- }
qr/Math cannot be performed on unknown values/,
  'Post-decrement cannot be performed with unknown values';
throws_ok { --$value }
qr/Math cannot be performed on unknown values/,
  'Pre-decrement cannot be performed with unknown values';
throws_ok { $value += 1 }
qr/Math cannot be performed on unknown values/,
  '+= cannot be performed with unknown values';
throws_ok { sin($value) }
qr/Math cannot be performed on unknown values/,
  'sin() cannot be performed with unknown values';
throws_ok { abs($value) }
qr/Math cannot be performed on unknown values/,
  'abs() cannot be performed with unknown values';

lives_ok { $value = 7 }
    'Assigning a value to an unknown object should succeed';
is $value, 7, '... and it should be a normal value';
lives_ok { $value++ }
    '... allowing you to manipulate it like normal';
is $value, 8, '... and it should be no longer unknown';
ok !is_unknown $value, '... or evaluate as unknown';

lives_ok { $value = unknown }
    'We should be able to reset a value to unknown';
ok is_unknown $value, '... and it should compare as unknown';

ok is_unknown !unknown, 'not unknown should evaluate to unknown';
use 5.12.0;
$value = unknown;
my $should_be_unknown = $value ||= 2;
ok is_unknown $should_be_unknown,
    'unknown ||= anything must return unknown because we cannot know if unknown was false';

$value = unknown;
my $should_be_unknown2 = $value //= 2;
ok is_unknown $should_be_unknown2,
    'unknown //= anything must return unknown because we cannot know if unknown was defined';

done_testing;
