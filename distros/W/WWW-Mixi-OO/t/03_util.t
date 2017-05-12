# -*- cperl -*-

use strict;
use warnings;
use Test::More qw(no_plan); # please supply nums for release
my $pkg;
BEGIN {
    $pkg = 'WWW::Mixi::OO::Session';
    use_ok $pkg;
}

TODO: {
    can_ok($pkg, 'absolute_uri');
    my $mixi_uri = 'http://mixi.jp';
    is($pkg->absolute_uri('home', $mixi_uri), "$mixi_uri/home.pl",
       'convert home to absolute');
    is($pkg->absolute_uri('list_user.pl?id=0', $mixi_uri),
       "$mixi_uri/list_user.pl?id=0", 'convert list_user to absolute');
    is($pkg->absolute_uri("$mixi_uri/list_user.pl?id=0", "http://example.com"),
       "$mixi_uri/list_user.pl?id=0", '... with wrong base');
};

TODO: {
    can_ok($pkg, 'remove_tag');
    is($pkg->remove_tag('<a href="abc">foo</a>'), 'foo', 'simple anchor');
    is($pkg->remove_tag('<a href="ab&cd">foo</a>'), 'foo', 'simple anchor with &');
    is($pkg->remove_tag('<div onclick="change(this, \'abc\');">foo</div>'),
       'foo', 'double quoted attribute has single quotes');
    is($pkg->remove_tag('<div onclick=\'change(this, "abc");\'>foo</div>'),
       'foo', 'single quoted attribute has double quotes');
    is($pkg->remove_tag('foo<!-- can you ignore this? -->bar'),
       'foobar', 'ordinary comment');
    is($pkg->remove_tag('foo<!--a href="abc">foo</a-->bar'),
       'foobar', 'commented elements');
};

TODO: {
    can_ok($pkg, 'escape');
    can_ok($pkg, 'unescape');
    can_ok($pkg, 'rewrite');

    my $do_test = sub {
	my ($test, $exp, $rewrite, $msg) = @_;
	my $ret;
	is(($ret = $pkg->escape($test)), $exp, $msg);
	is($pkg->unescape($ret), $test, '... and unescape');
	is($pkg->rewrite($test), $rewrite, '... and rewrite');
    };

    my $do_nothing_test = sub {
	my $test = shift;
	$do_test->($test, $test, $test, "escape $test (do nothing)");
    };

    $do_test->('&amp;', '&amp;amp;', '&', 'escape &amp;');

    $do_nothing_test->('&eacute;');
    $do_nothing_test->('&#64;');
    $do_nothing_test->('&#x7a;');

    $do_test->('<a href="foo">bar</a>',
	       '&lt;a href=&quot;foo&quot;&gt;bar&lt;/a&gt;',
	       'bar',
	       'escape normal anchor');

    $do_test->('<a href="foo?a=b&c=d">bar</a>',
	       '&lt;a href=&quot;foo?a=b&amp;c=d&quot;&gt;bar&lt;/a&gt;',
	       'bar',
	       'escape anchor has raw &');

    $do_test->('<span class="foo">bar&amp;baz</span>',
	       '&lt;span class=&quot;foo&quot;&gt;bar&amp;amp;baz&lt;/span&gt;',
	       'bar&baz',
	       'escape natural html with span & &amp;');

    $do_test->('<foo>&lt;!--bar--&gt;baz</foo>',
	       '&lt;foo&gt;&amp;lt;!--bar--&amp;gt;baz&lt;/foo&gt;',
	       '<!--bar-->baz',
	       'escape natural xml-like with escaped comment');

    $do_test->("<span class='foo'>bar&amp;baz</span>",
	       '&lt;span class=&apos;foo&apos;&gt;bar&amp;amp;baz&lt;/span&gt;',
	       'bar&baz',
	       'escape natural html with single quoted span & &amp;');
};

TODO: {
    can_ok($pkg, 'unquote');
    my $do_test = sub {
	my ($quoted, $unquote, $msg) = @_;
	is($pkg->unquote(qq|"$quoted"|), $unquote, "unquote double-quoted $msg");
	is($pkg->unquote(qq|'$quoted'|), $unquote, "... and single-quoted");
    };

    $do_test->('&quot;', qq|\"|, '&quot;');
    $do_test->('&apos;', qq|\'|, '&apos;');
    $do_test->('&quot;&apos;', qq|\"\'|, '&quot;&apos;');
};

TODO: {
    can_ok($pkg, 'extract_balanced_html_parts');
    my $text = '__junk_foo__
<ul>
  <li attr="1">foo</li>
  <li>bar
    <ul>
      __junk_bar_1__
      <li>bar-foo</li>
      <li>bar-bar</li>
      __junk_bar_2__
    </ul>
  </li>
  <li>baz
    <ul>
      __junk_baz_1__
      <li>baz-foo</li>
      __junk_baz_2__
      <li>baz-bar</li>
      __junk_baz_3__
  </li>
  __junk_qux__
</ul>
__junk_quux__';
    is_deeply(['<li attr="1">foo</li>', '<li>bar
    <ul>
      __junk_bar_1__
      <li>bar-foo</li>
      <li>bar-bar</li>
      __junk_bar_2__
    </ul>
  </li>', '<li>baz
    <ul>
      __junk_baz_1__
      <li>baz-foo</li>
      __junk_baz_2__
      <li>baz-bar</li>
      __junk_baz_3__
  </li>'], [$pkg->extract_balanced_html_parts(
     ignore_outside => 0,
     element => 'li',
     text => $text)], 'extract_balanced_html_parts: ignore_outside: 0');
    is_deeply(['<li>bar-foo</li>', '<li>bar-bar</li>', '<li>baz-foo</li>',
	       '<li>baz-bar</li>'], [$pkg->extract_balanced_html_parts(
     ignore_outside => 1,
     element => 'li',
     text => $text)], 'extract_balanced_html_parts: ignore_outside: 1');
    is_deeply([], [$pkg->extract_balanced_html_parts(
	ignore_outside => 2,
	element => 'li',
	text => $text)], 'extract_balanced_html_parts: ignore_outside: 2');
    is_deeply([qw(bar-foo bar-bar baz-foo baz-bar)],
	      [$pkg->extract_balanced_html_parts(
		  ignore_outside => 1,
		  exclude_border_element => 1,
		  element => 'li',
		  text => $text)], 'extract_balanced_html_parts: exclude_border_element: 1');
};
