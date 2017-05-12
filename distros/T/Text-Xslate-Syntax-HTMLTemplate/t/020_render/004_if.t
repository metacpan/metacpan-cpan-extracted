#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_render(<<'END;', expected => "\n");
<TMPL_IF NAME=foo>foo is true</TMPL_IF>
END;

compare_render(<<'END;', params => { foo => 0 }, expected => "\n");
<TMPL_IF NAME=foo>foo is true</TMPL_IF>
END;

compare_render(<<'END;', params => { foo => 1 }, expected => "foo is true\n");
<TMPL_IF NAME=foo>foo is true</TMPL_IF>
END;

compare_render(<<'END;', params => { foo => ''}, expected => "foo is false\n");
<TMPL_IF NAME=foo>foo is true<TMPL_ELSE>foo is false</TMPL_IF>
END;

compare_render(<<'END;', params => { foo => 'x'}, expected => "foo is true\n");
<TMPL_IF NAME=foo>foo is true<TMPL_ELSE>foo is false</TMPL_IF>
END;

compare_render(<<'END;');
<TMPL_IF NAME=foo>foo is true<TMPL_ELSIF NAME=bar>bar is true</TMPL_IF>
END;

compare_render(<<'END;');
<TMPL_IF NAME=foo>foo is true<TMPL_ELSIF NAME=bar>bar is true<TMPL_ELSE>both false</TMPL_IF>
END;

compare_render(<<'END;', params => { foo => 1}, expected => "foo == 1\n");
<TMPL_IF EXPR="foo == 1">foo == 1</TMPL_IF>
END;

compare_render(<<'END;', params => { foo => 1}, expected => "foo eq 1\n");
<TMPL_IF EXPR="foo eq 1">foo eq 1</TMPL_IF>
END;

compare_render(<<'END;', params => { foo => 0}, expected => "foo != 1\n");
<TMPL_IF EXPR="foo != 1">foo != 1</TMPL_IF>
END;

compare_render(<<'END;', params => { foo => 0}, expected => "foo ne 1\n");
<TMPL_IF EXPR="foo ne 1">foo ne 1</TMPL_IF>
END;

compare_render(<<'END;', params => { foo => 0, bar => 1}, expected => "foo or bar\n");
<TMPL_IF EXPR="foo or bar">foo or bar</TMPL_IF>
END;

compare_render(<<'END;', params => { foo => 1, bar => 1}, expected => "foo and bar\n");
<TMPL_IF EXPR="foo and bar">foo and bar</TMPL_IF>
END;

compare_render(<<'END;', expected => "foo is false\n");
<TMPL_IF EXPR="not foo">foo is false</TMPL_IF>
END;

compare_render(<<'END;', expected => "foo is false\n");
<TMPL_IF EXPR="! foo">foo is false</TMPL_IF>
END;

compare_render(<<'END;', expected => "foo is false\n", params => {foo => 0});
<TMPL_IF EXPR="foo">foo is true<TMPL_ELSE>foo is false</TMPL_IF>
END;

compare_render(<<'END;', expected => "foo is true\n", params => {foo => 1});
<TMPL_IF EXPR="foo">foo is true<TMPL_ELSE>foo is false</TMPL_IF>
END;

compare_render(<<'END;', expected => "foo is false\n", params => {foo => 0});
<TMPL_UNLESS EXPR="foo">foo is false<TMPL_ELSE>foo is true</TMPL_UNLESS>
END;

compare_render(<<'END;', expected => "foo is true\n", params => {foo => 1});
<TMPL_UNLESS EXPR="foo">foo is false<TMPL_ELSE>foo is true</TMPL_UNLESS>
END;


done_testing;


