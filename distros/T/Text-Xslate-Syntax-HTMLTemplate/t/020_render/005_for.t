#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_render(<<'END;',
1[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop>[<TMPL_VAR NAME=name>]</TMPL_LOOP>
[<TMPL_VAR NAME=name>]
END;
               params => {
                   name => 'global name',
                   loop => [
                       { name => 'local name', },
                       { name => 0, },
                       { name => '', },
                       { name => undef, },
                       {},
                   ],
               },
               expected =><<'END;',
1[global name]
[local name][0][][][]
[global name]
END;
           );

compare_render(<<'END;',
2[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop>[<TMPL_VAR NAME=name>]</TMPL_LOOP>
[<TMPL_VAR NAME=name>]
END;
               params => {
                   name => 'global name',
                   loop => [
                       { name => 'loop 1 name', },
                       { name => 'loop 2 name', },
                   ],
               },
               expected =><<'END;',
2[global name]
[loop 1 name][loop 2 name]
[global name]
END;
           );

compare_render(<<'END;',
3global[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop1>loop1[<TMPL_VAR NAME=name>]
  <TMPL_LOOP NAME=loop2>loop2[<TMPL_VAR NAME=name>]
</TMPL_LOOP>loop1[<TMPL_VAR NAME=name>]
</TMPL_LOOP>
global[<TMPL_VAR NAME=name>]
END;
               params => {
                   name => 'global name',
                   loop1 => [
                       {
                           name => '0',
                           loop2 => [
                               { name => '0_0', },
                               { name => '0_1', },
                               { name => '0_2', },
                           ],
                       },
                       {
                           name => '1',
                           loop2 => [
                               { name => '1_0', },
                               { name => '2_1', },
                               { name => '3_2', },
                           ],
                       },
                   ],
               },
               expected => <<'END;',
3global[global name]
loop1[0]
  loop2[0_0]
loop2[0_1]
loop2[0_2]
loop1[0]
loop1[1]
  loop2[1_0]
loop2[2_1]
loop2[3_2]
loop1[1]

global[global name]
END;
           );


compare_render(<<'END;',
4[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop>[<TMPL_VAR EXPR=name>]</TMPL_LOOP>
[<TMPL_VAR NAME=name>]
END;
               params => {
                   name => 'global name',
                   loop => [
                       { name => 'local name', },
                       { name => 0, },
                       { name => '', },
                       { name => undef, },
                       {},
                   ],
               },
               expected =><<'END;',
4[global name]
[local name][0][][][]
[global name]
END;
           );

done_testing;
