use strict;
use warnings;
use utf8;
use Test::More;
use Text::Table::Lite qw(generate_table);

my $rows = [
    ['姓名', '工作地点', '公司职位'],
    ["雷军", "北京\n昌平", "小米\n集团董事会\n创始人"],
    ["马云", "浙江\n杭州", "阿里巴巴\n董事会\n创始人"],
    ["刘强东", "北京\n亦庄", "京东\n集团董事会\n实控人"],
];
my $out = generate_table(
    rows => $rows,
    header_row => 1,
    border => 'unicode',
    row_separator => 1,
    align => ['left', 'left', 'right'],
);
ok(index($out, '┌') == 0, 'unicode top border');
ok(index($out, '╞') >= 0 && index($out, '╪') >= 0, 'double header separator');
ok(index($out, '├') >= 0 && index($out, '┼') >= 0, 'row separator');
like($out, qr/雷军.*小米/s, 'Chinese data rendered');
like($out, qr/刘强东.*实控人/s, 'last Chinese record rendered');
unlike($out, qr/实控人\n├/, 'no separator after last data row');

my $multi = generate_table(
    rows => [ ['Name', 'Place'], ["王海清", "北京\n海淀"], ['A', 'Tokyo'] ],
    header_row => 1,
    border => 'unicode',
    row_separator => 1,
);
ok(index($multi, "北京  │\n│        │ 海淀") >= 0 && index($multi, '├') > index($multi, '海淀'), 'multiline record separated only after its final physical line');

my $empty = generate_table(rows => []);
is($empty, '', 'empty input returns empty string');

my $none = generate_table(rows => [['a', 'b'], ['c', 'd']], border => 'none');
is($none, " a  b \n c  d ", 'borderless output');

done_testing;
