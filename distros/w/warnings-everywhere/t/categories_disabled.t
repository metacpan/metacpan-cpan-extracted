#!/usr/bin/env perl
# Check categories_disabled() works as expected.

use strict;
use warnings;
no warnings qw(uninitialized);

use Test::More qw(no_plan);

use_ok('warnings::everywhere');

# At first, no warning categories are disabled
is_deeply([warnings::everywhere::categories_disabled()],
    [], 'No warnings are disabled at first');
ok(warnings::everywhere::_is_bit_set($warnings::Bits{all}),
    'The all bit is set');

# We can disable uninitialized warnings
ok(warnings::everywhere::disable_warning_category('uninitialized'),
    'We can disable uninitialized warnings');
ok(!warnings::everywhere::_is_bit_set($warnings::Bits{all}),
    'The all bit is now unset');

is_deeply([warnings::everywhere::categories_disabled()],
    ['uninitialized'], 'This is now in our list of disabled categories');

# We can re-enable an unrelated warning; that changes nothing.
ok(warnings::everywhere::enable_warning_category('reserved'),
    'We can pointlessly enable reserved warnings');
is_deeply([warnings::everywhere::categories_disabled()],
    ['uninitialized'], 'Uninitialized warnings are still disabled');

# We can re-enable it
ok(warnings::everywhere::enable_warning_category('uninitialized'),
    'We can re-enable uninitialized warnings');

is_deeply([warnings::everywhere::categories_disabled()],
    [], 'No warnings are disabled any more');
ok(warnings::everywhere::_is_bit_set($warnings::Bits{all}),
    'The all bit is set once more')
    or diag(warnings::everywhere::_dump_mask($warnings::Bits{all}));
