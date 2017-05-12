#!perl -w

use strict;
use warnings;

use Test::More;
use Text::Xslate;

use t::lib::Util;

compare_render('<TMPL_VAR EXPR=foo()>', function => { foo => sub { "FOO"; } }, expected => "FOO");
compare_render('<TMPL_VAR EXPR=1>', expected => 1);
compare_render(q{<TMPL_VAR EXPR='"abc"'>}, expected => 'abc');
compare_render('<TMPL_VAR EXPR=1+2*3>', expected => 7);
compare_render('<TMPL_VAR EXPR="foo * 2">', params => { foo => 5}, expected => 10);
compare_render('<TMPL_VAR EXPR="x(foo)">', params => { foo => 'htp'}, function => { x => sub { my $s = shift ; "hello $s !" } }, expected => "hello htp !");
compare_render('<TMPL_VAR EXPR="x(1,y(2,3),4,5,y(6,7),z())">',
               function => {
                   x => sub { my $sum = 0;$sum += $_ for @_;$sum },
                   y => sub { $_[0] * $_[1]; },
                   z => sub { 0; },
               },
               expected => 58,
           );

my $tx = Text::Xslate->new(syntax => 'HTMLTemplate',
                           type => 'html', # enable auto escape
                           compiler => 'Text::Xslate::Compiler::HTMLTemplate',
                           path => [ 't/template' ],
                           function => {
                               foo => sub { "FOO"; },
                           },
                       );
is($tx->render_string('<TMPL_VAR EXPR=foo()>'), "FOO");
is($tx->render_string('<TMPL_VAR EXPR=bar()>', { bar => sub { "BAR"; } }), "BAR");


done_testing;
