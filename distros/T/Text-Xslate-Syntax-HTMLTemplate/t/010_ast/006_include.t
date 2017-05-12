#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_ast(<<'END;', <<'END;');
[% include "empty.tx" %]
END;
<TMPL_INCLUDE "empty.tx">
END;

compare_ast(<<'END;', <<'END;');
[% $name %]
[% for $loop->$__dummy_item__1 { %]
[%   include "x.tx" { __ROOT__.merge($__dummy_item__1) } %]
[% } %]
[% $name %]
END;
<TMPL_VAR NAME=name>
<TMPL_LOOP NAME=loop>
<TMPL_INCLUDE "x.tx">
</TMPL_LOOP>
<TMPL_VAR NAME=name>
END;



done_testing;
