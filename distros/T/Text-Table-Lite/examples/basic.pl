use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Text::Table::Lite qw(generate_table);

binmode STDOUT, ':encoding(UTF-8)';
my $rows = [
    ['姓名', '工作地点', '公司职位'],
    ["雷军", "北京\n昌平", "小米\n集团董事会\n创始人"],
    ["马云", "浙江\n杭州", "阿里巴巴\n董事会\n创始人"],
    ["刘强东", "北京\n亦庄", "京东\n集团董事会\n实控人"],
];
print generate_table(
    rows => $rows,
    header_row => 1,
    border => 'unicode',
    row_separator => 1,
), "\n";
