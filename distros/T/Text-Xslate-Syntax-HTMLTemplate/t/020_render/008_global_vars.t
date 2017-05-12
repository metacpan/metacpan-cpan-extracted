#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_render(<<'END;',
[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop>[<TMPL_VAR NAME=name>]</TMPL_LOOP>
[<TMPL_VAR NAME=name>]
END;
               params => {
                   name => 'global name',
                   loop => [
                       { name => 'local name', },
                       { name => 0, },
                       { name => '0', },
                       { name => '', },
                       { name => ' ', },
                       { name => undef, },
                       {},
                   ],
               },
               expected =><<'END;',
[global name]
[local name][0][0][][ ][][]
[global name]
END;
               use_global_vars => 0,
           );

compare_render(<<'END;',
[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop>[<TMPL_VAR NAME=name>]</TMPL_LOOP>
[<TMPL_VAR NAME=name>]
END;
               params => {
                   name => 'global name',
                   loop => [
                       { name => 'local name', },
                       { name => 0, },
                       { name => '0', },
                       { name => '', },
                       { name => ' ', },
                       { name => undef, },
                       {},
                   ],
               },
               expected =><<'END;',
[global name]
[local name][0][0][][ ][][global name]
[global name]
END;
               use_global_vars => 1,
           );

compare_render(<<'END;',
global[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop1>loop1[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop2>loop2[<TMPL_VAR NAME=name>]</TMPL_LOOP>
loop1[<TMPL_VAR NAME=name>]
</TMPL_LOOP>
global[<TMPL_VAR NAME=name>]
END;
               params => {
                   name => 'global name',
                   loop1 => [
                       {
                           name => 'loop1 0',
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => 'loop1 1',
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => 0,
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => '0',
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => '',
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => ' ',
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => undef,
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                   ],
               },
               expected => <<'END;',
global[global name]
loop1[loop1 0]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[]
loop1[loop1 0]
loop1[loop1 1]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[]
loop1[loop1 1]
loop1[0]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[]
loop1[0]
loop1[0]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[]
loop1[0]
loop1[]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[]
loop1[]
loop1[ ]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[]
loop1[ ]
loop1[]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[]
loop1[]
loop1[]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[]
loop1[]

global[global name]
END;
               use_global_vars => 0,
           );

compare_render(<<'END;',
global[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop1>loop1[<TMPL_VAR NAME=name>]
<TMPL_LOOP NAME=loop2>loop2[<TMPL_VAR NAME=name>]</TMPL_LOOP>
loop1[<TMPL_VAR NAME=name>]
</TMPL_LOOP>
global[<TMPL_VAR NAME=name>]
END;
               params => {
                   name => 'global name',
                   loop1 => [
                       {
                           name => 'loop1 0',
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => 'loop1 1',
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => 0,
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => '0',
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => '',
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => ' ',
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           name => undef,
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                       {
                           loop2 => [
                               { name => 'loop2 0', },
                               { name => 0, },
                               { name => '0', },
                               { name => '', },
                               { name => ' ', },
                               { name => undef, },
                               { },
                           ],
                       },
                   ],
               },
               expected => <<'END;',
global[global name]
loop1[loop1 0]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[loop1 0]
loop1[loop1 0]
loop1[loop1 1]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[loop1 1]
loop1[loop1 1]
loop1[0]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[0]
loop1[0]
loop1[0]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[0]
loop1[0]
loop1[]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[]
loop1[]
loop1[ ]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[ ]
loop1[ ]
loop1[]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[]
loop1[]
loop1[global name]
loop2[loop2 0]loop2[0]loop2[0]loop2[]loop2[ ]loop2[]loop2[global name]
loop1[global name]

global[global name]
END;
               use_global_vars => 1,
           );

done_testing;
