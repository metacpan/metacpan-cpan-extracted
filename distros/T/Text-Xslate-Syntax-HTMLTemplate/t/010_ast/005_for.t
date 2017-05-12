#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_ast(<<'END;', <<'END;', unwatch_filed => [qw/value/]);
[% for $loop->$__dummy_item__1 { %][% $__dummy_item__1.name %][% } %]
END;
<TMPL_LOOP NAME=loop><TMPL_VAR EXPR=name></TMPL_LOOP>
END;

compare_ast(<<'END;', <<'END;', unwatch_filed => [qw/value/]);
[% for $loop1->$__dummy_item__1 { %][% for $__dummy_item__1.loop2->$__dummy_item__2 { %][% $__dummy_item__2.name %][% } %][% } %]
END;
<TMPL_LOOP NAME=loop1><TMPL_LOOP NAME=loop2><TMPL_VAR EXPR=name></TMPL_LOOP></TMPL_LOOP>
END;

compare_ast(<<'END;', <<'END;', unwatch_filed => [qw/value/]);
[% for $loop->$__dummy_item__1 { %][% $__dummy_item__1.name %][% } %]
END;
<TMPL_LOOP NAME=loop><TMPL_VAR NAME=name></TMPL_LOOP>
END;

compare_ast(<<'END;', <<'END;', unwatch_filed => [qw/value/]);
[% for $loop1->$__dummy_item__1 { %][% for $__dummy_item__1.loop2->$__dummy_item__2 { %][% $__dummy_item__2.name %][% } %][% } %]
END;
<TMPL_LOOP NAME=loop1><TMPL_LOOP NAME=loop2><TMPL_VAR NAME=name></TMPL_LOOP></TMPL_LOOP>
END;

done_testing;
