use strict;
use warnings;
use Test::More;
use File::Temp 'tempfile';
use Text::Stencil;

# arrayref rows
my $r = Text::Stencil->new(header => '<ul>', row => '<li>{0:int}: {1:html}</li>', footer => '</ul>');
ok ref $r, 'new returns object';
is $r->render([[1, 'hello'], [2, '<b>world</b>']]),
    '<ul><li>1: hello</li><li>2: &lt;b&gt;world&lt;/b&gt;</li></ul>', 'arrayref render';

# hashref rows
my $rh = Text::Stencil->new(header => '<ul>', row => '<li>{name:html} ({id:int})</li>', footer => '</ul>');
is $rh->render([{ id => 1, name => 'Alice' }, { id => 2, name => 'Bob & Eve' }]),
    '<ul><li>Alice (1)</li><li>Bob &amp; Eve (2)</li></ul>', 'hashref render';

# separator
is(Text::Stencil->new(row => '{0:raw},{1:raw}', separator => "\n")->render([['a','b'], ['c','d']]),
    "a,b\nc,d", 'separator');

# url
is(Text::Stencil->new(row => '{0:url}')->render([['hello world&foo=bar']]),
    'hello%20world%26foo%3Dbar', 'url escape');

# json
is(Text::Stencil->new(row => '"{0:json}"')->render([["he said \"hi\"\nbye"]]),
    '"he said \\"hi\\"\\nbye"', 'json escape');
is(Text::Stencil->new(row => '{0:json}')->render([["\x00\x1f"]]),
    '\u0000\u001f', 'json control chars');

# html_br
is(Text::Stencil->new(row => '{0:html_br}')->render([["line1\nline2\n<end>"]]),
    'line1<br>line2<br>&lt;end&gt;', 'html_br');

# trim
is(Text::Stencil->new(row => '[{0:trim}]')->render([["  hello  \n"]]),
    '[hello]', 'trim');

# uc / lc
is(Text::Stencil->new(row => '{0:uc}')->render([['Hello']]), 'HELLO', 'uc');
is(Text::Stencil->new(row => '{0:lc}')->render([['Hello']]), 'hello', 'lc');

# int_comma
is(Text::Stencil->new(row => '{0:int_comma}')->render([[1234567]]),
    '1,234,567', 'int_comma');
is(Text::Stencil->new(row => '{0:int_comma}')->render([[-42]]),
    '-42', 'int_comma negative');

# float
is(Text::Stencil->new(row => '{0:float}')->render([[3.14159]]),
    '3.14', 'float default precision 2');
is(Text::Stencil->new(row => '{0:float:4}')->render([[3.14159]]),
    '3.1416', 'float precision 4');

# pad / rpad
is(Text::Stencil->new(row => '[{0:pad:8}]')->render([['hi']]),
    '[      hi]', 'pad left');
is(Text::Stencil->new(row => '[{0:rpad:8}]')->render([['hi']]),
    '[hi      ]', 'rpad right');
is(Text::Stencil->new(row => '[{0:pad:2}]')->render([['hello']]),
    '[hello]', 'pad no-op when shorter');

# trunc
is(Text::Stencil->new(row => '{0:trunc:10}')->render([['short']]),
    'short', 'trunc no-op');
is(Text::Stencil->new(row => '{0:trunc:10}')->render([['this is a long string']]),
    'this is...', 'trunc with ...');

# default
is(Text::Stencil->new(row => '{0:default:N/A}')->render([[undef]]),
    'N/A', 'default for undef');
is(Text::Stencil->new(row => '{0:default:N/A}')->render([['val']]),
    'val', 'default not used when defined');
is(Text::Stencil->new(row => '[{0:default:}]')->render([[undef]]),
    '[]', 'default empty string for undef');

# chaining: trim then html
is(Text::Stencil->new(row => '{0:trim|html}')->render([['  <b>hi</b>  ']]),
    '&lt;b&gt;hi&lt;/b&gt;', 'chain trim|html');

