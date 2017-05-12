#!/usr/bin/env perl
# Check categories_enabled() works as expected.

use strict;
use warnings;
no warnings qw(uninitialized);

use Test::More qw(no_plan);

use_ok('warnings::everywhere');

# At first, all warning categories are enabled.
my @all_warnings = grep { $_ ne 'all' } sort keys %warnings::Offsets;
is_deeply([warnings::everywhere::categories_enabled()],
    \@all_warnings, 'All warnings are enabled at first');

# We can disable misc warnings.
ok(warnings::everywhere::disable_warning_category('misc'),
    'We can disable misc warnings');

is_deeply(
    [warnings::everywhere::categories_enabled()],
    [grep { $_ ne 'misc' } @all_warnings],
    'All but misc warnings are enabled'
);

# Re-enabling a warning that's already enabled does nothing.
ok(
    warnings::everywhere::enable_warning_category('printf'),
    'We can pointlessly re-enable printf warnings'
);
is_deeply(
    [warnings::everywhere::categories_enabled()],
    [grep { $_ ne 'misc' } @all_warnings],
    'That changed nothing'
);

# We can re-enable them.
ok(warnings::everywhere::enable_warning_category('misc'),
    'We can re-enable misc warnings');

is_deeply([warnings::everywhere::categories_enabled()],
    \@all_warnings, 'All warnings are enabled again');
