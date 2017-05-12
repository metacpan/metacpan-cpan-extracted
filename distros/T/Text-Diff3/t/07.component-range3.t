use Test::Base tests => 35;
BEGIN { use_ok('Text::Diff3', ':factory') };

my $Factory = 'Text::Diff3::Factory';

my $factory = $Factory->new;
my $diff3 = $factory->create_list3;
my $range = $factory->create_range3(0, 1,2, 3,4, 5,6);

ok(ref $range eq ref $factory->create_null_range3,
    'same class, null_range and range');
my @range_method = qw(
    as_string as_array set_type_diff0 set_type_diff1 set_type_diff2
    set_type_diffA
    type lo0 hi0 lo1 hi1 lo2 hi2 range0 range1 range2
);
my @list_method = qw(
    push pop unshift shift is_empty size first last each at
);
can_ok($range, $_) for @range_method;
can_ok($diff3, $_) for @list_method;

$diff3->push($range);
$diff3->push($factory->create_range3(10, 11,12, 13,14, 15,16));
$diff3->push($factory->create_range3(20, 21,22, 23,24, 15,16));
ok($diff3->size == 3, 'size == 3');
ok(! $diff3->is_empty, '! is_empty');
is_deeply([$diff3->first->as_array], [0, 1,2, 3,4, 5,6], 'first_range');
is_deeply([$diff3->last->as_array], [20, 21,22, 23,24, 15,16], 'last_range');
$diff3->shift;
$diff3->shift;
$range = $diff3->shift;
ok($diff3->is_empty, 'is_empty');
is_deeply([$range->as_array], [20, 21,22, 23,24, 15,16], 'last shift');
is_deeply([$range->type, $range->lo0, $range->hi0, $range->lo1, $range->hi1,
    $range->lo2, $range->hi2], [$range->as_array], 'range structure');