# chaining: trim then uc
is(Text::Stencil->new(row => '{0:trim|uc}')->render([['  hello  ']]),
    'HELLO', 'chain trim|uc');

# chaining: default then html
is(Text::Stencil->new(row => '{0:default:<none>|html}')->render([[undef]]),
    '&lt;none&gt;', 'chain default|html');

# chaining: trunc then html
is(Text::Stencil->new(row => '{0:trunc:8|html}')->render([['<script>alert("x")</script>']]),
    '&lt;scri...', 'chain trunc|html');

# raw / default type
is(Text::Stencil->new(row => '{0:raw}')->render([['<b>']]), '<b>', 'raw');
is(Text::Stencil->new(row => '{0}')->render([['<b>']]), '<b>', 'default is raw');

# empty rows
is $r->render([]), '<ul></ul>', 'empty rows';

# bare
is(Text::Stencil->new(row => '{0:int}', separator => ',')->render([[1],[2],[3]]),
    '1,2,3', 'bare');

# unicode
is(Text::Stencil->new(row => '{0:html}')->render([["\x{2014}"]]), "\x{2014}", 'unicode em-dash');
is(Text::Stencil->new(row => '{0:html}')->render([["\x{30D5}\x{30EC}"]]),
    "\x{30D5}\x{30EC}", 'unicode japanese');

# render_one
my $one = Text::Stencil->new(header => '{', row => '"id":{0:int},"name":"{1:json}"', footer => '}');
is $one->render_one([42, 'Alice "A"']), '{"id":42,"name":"Alice \\"A\\""}', 'render_one arrayref';
is(Text::Stencil->new(header => '{', row => '"v":{val:int}', footer => '}')->render_one({val => 7}),
    '{"v":7}', 'render_one hashref');

# render_to_fh
my ($fh, $fname) = tempfile(UNLINK => 1);
Text::Stencil->new(row => '{0:int}', separator => "\n")->render_to_fh($fh, [[1],[2],[3]]);
close $fh;
open my $rfh, '<', $fname;
is(do { local $/; <$rfh> }, "1\n2\n3", 'render_to_fh');

# clone
my $orig = Text::Stencil->new(header => '<t>', row => '{0:int}', footer => '</t>');
my $cloned = $orig->clone(row => '{0:html}');
is $cloned->render([['<x>']]), '<t>&lt;x&gt;</t>', 'clone reuses header/footer';

# render_sorted
my $sort_arr = Text::Stencil->new(row => '{0:int}:{1:raw}', separator => ',');
is $sort_arr->render_sorted([[2,'b'],[1,'a'],[3,'c']], 1),
    '1:a,2:b,3:c', 'render_sorted arrayref by col';
my $sort_hash = Text::Stencil->new(row => '{id:int}:{name:raw}', separator => ',');
is $sort_hash->render_sorted([{id=>3,name=>'c'},{id=>1,name=>'a'},{id=>2,name=>'b'}], 'name'),
    '1:a,2:b,3:c', 'render_sorted hashref by field';
is $sort_arr->render_sorted([], 0), '', 'render_sorted empty rows';

# columns
my $c1 = Text::Stencil->new(row => '{0:int} {2:html}');
is_deeply $c1->columns, [0, 2], 'columns arrayref';
my $c2 = Text::Stencil->new(row => '{name:html} {id:int}');
is_deeply $c2->columns, ['name', 'id'], 'columns hashref';

# hex
is(Text::Stencil->new(row => '{0:hex}')->render([['ABC']]), '414243', 'hex');

# base64
is(Text::Stencil->new(row => '{0:base64}')->render([['Hello']]), 'SGVsbG8=', 'base64');
is(Text::Stencil->new(row => '{0:base64}')->render([['ab']]), 'YWI=', 'base64 padding');
is(Text::Stencil->new(row => '{0:base64url}')->render([['ab']]), 'YWI', 'base64url no padding');
is(Text::Stencil->new(row => '{0:base64url}')->render([["\xff\xfe"]]), '__4', 'base64url safe chars');

