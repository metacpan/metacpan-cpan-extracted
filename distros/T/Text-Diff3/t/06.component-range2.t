use Test::Base tests => 40;
BEGIN { use_ok('Text::Diff3', ':factory') };

# If you test another Factory change this
my $Factory = 'Text::Diff3::Factory';

can_ok($Factory, 'new');
my $f = $Factory->new;

can_ok($Factory, 'create_list2');
can_ok($Factory, 'create_range2');
my $diff = $f->create_list2;
my $range2 = $f->create_range2;

my @range_method = qw(
    new as_string set_type_a set_type_c set_type_d type
    loA hiA loB hiB rangeA rangeB
);
my @list_method = qw(
    push pop unshift shift is_empty size first last each at
);
can_ok($range2, $_) for @range_method;
can_ok($diff, $_) for @list_method;

$diff->push($f->create_range2('c', 1,2, 3,4));
ok($diff->first->type eq 'c', 'Range2->type');
$diff->first->set_type_a;
ok($diff->first->type eq 'a', 'Range2->set_type_a');
$diff->first->set_type_c;
ok($diff->first->type eq 'c', 'Range2->set_type_c');
$diff->first->set_type_d;
ok($diff->first->type eq 'd', 'Range2->set_type_d');
ok($diff->first->loA == 1, 'Range2->loA');
ok($diff->first->hiA == 2, 'Range2->hiA');
ok($diff->first->loB == 3, 'Range2->loB');
ok($diff->first->hiB == 4, 'Range2->hiB');

$diff->push($f->create_range2('a', 5,6, 7,8));
$diff->push($f->create_range2('d', 9,10, 11,12));
ok($diff->size == 3, 'List2->size == 3');
$diff->shift;
$diff->shift;
ok($diff->size == 1, 'List2->size == 1');
my $range = $diff->first;
is_deeply([$range->as_array], ['d', 9,10, 11,12], 'first');
ok(! $diff->is_empty, '! is_empty');
$range = $diff->shift;
ok($diff->is_empty, 'is_empty');
is_deeply([$range->as_array], ['d', 9,10, 11,12], 'shift');
