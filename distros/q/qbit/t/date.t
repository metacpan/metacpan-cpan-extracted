use Test::More tests => 16;

use qbit;

is(trdate(db => norm => 0), undef, 'Check bad date');

is_deeply(trdate(norm => norm => [2013, 12, 31, 23, 59, 59]), [2013, 12, 31, 23, 59, 59], 'Check trdate norm => norm');

is_deeply(trdate(norm => db => [2013, 12, 31, 23, 59, 59]), '2013-12-31', 'Check trdate norm => db');
is_deeply(trdate(db => norm => '2013-12-31'), [2013, 12, 31, 0, 0, 0], 'Check trdate db => norm ');

is_deeply(trdate(norm => db_time => [2013, 12, 31, 23, 59, 59]), '2013-12-31 23:59:59', 'Check trdate norm => db_time');
is_deeply(trdate(db_time => norm => '2013-12-31 23:59:59'), [2013, 12, 31, 23, 59, 59],
    'Check trdate db_time => norm ');

is(trdate(norm => sec => trdate(sec => norm => 1375808504)), 1375808504, 'Check trdate sec => norm => sec');

is(trdate(norm => days_in_month => [2012, 02, 15]), 29, 'Check trdate norm => days_in_month');

is(check_date("2013-12-31\n", iformat => 'db'), '', 'Check bad date with \n');

is(check_date("2013-12-31", iformat => 'db'), 1, 'Check date');

is(compare_dates('1980-01-01', '1984-07-04', iformat1 => 'db', iformat2 => 'db'), -1, 'compare_dates()',);

is(compare_dates('2000-01-01', '2010-01-01', iformat1 => 'db', iformat2 => 'db'), -1, 'compare_dates()',);

is(compare_dates('1900-01-01', '1984-07-04', iformat1 => 'db', iformat2 => 'db'), -1, 'compare_dates()',);

is(compare_dates('2010-01-01', '2010-01-01', iformat1 => 'db', iformat2 => 'db'), 0, 'compare_dates()',);

is(compare_dates('1999-01-01', '1998-01-01', iformat1 => 'db', iformat2 => 'db'), 1, 'compare_dates()',);

is_deeply(
    trdate(db_time => norm => '2013-12-31'),
    [2013, 12, 31, 0, 0, 0],
    'Check trdate db_time (without time) => norm'
);