# count
is(Text::Stencil->new(row => '{0:count}')->render([[[1,2,3]]]), '3', 'count array');
is(Text::Stencil->new(row => '{0:count}')->render([[{a=>1,b=>2}]]), '2', 'count hash');
is(Text::Stencil->new(row => '{0:count}')->render([['scalar']]), '0', 'count non-ref');

# bool
is(Text::Stencil->new(row => '{0:bool:yes:no}')->render([['hello']]), 'yes', 'bool truthy');
is(Text::Stencil->new(row => '{0:bool:yes:no}')->render([['0']]), 'no', 'bool falsy 0');
is(Text::Stencil->new(row => '{0:bool:yes:no}')->render([[undef]]), 'no', 'bool undef');
is(Text::Stencil->new(row => '{0:bool}')->render([['x']]), 'true', 'bool default truthy');
is(Text::Stencil->new(row => '{0:bool}')->render([['0']]), 'false', 'bool default falsy');

# date
is(Text::Stencil->new(row => '{0:date}')->render([['0']]), '1970-01-01 00:00:00', 'date epoch 0');
is(Text::Stencil->new(row => '{0:date:%Y-%m-%d}')->render([['1704067200']]), '2024-01-01', 'date custom fmt');

# row_count
my $rc = Text::Stencil->new(row => '{0:int}');
$rc->render([[1],[2],[3]]);
is $rc->row_count, 3, 'row_count';
$rc->render([]);
is $rc->row_count, 0, 'row_count empty';

# sprintf
is(Text::Stencil->new(row => '{0:sprintf:%05d}')->render([[42]]), '00042', 'sprintf %05d');
is(Text::Stencil->new(row => '{0:sprintf:%08x}')->render([[255]]), '000000ff', 'sprintf %08x');
is(Text::Stencil->new(row => '{0:sprintf:%.3f}')->render([[3.14]]), '3.140', 'sprintf %.3f');
is(Text::Stencil->new(row => '{0:sprintf:%-10s}')->render([['hi']]), 'hi        ', 'sprintf %-10s');

# sprintf rejection of unsafe/multi specifiers
is(Text::Stencil->new(row => '{0:sprintf:%d%s}')->render([['42']]), '42', 'sprintf multi-spec passthrough');
is(Text::Stencil->new(row => '{0:sprintf:%n}')->render([['42']]), '42', 'sprintf %n passthrough');

# replace
is(Text::Stencil->new(row => '{0:replace:foo:bar}')->render([['foo baz foo']]),
    'bar baz bar', 'replace all');
is(Text::Stencil->new(row => '{0:replace:x:}')->render([['axbxc']]),
    'abc', 'replace delete');
is(Text::Stencil->new(row => '{0:replace:ab:XY}')->render([['abc']]),
    'XYc', 'replace longer match');

# substr
is(Text::Stencil->new(row => '{0:substr:0:5}')->render([['Hello World']]),
    'Hello', 'substr start:len');
is(Text::Stencil->new(row => '{0:substr:6}')->render([['Hello World']]),
    'World', 'substr start only');
is(Text::Stencil->new(row => '{0:substr:99}')->render([['short']]),
    '', 'substr beyond length');

# plural
is(Text::Stencil->new(row => '{0:plural:item:items}')->render([[1]]),
    '1 item', 'plural singular');
is(Text::Stencil->new(row => '{0:plural:item:items}')->render([[5]]),
    '5 items', 'plural plural');
is(Text::Stencil->new(row => '{0:plural:item:items}')->render([[0]]),
    '0 items', 'plural zero');

