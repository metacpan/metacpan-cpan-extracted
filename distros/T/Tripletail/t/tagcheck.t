use Test::More tests => 32;
use Test::Exception;
use strict;
use warnings;

BEGIN {
    eval q{use Tripletail qw(/dev/null)};
}

END {
}

my $src = qq{
    <foo>
    <hr>aaa</hr>
    <strong>foobar
    http://example.com/あああ
    http://example.com/[test]#[test]
    <a href="http://example.com/" name="a">あああ</a>
    <table>
      <tr><td>foo</td></tr>
      <tr><th>foo</th></tr>
      foo</th>
      <strong>aaa

      http://example.com/あああ
    </table>
    </foo>
    </table>
};

my $dst_1 = qq{
    &lt;foo&gt;
    <hr>aaa
    <strong>foobar</strong>
    <a href="http://example.com/" target="_blank">http://example.com/</a>あああ
    <a href="http://example.com/[test]#[test]" target="_blank">http://example.com/[test]#[test]</a>
    &lt;a href=&quot;http://example.com/&quot; name=&quot;a&quot;&gt;あああ&lt;/a&gt;
    &lt;table&gt;
      &lt;tr&gt;&lt;td&gt;foo&lt;/td&gt;&lt;/tr&gt;
      &lt;tr&gt;&lt;th&gt;foo&lt;/th&gt;&lt;/tr&gt;
      foo&lt;/th&gt;
      <strong>aaa</strong>

      <a href="http://example.com/" target="_blank">http://example.com/</a>あああ
    &lt;/table&gt;
    &lt;/foo&gt;
    &lt;/table&gt;
};

my $dst_2 = qq{
    &lt;foo&gt;
    <hr>aaa
    &lt;strong&gt;foobar
    <a href="http://example.com/">http://example.com/</a>あああ
    <a href="http://example.com/[test]#[test]">http://example.com/[test]#[test]</a>
    <a href="http://example.com/" name="a">あああ</a>
    <table><tr><td>foo</td></tr><tr>&lt;th&gt;foo&lt;/th&gt;</tr></table>
    &lt;/foo&gt;
    &lt;/table&gt;
};

my $dst_3 = qq{
    &lt;foo&gt;
    &lt;hr&gt;aaa&lt;/hr&gt;
    &lt;strong&gt;foobar
    <a href="http://example.com/" target="_new">http://example.com/</a>あああ
    <a href="http://example.com/[test]#[test]" target="_new">http://example.com/[test]#[test]</a>
    <a href="http://example.com/" target="_new">あああ</a>
    <table>
      <tr><td>foo</td></tr>
      <tr></tr>
      foo&lt;/th&gt;
      &lt;strong&gt;aaa

      <a href="http://example.com/" target="_new">http://example.com/</a>あああ
    </table>
    &lt;/foo&gt;
    &lt;/table&gt;
};

my $tc;
ok($tc = $TL->newTagCheck, 'newTagCheck');

dies_ok {$tc->setAllowTag} 'setAllowTag undef';
dies_ok {$tc->setAllowTag(\123)} 'setAllowTag ref';
ok($tc->setAllowTag(qq{:HR;STRONG}), 'setAllowTag');

dies_ok {$tc->setAutoLink(\123)} 'setAutoLink ref';
ok($tc->setAutoLink(1), 'setAutoLink');

dies_ok {$tc->setATarget(\123)} 'setATarget ref';
ok($tc->setATarget('_blank'), 'setATarget');

dies_ok {$tc->setTagBreak} 'setTagBreak undef';
dies_ok {$tc->setTagBreak(\123)} 'setTagBreak ref';
dies_ok {$tc->setTagBreak('file')} 'setTagBreak no line block none';
ok($tc->setTagBreak('line'), 'setTagBreak');

dies_ok {$tc->check} 'check undef';
dies_ok {$tc->check(\123)} 'check ref';
is($tc->check($src), $dst_1, 'check (1)');

ok($tc->setATarget,'setATarget undef');

dies_ok {$tc->addAllowTag} 'addAllowTag undef';
dies_ok {$tc->addAllowTag(\123)} 'addAllowTag ref';


ok($tc->addAllowTag(qq{!STRONG;TABLE[TR]{none};TR[TD,TH,*];TD{none};A(HREF,TARGET,NAME)}), 'addAllowTag');
is($tc->check($src), $dst_2, 'check (2)');

ok($tc->setAllowTag(qq{;TABLE[TR,*]{none};TR[TD];TH{block};TD[*]{none};A(HREF,TARGET)}), 'setAllowTag');
ok($tc->setATarget('_new'),'setATarget new');
is($tc->check($src), $dst_3, 'check (3)');

ok(my $info = Tripletail::TagCheck::TagInfo->new('A'), 'TagInfo new');
is($info->isAllowedAttribute(''), 1 ,'isAllowedAttribute');

$tc = $TL->newTagCheck;
$tc->setAllowTag(':BR;X;Y;Z');
is($tc->check(q{<br><BR>}), q{<br><BR>}, 'check :tag');
is($tc->check(q{<br/><BR/><br /><BR />}), q{<br /><BR /><br /><BR />}, 'check :tag');
is($tc->check(q{<x><y><Z></Z></y></x>}), q{<x><y><Z></Z></y></x>}, 'check ;tag');
is($tc->check(q{<x><y><Z>}), q{<x><y><Z></Z></y></x>}, 'check ;tag');
is($tc->check(q{<x><y><Z/>}), q{<x><y><Z /></y></x>}, 'check ;tag');
is($tc->check(q{<x><y><Z></Z>}), q{<x><y><Z></Z></y></x>}, 'check ;tag');
is($tc->check(q{<x><y><Z></y></x>}), q{<x><y><Z></y></x></Z>}, 'check ;tag');

