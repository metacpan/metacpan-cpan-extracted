#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_render(<<'END;',
<TMPL_IF NAME=loop>loop</TMPL_IF>
END;
               params => {
                   loop => [],
               },
               expected =><<'END;',

END;
               use_has_value => 1,
           );

done_testing;