# from_file
my ($tf, $tname) = tempfile(UNLINK => 1, SUFFIX => '.tpl');
print $tf <<'TPL';
__HEADER__
<ul>
__ROW__
<li>{0:html}</li>
__FOOTER__
</ul>
TPL
close $tf;
my $from_f = Text::Stencil->from_file($tname);
is $from_f->render([['a&b'], ['<c>']]), "<ul>\n<li>a&amp;b</li>\n<li>&lt;c&gt;</li>\n</ul>\n", 'from_file';

# from_file without markers (whole file = row)
my ($tf2, $tname2) = tempfile(UNLINK => 1, SUFFIX => '.tpl');
print $tf2 '{0:int}';
close $tf2;
is(Text::Stencil->from_file($tname2, separator => ',')->render([[1],[2]]), '1,2', 'from_file bare');

# if / unless
is(Text::Stencil->new(row => '{0:if: (active)}')->render([['1']]), ' (active)', 'if truthy');
is(Text::Stencil->new(row => '{0:if: (active)}')->render([['0']]), '', 'if falsy');
is(Text::Stencil->new(row => '{0:if: (active)}')->render([['']]), '', 'if empty');
is(Text::Stencil->new(row => '{0:if:YES}')->render([[undef]]), '', 'if undef');
is(Text::Stencil->new(row => '{0:unless:N/A}')->render([['']]), 'N/A', 'unless empty');
is(Text::Stencil->new(row => '{0:unless:N/A}')->render([['x']]), '', 'unless truthy');

# map
is(Text::Stencil->new(row => '{0:map:a=Alpha:b=Beta:*=Other}')->render([['a']]), 'Alpha', 'map match');
is(Text::Stencil->new(row => '{0:map:a=Alpha:b=Beta:*=Other}')->render([['b']]), 'Beta', 'map match 2');
is(Text::Stencil->new(row => '{0:map:a=Alpha:b=Beta:*=Other}')->render([['z']]), 'Other', 'map default');
is(Text::Stencil->new(row => '{0:map:y=Yes:n=No}')->render([['x']]), 'x', 'map passthrough');
is(Text::Stencil->new(row => '{0:map:*=Other:a=Alpha}')->render([['a']]), 'Alpha', 'map wildcard-first exact wins');

# wrap
is(Text::Stencil->new(row => '{0:wrap:<b>:</b>}')->render([['hi']]), '<b>hi</b>', 'wrap non-empty');
is(Text::Stencil->new(row => '{0:wrap:<b>:</b>}')->render([['']]), '', 'wrap empty');
is(Text::Stencil->new(row => '{0:wrap:<b>:</b>}')->render([[undef]]), '', 'wrap undef');
is(Text::Stencil->new(row => '{0:wrap:>>}')->render([['x']]), '>>x', 'wrap prefix only');

# number_si
is(Text::Stencil->new(row => '{0:number_si}')->render([[1500]]), '1.5K', 'number_si K');
is(Text::Stencil->new(row => '{0:number_si}')->render([[2300000]]), '2.3M', 'number_si M');
is(Text::Stencil->new(row => '{0:number_si}')->render([[42]]), '42', 'number_si small');

# bytes_si
is(Text::Stencil->new(row => '{0:bytes_si}')->render([[1536]]), '1.5 KB', 'bytes_si KB');
is(Text::Stencil->new(row => '{0:bytes_si}')->render([[1073741824]]), '1.0 GB', 'bytes_si GB');
is(Text::Stencil->new(row => '{0:bytes_si}')->render([[500]]), '500 B', 'bytes_si B');

# elapsed
is(Text::Stencil->new(row => '{0:elapsed}')->render([[3661]]), '1h 1m 1s', 'elapsed');
is(Text::Stencil->new(row => '{0:elapsed}')->render([[90061]]), '1d 1h 1m 1s', 'elapsed days');
is(Text::Stencil->new(row => '{0:elapsed}')->render([[45]]), '45s', 'elapsed secs');

