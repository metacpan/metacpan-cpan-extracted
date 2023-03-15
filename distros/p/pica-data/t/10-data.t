use strict;
use Test::More;
use Test::Exception;

use PICA::Data ':all';
use Scalar::Util 'blessed';
use PICA::Parser::Plain;
my $record = PICA::Parser::Plain->new('./t/files/pica.plain')->next;

foreach ('019@', pica_path('019@')) {
    is_deeply [pica_values($record, $_)], ['XB-CN'], 'pica_values';
}

bless $record, 'PICA::Data';
my %map = (
    '019@$*/0-1' => ['XB'],
    '019@$*/1'   => ['B'],
    '019@$*/5'   => [],
    '019@$*/3-'  => ['CN'],
    '019@$*/-1'  => ['XB'],
    '019@x'      => [],
    '1...b'      => ['9330'],
    '1.../*b'    => ['9330', 'test$'],
    '?+#'        => [],
);
foreach (keys %map) {
    is_deeply [$record->values($_)], $map{$_}, "->values($_)";
}

is_deeply [$record->value('1...b')], ['9330'], '->value';
is_deeply [$record->value('234X')], [], '->value (empty)';

is_deeply $record->fields('010@'), [['010@', '', 'a' => 'chi']], '->fields';
is @{$record->fields}, 18, '->fields';

is_deeply $record->fields('003@', '010@'),
    [['003@', '', '0' => '12345'], ['010@', '', 'a' => 'chi']],
    '->fields(...)';

is $record->id, '12345', '->id';

is_deeply $record->fields('?!*~'), [], 'invalid PICA path';
# throws_ok { $record->fields('?!*~') } qr/invalid pica path/, 'invalid PICA Path';
my $fields = pica_fields($record, '1.../*');
is blessed($fields->[0]), 'PICA::Data::Field', 'PICA::Data::Field';
is scalar @$fields, 5, 'pica_fields';

my $field = ['000@', '', '0', '0'];
my $annotated = [@$field, ' '];
is pica_annotation($field), undef, 'no annotation';
is pica_annotation($annotated), ' ', 'get annotation';

dies_ok { pica_annotation($annotated, 'x') };
pica_annotation($annotated, '-'), '-', 'set annotation';
is pica_annotation($annotated), '-', 'set annotation';
pica_annotation($field, ' ');
pica_annotation($annotated, undef);
is pica_annotation($field), ' ', 'added annotation';
is pica_annotation($annotated), undef, 'removed annotation';

ok pica_empty([]), 'empty';
ok pica_empty({ record => [] }), 'empty';

is $record->subfields('003@')->{0}, '12345', 'subfields';
is_deeply $record->subfields('01..')->mixed, {
    0 => '0',
    a => [qw(chi 2004 XB-CN)],
    n => '2004.01',
    x => '',
    y => ''
  }, 'subfields';

is_deeply pica_field('123A', a => 0, b => '', c => 1), ['123A', undef, a => 0, c => 1], 'pica_field';
is_deeply pica_field('123A/00', a => 0), ['123A', undef, a => 0], 'pica_field';
is_deeply pica_field('123A/1', a => 0), ['123A', '01', a => 0], 'pica_field';

$record = PICA::Data->new;
$record->append('037A/01', a => 'hello', b => 'world', x => undef, y => '');
$record->append('037A', 1, a => 'hello', b => 'world');
$record->append('123X/00', x => 1);
is_deeply $record->fields, [
    ['037A', '01', a => 'hello', b => 'world'],
    ['037A', '01', a => 'hello', b => 'world'],
    ['123X', undef, x => 1],
], 'append';

$record->update('123X', x => 1);
dies_ok { $record->update('123X', 1) };

$record->remove('037./*');
is_deeply $record->fields, [ ['123X', undef, x => 1] ], 'update and remove';
$record->update('123X$y', 2);
is_deeply $record->fields, [ ['123X', undef, x => 1, y => 2] ], 'update subfield';
$record->update('123X$x', 0);
is_deeply $record->fields, [ ['123X', undef, x => 0, y => 2] ], 'update subfield';
$record->update('123X$*', 1);
is_deeply $record->fields, [ ['123X', undef, x => 1, y => 1] ], 'update subfields';
$record->update('123X$x', '');
is_deeply $record->fields, [ ['123X', undef, y => 1] ], 'remove subfield';
$record->update('123X$y', undef);
is_deeply $record->fields, [ ], 'remove last subfield';

done_testing;
