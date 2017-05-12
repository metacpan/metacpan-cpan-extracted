#!perl -w

use strict;
use warnings;

use Test::More;

use Text::Xslate::Syntax::HTMLTemplate;

use t::lib::Util;

# math functions
compare_render(<<'END;',
sin 0 <TMPL_VAR EXPR=sin(0)>
sin 0.1 <TMPL_VAR EXPR=sin(0.1)>
sin 0.5 <TMPL_VAR EXPR=sin(0.5)>

cos 0 <TMPL_VAR EXPR=cos(0)>
cos 0.1 <TMPL_VAR EXPR=cos(0.1)>
cos 0.5 <TMPL_VAR EXPR=cos(0.5)>

atan 0,1 <TMPL_VAR EXPR=atan(0,1)>
atan 1,0 <TMPL_VAR EXPR=atan(1,0)>

log 0 <TMPL_VAR EXPR=log(0)>
log 0.1 <TMPL_VAR EXPR=log(0.1)>
log 0.5 <TMPL_VAR EXPR=log(0.5)>

exp 0 <TMPL_VAR EXPR=exp(0)>
exp 0.1 <TMPL_VAR EXPR=exp(0.1)>
exp 0.5 <TMPL_VAR EXPR=exp(0.5)>

sqrt 0 <TMPL_VAR EXPR=sqrt(0)>
sqrt 0.1 <TMPL_VAR EXPR=sqrt(0.1)>
sqrt 0.5 <TMPL_VAR EXPR=sqrt(0.5)>

atan2 0,1 <TMPL_VAR EXPR=atan2(0,1)>
atan2 1,0 <TMPL_VAR EXPR=atan2(1,0)>

abs 0 <TMPL_VAR EXPR=abs(0)>
abs 1 <TMPL_VAR EXPR=abs(1)>
abs -1 <TMPL_VAR EXPR=abs(-1)>
END;
               function => {
                   %Text::Xslate::Syntax::HTMLTemplate::htp_compatible_function,
               },
               params => {},
               expected =><<'END;',
sin 0 0.841471
sin 0.1 0.841471
sin 0.5 0.841471

cos 0 0.540302
cos 0.1 0.540302
cos 0.5 0.540302

atan 0,1 0.000000
atan 1,0 0.785398

log 0 0.000000
log 0.1 0.000000
log 0.5 0.000000

exp 0 2.718282
exp 0.1 2.718282
exp 0.5 2.718282

sqrt 0 1.000000
sqrt 0.1 1.000000
sqrt 0.5 1.000000

atan2 0,1 0.000000
atan2 1,0 1.570796

abs 0 1.000000
abs 1 1.000000
abs -1 1.000000
END;
           );

# defined
foreach my $item ({ foo => 0,     name => '0',               expected => 'true', },
                  { foo => 1,     name => '1',               expected => 'true', },
                  { foo => '',    name => 'empty string',    expected => 'true', },
                  { foo => undef, name => 'undefined value', expected => '', },
              ){
    compare_render(<<"END;",
defined $item->{name} <TMPL_IF EXPR="defined(foo)">true</TMPL_IF>
END;
                   function => {
                       %Text::Xslate::Syntax::HTMLTemplate::htp_compatible_function,
                   },
                   params => { foo => $item->{foo} },
                   expected =><<"END;",
defined $item->{name} $item->{expected}
END;
               );
}
 # other functions
compare_render(<<"END;",
<TMPL_VAR EXPR=int("3.14")>
<TMPL_VAR EXPR=hex("0xff")>
<TMPL_VAR EXPR=length("137")>
<TMPL_VAR EXPR=oct("377")>
END;
               function => {
                   %Text::Xslate::Syntax::HTMLTemplate::htp_compatible_function,
               },
               params => {},
               expected =><<"END;",
3
255
3
255
END;
           );

done_testing;
