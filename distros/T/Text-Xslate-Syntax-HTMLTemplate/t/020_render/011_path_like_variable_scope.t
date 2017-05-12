#!perl -w

use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{PERL_ONLY} = 1;
    $ENV{XSLATE} = "";
#    $ENV{XSLATE} .= " dump=ast";
#    $ENV{XSLATE} .= " dump=gen";
#    $ENV{XSLATE} .= " dump=asm";
#    $ENV{XSLATE} .= " ix ";
};

use t::lib::Util;



compare_render(<<'END;',
<TMPL_LOOP NAME=loop1>
<TMPL_LOOP NAME=loop2>
normal[<TMPL_VAR EXPR="foo">]
${}[<TMPL_VAR EXPR="${foo}">]
${../}[<TMPL_VAR EXPR="${../foo}">]
${../..}[<TMPL_VAR EXPR="${../../foo}">]
</TMPL_LOOP>
</TMPL_LOOP>
END;
               params => {
                   foo => 'global foo',
                   loop1 => [
                       {
                           foo => 'loop1 foo',
                           loop2 => [ { foo => 'loop2 foo', }]
                       },
                   ],
               },
               use_global_vars => 1,
               use_path_like_variable_scope => 1,
               expected =><<'END;',


normal[loop2 foo]
${}[loop2 foo]
${../}[loop1 foo]
${../..}[global foo]


END;
           );

done_testing;exit;


compare_render(<<'END;',
<TMPL_VAR EXPR="foo">
<TMPL_LOOP NAME=loop>normal[<TMPL_VAR EXPR="foo">]{}[<TMPL_VAR EXPR="{foo}">]${}[<TMPL_VAR EXPR="${foo}">]${/}[<TMPL_VAR EXPR="${/foo}">]
</TMPL_LOOP>
END;
               params => {
                   foo => 'global foo',
                   loop => [
                       { foo => 'local foo', },
                       { },
                   ],
               },
               use_global_vars => 1,
               expected =><<'END;',
global foo
normal[local foo]{}[local foo]${}[local foo]${/}[]
normal[global foo]{}[global foo]${}[global foo]${/}[]

END;
           );


compare_render(<<'END;',
<TMPL_VAR EXPR="foo">
<TMPL_LOOP NAME=loop>normal[<TMPL_VAR EXPR="foo">]{}[<TMPL_VAR EXPR="{foo}">]${}[<TMPL_VAR EXPR="${foo}">]${/}[<TMPL_VAR EXPR="${/foo}">]
</TMPL_LOOP>
END;
               params => {
                   foo => 'global foo',
                   loop => [
                       { foo => 'local foo', },
                       { },
                   ],
               },
               use_global_vars => 1,
               use_path_like_variable_scope => 1,
               expected =><<'END;',
global foo
normal[local foo]{}[local foo]${}[local foo]${/}[global foo]
normal[global foo]{}[global foo]${}[global foo]${/}[global foo]

END;
           );
done_testing;
__END__
