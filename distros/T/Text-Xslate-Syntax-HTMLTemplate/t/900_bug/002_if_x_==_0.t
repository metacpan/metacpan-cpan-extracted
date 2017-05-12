#!perl -w

use strict;
use warnings;

use Test::More;

use t::lib::Util;

compare_render(q{<TMPL_UNLESS EXPR=x>x is false</TMPL_UNLESS>}, expected => q{x is false});
compare_render(q{<TMPL_UNLESS EXPR=x>x is false</TMPL_UNLESS>}, expected => q{}, params => { x => 1 });
compare_render(q{<TMPL_IF EXPR='x == 0'>x==0</TMPL_IF>},        expected => q{x==0});
compare_render(q{<TMPL_IF EXPR='x == 0'>x==0</TMPL_IF>},        expected => q{}, params => { x => 1 });
compare_render(q{<TMPL_IF EXPR='x == ""'>x == ""</TMPL_IF>},    expected => q{x == ""});
compare_render(q{<TMPL_IF EXPR='x == ""'>x == ""</TMPL_IF>},    expected => q{}, params => { x => 1 });
compare_render(q{<TMPL_IF EXPR='x() == 0'>x() == 0</TMPL_IF>},  expected => q{x() == 0},
               function => { x => sub { }, });
compare_render(q{<TMPL_IF EXPR='x() == 0'>x() == 0</TMPL_IF>},  expected => q{x() == 0},
               function => { x => sub { undef }, });
compare_render(q{<TMPL_IF EXPR='x() == 0'>x() == 0</TMPL_IF>},  expected => q{x() == 0},
               function => { x => sub { () }, });
compare_render(q{<TMPL_IF EXPR='x() == 0'>x() == 0</TMPL_IF>},  expected => q{},
               function => { x => sub { 1 }, });
done_testing;
