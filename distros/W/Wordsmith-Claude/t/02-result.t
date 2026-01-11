#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Wordsmith::Claude::Result;

# Test basic result
my $result = Wordsmith::Claude::Result->new(
    original => 'Hello world',
    text     => 'Greetings, planet Earth',
);

is($result->original, 'Hello world', 'original preserved');
is($result->text, 'Greetings, planet Earth', 'text preserved');
ok($result->is_success, 'is_success true');
ok(!$result->is_error, 'is_error false');
ok(!$result->has_error, 'has_error false');

# Test with mode
$result = Wordsmith::Claude::Result->new(
    original => 'Test',
    text     => 'Rewritten',
    mode     => 'formal',
);

is($result->mode, 'formal', 'mode preserved');

# Test with error
$result = Wordsmith::Claude::Result->new(
    original => 'Test',
    text     => '',
    error    => 'Something went wrong',
);

ok(!$result->is_success, 'is_success false on error');
ok($result->is_error, 'is_error true on error');
is($result->error, 'Something went wrong', 'error message preserved');

# Test variations
$result = Wordsmith::Claude::Result->new(
    original   => 'Test',
    text       => 'Variation 1',
    variations => ['Variation 1', 'Variation 2', 'Variation 3'],
);

is($result->variation_count, 3, 'variation_count correct');
my @vars = $result->all_variations;
is(scalar @vars, 3, 'all_variations returns 3');
is($vars[0], 'Variation 1', 'first variation correct');
is($vars[2], 'Variation 3', 'third variation correct');

is($result->variation(0), 'Variation 1', 'variation(0) correct');
is($result->variation(1), 'Variation 2', 'variation(1) correct');
is($result->variation(2), 'Variation 3', 'variation(2) correct');

# Test single result returns itself as variation
$result = Wordsmith::Claude::Result->new(
    original => 'Test',
    text     => 'Single result',
);

is($result->variation_count, 1, 'single result has count 1');
@vars = $result->all_variations;
is(scalar @vars, 1, 'all_variations returns 1 for single');
is($vars[0], 'Single result', 'single variation is the text');
is($result->variation(0), 'Single result', 'variation(0) for single');

done_testing();
