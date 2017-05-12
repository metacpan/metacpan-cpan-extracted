#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_render(<<'END;',
<TMPL_LOOP NAME=loop>
================================================================
index:<TMPL_VAR NAME="index">
<TMPL_VAR NAME="__counter__">
<TMPL_IF NAME="__first__">first</TMPL_IF>
<TMPL_IF NAME="__inner__">inner</TMPL_IF>
<TMPL_IF NAME="__odd__">odd<TMPL_ELSE>even</TMPL_IF>
<TMPL_IF NAME="__last__">last</TMPL_IF></TMPL_LOOP>
END;
               params => {
                   loop => [
                       { index => 1 },
                       { index => 2 },
                       { index => 3 },
                       { index => 4 },
                       { index => 5 },
                       { index => 6 },
                   ],
               },
               expected =><<'END;',

================================================================
index:1
1
first

odd

================================================================
index:2
2

inner
even

================================================================
index:3
3

inner
odd

================================================================
index:4
4

inner
even

================================================================
index:5
5

inner
odd

================================================================
index:6
6


even
last
END;
               use_loop_context_vars => 1,
           );

compare_render(<<'END;',
<TMPL_LOOP NAME=loop>
================================================================
index:<TMPL_VAR NAME="index">
<TMPL_UNLESS NAME="__odd__">even</TMPL_UNLESS></TMPL_LOOP>
END;
               params => {
                   loop => [
                       { index => 1 },
                       { index => 2 },
                       { index => 3 },
                       { index => 4 },
                       { index => 5 },
                       { index => 6 },
                   ],
               },
               expected =><<'END;',

================================================================
index:1

================================================================
index:2
even
================================================================
index:3

================================================================
index:4
even
================================================================
index:5

================================================================
index:6
even
END;
               use_loop_context_vars => 1,
           );

compare_render(<<'END;',
<TMPL_LOOP NAME=loop>
================================================================
index:<TMPL_VAR NAME="index">
<TMPL_UNLESS NAME="__odd__">even</TMPL_UNLESS></TMPL_LOOP>
END;
               params => {
                   loop => [
                       { index => 1 },
                       { index => 2 },
                       { index => 3 },
                       { index => 4 },
                       { index => 5 },
                       { index => 6 },
                   ],
               },
               expected =><<'END;',

================================================================
index:1
even
================================================================
index:2
even
================================================================
index:3
even
================================================================
index:4
even
================================================================
index:5
even
================================================================
index:6
even
END;
               use_loop_context_vars => 0,
           );

done_testing;
