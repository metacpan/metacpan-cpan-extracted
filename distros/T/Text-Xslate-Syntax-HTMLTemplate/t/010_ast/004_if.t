#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_ast(<<'END;', <<'END;');
[% if($foo){ %]foo is true[% } %]
END;
<TMPL_IF NAME=foo>foo is true</TMPL_IF>
END;

compare_ast(<<'END;', <<'END;');
[% if($foo){ %]foo is true[% }else{ %]foo is false[% } %]
END;
<TMPL_IF NAME=foo>foo is true<TMPL_ELSE>foo is false</TMPL_IF>
END;

compare_ast(<<'END;', <<'END;');
[% if($foo){ %]foo is true[% }elsif($bar){ %]bar is true[% } %]
END;
<TMPL_IF NAME=foo>foo is true<TMPL_ELSIF NAME=bar>bar is true</TMPL_IF>
END;

compare_ast(<<'END;', <<'END;');
[% if($foo){ %]foo is true[% }elsif($bar){ %]bar is true[% }else{ %]both false[% } %]
END;
<TMPL_IF NAME=foo>foo is true<TMPL_ELSIF NAME=bar>bar is true<TMPL_ELSE>both false</TMPL_IF>
END;

compare_ast(<<'END;', <<'END;');
[% if(!($foo == 2)){ %]foo is not 2[% } %]
END;
<TMPL_UNLESS EXPR='foo == 2'>foo is not 2</TMPL_UNLESS>
END;

compare_ast(<<'END;', <<'END;');
[% if(! $foo ){ %]foo is false[% }else{ %]foo is true[% } %]
END;
<TMPL_UNLESS EXPR="foo">foo is false<TMPL_ELSE>foo is true</TMPL_UNLESS>
END;

done_testing;


