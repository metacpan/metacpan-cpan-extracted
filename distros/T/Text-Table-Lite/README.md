# Text::Table::Lite

Perl terminal-table formatter with Unicode display-width handling, multiline cells, optional row separators, and a single input/output encoding setting.

## Install

```sh
cpanm Unicode::GCString
perl Makefile.PL
make test
make install
```

## Example: Perl character strings (default)

```perl
use strict;
use warnings;
use utf8;
use Text::Table::Lite qw(generate_table);
binmode STDOUT, ':encoding(UTF-8)';

my $rows = [
    ['姓名', '工作地点', '公司职位'],
    ["雷军", "北京\n昌平", "小米\n集团董事会\n创始人"],
    ["马云", "浙江\n杭州", "阿里巴巴\n董事会\n创始人"],
    ["刘强东", "北京\n亦庄", "京东\n集团董事会\n实控人"],
];

print generate_table(
    rows          => $rows,
    header_row    => 1,
    border        => 'unicode',
    row_separator => 1,
), "\n";
```

## Example: GBK byte strings

```perl
use strict;
use warnings;
use Encode qw(encode);
use Text::Table::Lite qw(generate_table);

my $rows = [
    [encode('GBK', '姓名'), encode('GBK', '工作地点'), encode('GBK', '公司职位')],
    [encode('GBK', '雷军'), encode('GBK', "北京\n昌平"), encode('GBK', "小米\n集团董事会\n创始人")],
];

my $table = generate_table(
    rows          => $rows,
    header_row    => 1,
    border        => 'ascii', # GBK cannot represent Unicode box-drawing characters
    row_separator => 1,
    encoding      => 'GBK',
);
print $table; # The output is GBK bytes; configure the destination accordingly.
```

## Encoding behavior

- `encoding => 'characters'` is the default: input cells and returned table are Perl character strings.
- `encoding => 'UTF-8'`, `'GBK'`, `'GB2312'`, `'Big5'`, or another encoding recognized by Perl's `Encode` means input cells are byte strings in that encoding and the returned table is encoded in the same encoding.
- Input and output encoding are deliberately unified; the module does not support decoding in one encoding and encoding in another during one call.
- In encoded mode, do not mix decoded Perl character strings with byte strings. Invalid byte sequences and output characters that cannot be represented cause an exception.
- Use `border => 'ascii'` for legacy encodings that cannot represent Unicode box-drawing characters.
