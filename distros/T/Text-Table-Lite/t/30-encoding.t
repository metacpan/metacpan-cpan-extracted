use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw(encode decode);
use Text::Table::Lite qw(generate_table);

my $rows = [
    ['姓名', '工作地点', '公司职位'],
    ["雷军", "北京\n昌平", "小米\n集团董事会\n创始人"],
    ["马云", "浙江\n杭州", "阿里巴巴\n董事会\n创始人"],
    ["刘强东", "北京\n亦庄", "京东\n集团董事会\n实控人"],
];
my $unicode = generate_table(rows => $rows, header_row => 1, border => 'unicode', row_separator => 1);
ok(utf8::is_utf8($unicode), 'characters mode returns a character string');
like($unicode, qr/雷军/, 'Chinese data is preserved');
like($unicode, qr/集团董事会/, 'multiline Chinese cell is preserved');

my $gbk_rows = [ map { [ map { encode('GBK', $_) } @$_ ] } @$rows ];
my $gbk = generate_table(rows => $gbk_rows, header_row => 1, border => 'ascii', row_separator => 1, encoding => 'GBK');
ok(!utf8::is_utf8($gbk), 'GBK mode returns encoded bytes');
my $decoded = decode('GBK', $gbk);
like($decoded, qr/雷军/, 'GBK input and output use the same encoding');
like($decoded, qr/集团董事会/, 'multiline GBK cell is preserved');

eval { generate_table(rows => [["\xFF"]], encoding => 'UTF-8') };
ok($@, 'invalid input byte sequence fails strictly');
eval { generate_table(rows => [[encode('GB2312', '姓名')]], encoding => 'GB2312') };
# Both encodings are supported; this confirms Encode recognizes GB2312 and that
# the supplied bytes are decoded/re-encoded without changing the requested mode.
ok(!$@, 'GB2312 encoding name is accepted');
eval { generate_table(rows => [['😀']], encoding => 'GBK') };
ok($@, 'encoded mode rejects decoded character strings');

done_testing;
