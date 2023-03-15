use v5.14.1;
use Test::More;
use PICA::Data qw(pica_sort_subfields pica_string);

my $field = [qw(012X 1 a 1 b 2 c 3 a 4)];
ok pica_sort_subfields($field, 'bca');
is_deeply $field, [qw(012X 1 b 2 c 3 a 1)];
say pica_string([$field]);

$field = [qw(012X 2 a 1 b 2 c 3 z 1 a 4)];
ok pica_sort_subfields($field, 'ba+c');
is_deeply $field, [qw(012X 2 b 2 a 1 a 4 c 3)];

ok !pica_sort_subfields($field, 'xyz');

done_testing;
