#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_render(<<'END;',
global[<TMPL_VAR NAME=name>]
<TMPL_INCLUDE "x.tx">
global[<TMPL_VAR NAME=name>]
END;
               params => {
                   name => 'global',
               },
               expected =><<'END;');
global[global]
include[global]
global[global]
END;

compare_render(<<'END;',
global[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop><TMPL_INCLUDE "x.tx">
</TMPL_LOOP>global[<TMPL_VAR NAME=name>]
END;
               params => {
                   name => 'global',
                   loop => [
                       { name => '0', },
                       { name => '', },
                       { name => ' ', },
                       { name => 'x', },
                   ],
               },
               expected =><<'END;');
global[global]
include[0]
include[]
include[ ]
include[x]
global[global]
END;



done_testing;