# ago (just check it produces something reasonable)
my $now = time();
like(Text::Stencil->new(row => '{0:ago}')->render([[$now - 120]]), qr/2m ago/, 'ago minutes');
like(Text::Stencil->new(row => '{0:ago}')->render([[$now - 7200]]), qr/2h ago/, 'ago hours');

# escape_char
is(Text::Stencil->new(row => '[0:int]', escape_char => '[')->render([[42]]), '42', 'escape_char [');
is(Text::Stencil->new(row => '|0:int|', escape_char => '|')->render([[42]]), '42', 'escape_char | symmetric');
is(Text::Stencil->new(
    header => '{"items":[',
    row => '{"id":[0:int]}',
    footer => ']}',
    separator => ',',
    escape_char => '[',
)->render([[1],[2]]), '{"items":[{"id":1},{"id":2}]}', 'escape_char JSON');

# mask
is(Text::Stencil->new(row => '{0:mask:4}')->render([['secret123456']]), '********3456', 'mask keep 4');
is(Text::Stencil->new(row => '{0:mask:3}')->render([['4111222233334444']]), '*************444', 'mask card');
is(Text::Stencil->new(row => '{0:mask}')->render([['abcdefgh']]), '****efgh', 'mask default 4');
is(Text::Stencil->new(row => '{0:mask:0}')->render([['secret']]), '******', 'mask all');
is(Text::Stencil->new(row => '{0:mask:10}')->render([['short']]), 'short', 'mask keep > len');


# shorthand new($row)
is(Text::Stencil->new("{0:int}")->render([[42]]), "42", "new shorthand");
is(Text::Stencil->new("{name:html}")->render([{name => "<b>"}]), "&lt;b&gt;", "new shorthand hash");

# empty render with no header/footer
is(Text::Stencil->new(row => '{0:int}')->render([]), '', 'bare empty render');

# replace with empty needle (should passthrough, not hang)
is(Text::Stencil->new(row => '{0:replace::X}')->render([['abc']]),
    'abc', 'replace empty needle passthrough');

# replace with empty replacement
is(Text::Stencil->new(row => '{0:replace:x:}')->render([['axbxc']]),
    'abc', 'replace empty replacement');

# negative int_comma > 999
is(Text::Stencil->new(row => '{0:int_comma}')->render([[-1234567]]),
    '-1,234,567', 'int_comma large negative');

# elapsed 0
is(Text::Stencil->new(row => '{0:elapsed}')->render([[0]]),
    '0s', 'elapsed zero');

# bool with empty truthy text
is(Text::Stencil->new(row => '{0:bool::no}')->render([['yes']]),
    '', 'bool empty truthy text');
is(Text::Stencil->new(row => '{0:bool::no}')->render([['0']]),
    'no', 'bool empty truthy falsy');

# escape_char < >
is(Text::Stencil->new(row => '<0:int>', escape_char => '<')->render([[42]]),
    '42', 'escape_char <');

# negative float
is(Text::Stencil->new(row => '{0:float:2}')->render([[-3.14]]),
    '-3.14', 'float negative');

# 3+ transform chain (exercises double-buffer ping-pong)
is(Text::Stencil->new(row => '{0:trim|uc|html}')->render([['  <b>hi</b>  ']]),
    '&lt;B&gt;HI&lt;/B&gt;', '3-transform chain trim|uc|html');
is(Text::Stencil->new(row => '{0:default:none|trim|uc}')->render([[undef]]),
    'NONE', '3-transform chain default|trim|uc');

# mask chained with html
is(Text::Stencil->new(row => '{0:mask:4|html}')->render([['secret<tag>']]),
    '*******tag&gt;', 'mask chained html');

# {#} row number placeholder
is(Text::Stencil->new(row => '{#}:{0:raw}', separator => ',')->render([['a'],['b'],['c']]),
    '0:a,1:b,2:c', 'rownum basic');
# rownum with int_comma on larger index
like(Text::Stencil->new(row => '{#:int_comma}', separator => ',')->render([map {[$_]} 0..1000]),
    qr/1,000$/, 'rownum int_comma');
