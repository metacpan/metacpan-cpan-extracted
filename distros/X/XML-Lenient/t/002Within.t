use strict;
use warnings;
use Moo;
use Method::Signatures;
use Test::More;
use XML::Lenient;
no warnings "uninitialized";

my $p = XML::Lenient->new();
my $ml = '<x>asdf</x>';
my $within = $p->within($ml, 'x');
ok ('asdf' eq $within, "Simple within works");
$ml = '<x>asdf</x><x>qwer</x>';
$within = $p->within($ml, 'x');
ok ('asdf' eq $within, "Works with multiple tags");
$ml = 'qwer<x>asdf</x>';
$within = $p->within($ml, 'x');
ok ('asdf' eq $within, "Within works where tag doesn't start text");
ok ('applet' eq ${$p->{verbatim}}[0], "Correct default first verbatim tag");
$ml = '<x>asdf<pre><x></pre></x>';
my @stripped;
$p->_stripverbatim(\@stripped, \$ml);
ok ('<x>asdf<pre>0</pre></x>' eq $ml, "Replaced verbatim tag correctly");
$ml = '<x>asdf<pre><x></pre></x>';
$within = $p->within($ml, 'x');
ok ('asdf<pre><x></pre>' eq $within, "Within ignores inner verbatim tags");
$ml = '<x><x><x>asdf</x></x></x><x>qwer</x>';
$within = $p->within($ml, 'x', 2);
ok ('<x>asdf</x>' eq $within, "Indexing works with nested tags");
$within = $p->within($ml, 'x', 3);
ok ('asdf' eq $within, "Indexing works with deeply nested tags");
$within = $p->within($ml, 'x', 4);
ok ('qwer' eq $within, "Indexing works with multiple nested tags");
$ml = '<x><x>asdf</x>';
$within = $p->within($ml, 'x');
ok ('<x>asdf</x>' eq $within, "Handles unclosed tags");
$within = $p->within($ml, 'x', 2);
ok ('asdf' eq $within, "Handles nested mismatched tags");
$ml = '<a href="www.example.com">Click</a>';
$within = $p->within($ml, 'a');
ok ('Click' eq $within, "Within tags with values works");
$ml = '<x><y><z>asdf</z></y></x>';
$within = $p->within($ml, 'z');
ok ('asdf' eq $within, 'Outer non-target tags ignored');
$ml = '<x><pre>zxcv</pre><y><z>asdf</z></y></x>';
$within = $p->within($ml, 'z');
ok ('asdf' eq $within, 'Outer non-target tags and verbatim stuff within them ignored');
$ml = '<x><pre><z>xcv</pre><y><z>asdf</z></y></x>';
$within = $p->within($ml, 'z');
ok ('asdf' eq $within, 'Outer non-target tags containing verbatim target tag ignored');
$ml = '<x>
<x>
<x>
asdf
</x>
</x>
</x>
<x>
qwer
</x>';
$within = $p->within($ml, 'x', 2);
ok ('
<x>
asdf
</x>
' eq $within, "Indexing works with nested tags and multiple lines");
$ml = '<pre><x>zxcv</x></pre>';
$within = $p->within($ml, 'x');
ok ('' eq $within, 'Tags within verbatim tags are ignored');
$ml = '<x>asdf</x>';
$within = $p->within($ml, '');
ok ('' eq $within, "within returns nothing with zero length tag");
$within = $p->within($ml, undef);
ok ('' eq $within, "within returns nothing with undef tag");
$within = $p->within($ml, 'y');
ok ('' eq $within, "within returns nothing with valid, but missing, tag");
$ml = '<x><y>asdf</x></y>';
$within = $p->within($ml, 'x');
ok ('<y>asdf' eq $within, "Mismatched tags return something sensible");
$within = $p->within($ml, 'y');
ok ('asdf</x>' eq $within, "Mismatched tags return something sensible again");
$ml = '<x><x>asdf</x></x>';
$within = $p->within($ml, 'x', undef);
ok ('<x>asdf</x>' eq $within, "Nested within works with undef");
$within = $p->within($ml, 'x', 3);
ok ('' eq $within, "Within returns '' if index too high");
$ml = '<x><x><x>asdf</x></x></x><x>qwer</x>';
$within = $p->within($ml, 'x', 0);
ok ('<x><x>asdf</x></x>' eq $within, "Zero index is the first element");
$within = $p->within($ml, 'x', -1);
ok ('qwer' eq $within, "Negative index works as in Perl");
$within = $p->within($ml, 'x', -2);
ok ('asdf' eq $within, "Negative indices continue working backwards");
$within = $p->within($ml, 'x', '-1-');
ok ('qwer' eq $within, "Garbled negative index works");
$within = $p->within(undef, 'x');
ok ('' eq $within, "Within returns '' if ML undefined");

done_testing;