is(Text::Stencil->new(row => '{#:pad:4}:{0:raw}', separator => ',')->render([['a'],['b']]),
    '   0:a,   1:b', 'rownum with pad');
is(Text::Stencil->new(row => '{#}')->render_one([42]),
    '0', 'rownum render_one');

# skip_if
my $skip_if = Text::Stencil->new(row => '{0:raw}', separator => ',', skip_if => 1);
is($skip_if->render([['a',''],['b','1'],['c','0'],['d',undef]]),
    'a,c,d', 'skip_if skips truthy');

# skip_if with hash mode
my $skip_if_h = Text::Stencil->new(row => '{name:raw}', separator => ',', skip_if => 'hidden');
is($skip_if_h->render([{name=>'a',hidden=>''},{name=>'b',hidden=>'1'},{name=>'c',hidden=>'0'}]),
    'a,c', 'skip_if hash mode');

# skip_unless
my $skip_unless = Text::Stencil->new(row => '{0:raw}', separator => ',', skip_unless => 1);
is($skip_unless->render([['a',''],['b','1'],['c','0'],['d',undef]]),
    'b', 'skip_unless skips falsy');

# skip_unless with hash mode
my $skip_unless_h = Text::Stencil->new(row => '{name:raw}', separator => ',', skip_unless => 'active');
is($skip_unless_h->render([{name=>'a',active=>'yes'},{name=>'b',active=>''},{name=>'c',active=>'1'}]),
    'a,c', 'skip_unless hash mode');

# render_cb basic
{
    my @data = ([1,'a'],[2,'b'],[3,'c']);
    my $i = 0;
    my $cb_s = Text::Stencil->new(row => '{0:int}:{1:raw}', separator => ',');
    my $result = $cb_s->render_cb(sub { $i <= $#data ? $data[$i++] : undef });
    is($result, '1:a,2:b,3:c', 'render_cb basic');
}

# render_cb with fh
{
    my @data = ([1],[2],[3]);
    my $i = 0;
    my ($fh3, $fname3) = tempfile(UNLINK => 1);
    my $cb_fh = Text::Stencil->new(row => '{0:int}', separator => "\n");
    $cb_fh->render_cb(sub { $i <= $#data ? $data[$i++] : undef }, $fh3);
    close $fh3;
    open my $rfh3, '<', $fname3;
    is(do { local $/; <$rfh3> }, "1\n2\n3", 'render_cb with fh');
}

# render_cb returning undef immediately
{
    my $cb_empty = Text::Stencil->new(header => '[', row => '{0:int}', footer => ']');
    is($cb_empty->render_cb(sub { undef }), '[]', 'render_cb undef immediately');
}

# render_sorted descending
is(Text::Stencil->new(row => '{0:raw}', separator => ',')->render_sorted(
    [['c'],['a'],['b']], 0, {descending => 1}),
    'c,b,a', 'render_sorted descending');

# render_sorted numeric
is(Text::Stencil->new(row => '{0:raw}', separator => ',')->render_sorted(
    [['10'],['2'],['1']], 0, {numeric => 1}),
    '1,2,10', 'render_sorted numeric asc');

# render_sorted numeric descending
is(Text::Stencil->new(row => '{0:raw}', separator => ',')->render_sorted(
    [['10'],['2'],['1']], 0, {numeric => 1, descending => 1}),
    '10,2,1', 'render_sorted numeric desc');

# UTF-8 multibyte edge cases
is(Text::Stencil->new(row => '{0:uc}')->render([['aBcD']]), 'ABCD', 'uc on ASCII');
is(Text::Stencil->new(row => '{0:lc}')->render([['aBcD']]), 'abcd', 'lc on ASCII');
is(Text::Stencil->new(row => '{name:html}')->render([{name => "\x{2603}"}]),
    "\x{2603}", 'hashref with unicode value passthrough');
is(Text::Stencil->new(row => '{0:html}')->render([["\x{1F600}<b>"]]),
    "\x{1F600}&lt;b&gt;", 'html escape preserves emoji');
is(Text::Stencil->new(row => '{0:json}')->render([["\x{2014}test"]]),
    "\x{2014}test", 'json preserves non-ASCII');

# stress: large row count
{
    my $big = Text::Stencil->new(row => '{0:int}', separator => ',');
    my @rows = map { [$_] } 1..10000;
    my $out = $big->render(\@rows);
    like $out, qr/^1,/, 'stress 10K rows start';
    like $out, qr/,10000$/, 'stress 10K rows end';
}

# stress: long chain
is(Text::Stencil->new(row => '{0:trim|lc|trim|lc|trim|lc|html}')->render([['  <B>X</B>  ']]),
    '&lt;b&gt;x&lt;/b&gt;', 'stress 7-deep chain');

# stress: large field value
{
    my $long = 'x' x 100000;
    is(length(Text::Stencil->new(row => '{0:html}')->render([[$long]])), 100000, 'stress 100K field');
}

# render_to_fh flush boundary (>64KB output)
{
    my ($fhb, $fnameb) = tempfile(UNLINK => 1);
    my $big_fh = Text::Stencil->new(row => '{0:raw}', separator => "\n");
    my @rows = map { ['x' x 1000] } 1..200;  # 200KB total
    $big_fh->render_to_fh($fhb, \@rows);
    close $fhb;
    open my $rfhb, '<', $fnameb;
    my $content = do { local $/; <$rfhb> };
    my @lines = split /\n/, $content;
    is scalar @lines, 200, 'render_to_fh flush 200 rows';
    is length($lines[0]), 1000, 'render_to_fh row length preserved';
}

# literal escape {{ → {
is(Text::Stencil->new(row => '{{not a field}}')->render([['x']]),
    '{not a field}}', 'literal {{ escape');
is(Text::Stencil->new(row => '{{"id":{0:int}}')->render([[42]]),
    '{"id":42}', 'literal {{ in JSON context');
is(Text::Stencil->new(row => '[[[0:int]]', escape_char => '[')->render([[7]]),
    '[7]', 'literal [[ with escape_char');

# interaction: render_cb + skip_if
{
    my @data = ([1,'yes'],[2,''],[3,'yes'],[4,'']);
    my $i = 0;
    my $cb_skip = Text::Stencil->new(row => '{0:int}', separator => ',', skip_if => 1);
    my $r = $cb_skip->render_cb(sub { $i <= $#data ? $data[$i++] : undef });
    is $r, '2,4', 'render_cb + skip_if';
}

# interaction: render_sorted + skip_unless
{
    my $s = Text::Stencil->new(row => '{0:raw}', separator => ',', skip_unless => 1);
    is $s->render_sorted([['c','1'],['a',''],['b','1']], 0), 'b,c', 'render_sorted + skip_unless';
}

# interaction: {#} with render_sorted (row number is output order, not input)
{
    my $s = Text::Stencil->new(row => '{#}:{0:raw}', separator => ',');
    is $s->render_sorted([['c'],['a'],['b']], 0), '0:a,1:b,2:c', 'rownum with render_sorted';
}

# all transforms with undef input
{
    my @xforms = qw(raw int int_comma float html html_br url json trim uc lc
                     hex base64 base64url mask elapsed ago number_si bytes_si);
    for my $xf (@xforms) {
        my $s = Text::Stencil->new(row => "{0:$xf}");
        my $out = $s->render([[undef]]);
        is $out, '', "undef with $xf produces empty";
    }
}

# negative column indices
is(Text::Stencil->new(row => '{-1:raw}')->render([['a','b','c']]), 'c', 'negative col -1');
is(Text::Stencil->new(row => '{-2:raw}')->render([['a','b','c']]), 'b', 'negative col -2');
is(Text::Stencil->new(row => '{-1:int}')->render([[1,2,3]]), '3', 'negative col -1 int');

# coalesce
my $coal = Text::Stencil->new(row => '{name:coalesce:nickname:Anonymous}');
is($coal->render([{name => 'Alice', nickname => 'Al'}]), 'Alice', 'coalesce primary present');
is($coal->render([{name => '', nickname => 'Al'}]), 'Al', 'coalesce fallback to second');
is($coal->render([{name => '', nickname => ''}]), 'Anonymous', 'coalesce fallback to default');
is($coal->render([{name => undef, nickname => undef}]), 'Anonymous', 'coalesce all undef');

# coalesce in array mode
is(Text::Stencil->new(row => '{0:coalesce:1:N/A}')->render([['', 'fallback']]),
    'fallback', 'coalesce array mode');

# multi-column sort
is(Text::Stencil->new(row => '{0:raw}{1:raw}', separator => ',')->render_sorted(
    [['b','2'],['a','1'],['a','2']], [0, 1]),
    'a1,a2,b2', 'multi-column sort');

# multi-column sort hash mode
is(Text::Stencil->new(row => '{name:raw}{age:raw}', separator => ',')->render_sorted(
    [{name=>'b',age=>'2'},{name=>'a',age=>'1'},{name=>'a',age=>'2'}], ['name', 'age']),
    'a1,a2,b2', 'multi-column sort hash');

# skip_if with negative column index
is(Text::Stencil->new(row => '{0:raw}', separator => ',', skip_if => -1)->render(
    [['a',''],['b','1'],['c','0']]), 'a,c', 'skip_if negative col');

# skip_unless with negative column index
is(Text::Stencil->new(row => '{0:raw}', separator => ',', skip_unless => -1)->render(
    [['a',''],['b','1'],['c','0']]), 'b', 'skip_unless negative col');

# coalesce with numeric fallback in hash mode
is(Text::Stencil->new(row => '{name:coalesce:0:fallback}')->render(
    [{name => '', 0 => 'zero_key'}]), 'zero_key', 'coalesce numeric key in hash mode');

# length transform
is(Text::Stencil->new(row => '{0:length}')->render([['hello']]), '5', 'length basic');
is(Text::Stencil->new(row => '{0:length}')->render([['']]),'0', 'length empty');
is(Text::Stencil->new(row => '{0:trim|length}')->render([['  ab  ']]), '2', 'length chained');

# descending sort shorthand with - prefix
is(Text::Stencil->new(row => '{name:raw}', separator => ',')->render_sorted(
    [{name=>'a'},{name=>'c'},{name=>'b'}], '-name'),
    'c,b,a', 'render_sorted -name descending shorthand');

# -field shorthand only works for single sort_by, not arrays (use {descending=>1} for arrays)
is(Text::Stencil->new(row => '{name:raw}', separator => ',')->render_sorted(
    [{name=>'a'},{name=>'c'},{name=>'b'}], ['name'], {descending => 1}),
    'c,b,a', 'render_sorted array descending via opts');

# substr with negative offset (should produce empty, not crash)
is(Text::Stencil->new(row => '{0:substr:-1}')->render([['hello']]),
    '', 'substr negative offset empty');

# render_one respects skip_if
is(Text::Stencil->new(row => '{0:raw}', skip_if => 1)->render_one(['val', '1']),
    '', 'render_one skip_if');
is(Text::Stencil->new(row => '{0:raw}', skip_if => 1)->render_one(['val', '']),
    'val', 'render_one skip_if not triggered');

# clone preserves skip_if
{
    my $orig = Text::Stencil->new(header => '<', row => '{0:raw}', footer => '>', skip_if => 1);
    my $cloned = $orig->clone(row => '{0:uc}');
    is $cloned->render([['a',''],['b','1']]), '<A>', 'clone preserves skip_if';
}

done_testing;
