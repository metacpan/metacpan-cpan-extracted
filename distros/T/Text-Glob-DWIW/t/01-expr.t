#! /usr/bin/perl -wT

use strict; use warnings;
use Test::More tests => 145;                  BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};
use Text::Glob::DWIW qw':all';
my $p; my @v; my $v; my $sec='re';

# with RE it exists different ways to express, these is the actual kind,
# this test are to recognise (unintended) changes.
is tg_re($p='\*'),        qr/^(?:\*)\z/s,     "$sec: $p";
is tg_re($p='\?'),        qr/^(?:\?)\z/s,     "$sec: $p";
is tg_re($p='*'),         qr/^(?:.*?)\z/s,    "$sec: $p";
is tg_re($p='?'),         qr/^(?:.)\z/s,      "$sec: $p";
is tg_re($p='a*c'),       qr/^(?:a.*?c)\z/s,  "$sec: $p";
is tg_re($p='a**c'),      qr/^(?:a.*?c)\z/s,  "$sec: $p";
is tg_re($p='a***c'),     qr/^(?:a.*?c)\z/s,  "$sec: $p";
is tg_re($p='a\*c'),      qr/^(?:a\*c)\z/s,   "$sec: $p";
is tg_re($p='a\\*c'),     qr/^(?:a\*c)\z/s,   "$sec: $p";
is tg_re($p='a\\\\*c'),   qr/^(?:a\\.*?c)\z/s,"$sec: $p";
is tg_re($p='a*c', {unchar=>'/'}),qr{^(?:a[^/]*?c)\z}s,"$sec: $p (unchar)";
is tg_re($p='a***c',{unchar=>'/'}),qr{^(?:a.*?c)\z}s,   "$sec: $p (unchar **)";
is tg_re($p='a**c',{unchar=>'/',twin=>'*'}),qr{^(?:a[^/]*?[^/]*?c)\z}s,"$sec: $p (unchar **-off)";
is tg_re($p='a***c',{unchar=>'/',twin=>'*'}),qr{^(?:a[^/]*?[^/]*?[^/]*?c)\z}s,"$sec: $p (unchar ***-off)";
is tg_re($p='a**c',{unchar=>'/',twin=>0}),qr{^(?:a[^/]*?c)\z}s,"$sec: $p (unchar **-off)";
is tg_re($p='a***c',{unchar=>'/',twin=>0}),qr{^(?:a[^/]*?c)\z}s,"$sec: $p (unchar ***-off)";
# 0...normal off, single *..replacment off (undocumented)
# todo: also **
is tg_re($p='a\bc'),      qr/^(?:a\\bc)\z/s,  "$sec: $p";
is tg_re($p='a\\bc'),     qr/^(?:a\\bc)\z/s,  "$sec: $p";
is tg_re($p='a\\b\\c'),   qr/^(?:a\\b\\c)\z/s,"$sec: $p";
is tg_re($p='a\\bc\\'),   qr/^(?:a\\bc\\)\z/s,"$sec: $p";
is tg_re($p='{abc,wert}'),qr/^(?:abc|wert)\z/s,"$sec: $p";
is tg_re($p='{abc,wert}',{case=>0}),qr/^(?i:abc|wert)\z/s,"$sec: $p (case=0)";
is tg_re($p='{abc,wert}',{case=>2}),qr/^(?:[aA][bB][cC]|[wW][eE][rR][tT])\z/s,"$sec: $p (case=2)";
is tg_re($p='{abc,wert}',{anchored=>0}),qr/(?:abc|wert)/s,"$sec: $p (a=0)";
is tg_re($p='{abc,wert}',{anchored=>undef}),qr/(?:abc|wert)/s,"$sec: $p (a=0)";
is tg_re($p='{abc,wert}',{anchored=>''}),qr/(?:abc|wert)/s,"$sec: $p (a=0)";
is tg_re($p='{abc,wert}',{anchored=>'^'}),qr/^(?:abc|wert)/s,"$sec: $p (a=0)";
is tg_re($p='{abc,wert}',{anchored=>'$'}),qr/(?:abc|wert)$/s,"$sec: $p (a=0)";
is tg_re($p='{abc,wert}',{anchored=>'z'}),qr/(?:abc|wert)\z/s,"$sec: $p (a=0)";
is tg_re($p='{abc,wert}',{anchored=>'^$'}),qr/^(?:abc|wert)$/s,"$sec: $p (a=0)";
is tg_re($p='{abc,wert}',{anchored=>'az'}),qr/^(?:abc|wert)\z/s,"$sec: $p (a=0)";
is tg_re($p='{abc,wert}',{anchored=>'^,$'}),qr/^(?:abc|wert)$/s,"$sec: $p (a=0)";
is tg_re($p='{abc,wert}',{anchored=>'a,z'}),qr/^(?:abc|wert)\z/s,"$sec: $p (a=0)";
is tg_re($p='{abc,wert}',{anchored=>'else'}),qr/^(?:abc|wert)\z/s,"$sec: $p (a=0)";
is tg_re($p='[a-f]'),qr/^(?:a|b|c|d|e|f)\z/s,"$sec: $p";
is tg_re($p='[a-f]',{range=>0}),qr/^(?:a|\-|f)\z/s,"$sec: $p";
# ^- was: '(?^s:^(?:a|(?:\-)|f)$)'; :vs.: qr/^(?:a|-|f)\z/s, but fine
ok '-'=~tg_re($p='[a-f]',{range=>0}),"$sec: $p";
is tg_re($p='{a-f}'),qr/^(?:a|b|c|d|e|f)\z/s,"$sec: $p";
is tg_re($p='{a-f}',{range=>0}),qr/^(?:a\-f)\z/s,"$sec: $p (r=0)"; #qr/^(?:a-f)\z/s also fine
ok 'a-f'=~tg_re($p='{a-f}',{range=>0}),"$sec: $p (r=0)";
is tg_re($p='{ou,????????.??}*',{rewrite=>0}),qr/^(?:ou.*?|........\....*?)\z/s,"$sec: $p";
is tg_re($p='{ou,????????.??}*',{rewrite=>1}),qr/^(?:(?:ou|........\...).*?)\z/s,"$sec: $p";
is tg_re($p='foo |1*3| bar'),qr/^(?:foo\ \|1.*?3\|\ bar)\z/s,"$sec: $p";

$sec='no stars';
is tg_re($p='a*c',{star=>0}), qr/^(?:a\*c)\z/s,   "$sec: $p (star=0)";
is tg_re($p='a**c',{star=>0}),qr/^(?:a\*\*c)\z/s,"$sec: $p (star=0)";
is tg_re($p='a**c',{star=>0,twin=>0}),qr/^(?:a\*\*c)\z/s,"$sec: $p (star=0,twin=0)";
is tg_re($p='a?c',{star=>0}), qr/^(?:a\?c)\z/s,   "$sec: $p (star=0)";
is tg_re($p='a?c',{star=>0,anchored=>0}), qr/(?:a\?c)/s,   "$sec: $p (star=0,a=0)";
is tg_re($p='a?c',{star=>0,anchored=>0,case=>0}), qr/(?i:a\?c)/s,  "$sec: $p (star=0,a=0,case=0)";

$sec='capture';
is tg_re($p='a*c',{capture=>1}),        qr/^(?|a.*?c)\z/s,      "$sec: $p";
is tg_re($p='a{*}c',{capture=>1}),        qr/^(?|a(.*?)c)\z/s,      "$sec: $p";
is tg_re($p='fo{ob}ar',{capture=>1}),     qr/^(?|fo(ob)ar)\z/s,      "$sec: $p";
is tg_re($p='{fo{o,b}ar}',{capture=>1,rewrite=>0}),  qr/^(?|(fo(o)ar)|(fo(b)ar))\z/s,"$sec: $p";
is tg_re($p='{fo{o,b}ar}',{capture=>1,rewrite=>1}),  qr/^(?|(fo(o|b)ar))\z/s,"$sec: $p";
is tg_re($p='{fo{o},{b}ar}',{capture=>1,rewrite=>0}),qr/^(?|(fo(o))|((b)ar))\z/s,"$sec: $p";
is tg_re($p='{fo{o},{b}ar}',{capture=>1,rewrite=>1}),qr/^(?|(fo(o)|(b)ar))\z/s,  "$sec: $p";
is tg_re($p='a*c',{capture=>1,case=>0}),qr/^(?|(?i)a.*?c)\z/s,  "$sec: $p";# qr/^((?i)a.*?c)\z/s
is tg_re($p='a*c',{capture=>1,case=>2}),qr/^(?|[aA].*?[cC])\z/s,  "$sec: $p";
is tg_re($p='a{*}c',{capture=>1,case=>0}),qr/^(?|(?i)a(.*?)c)\z/s,  "$sec: $p";
is tg_re($p='a{*}c',{capture=>1,case=>2}),qr/^(?|[aA](.*?)[cC])\z/s,  "$sec: $p";
is tg_re($p='{a-f}',{capture=>1,rewrite=>0}),qr/^(?|(a)|(b)|(c)|(d)|(e)|(f))\z/s,"$sec: $p";
is tg_re($p='{a-f}',{capture=>1,rewrite=>1}),qr/^(?|(a|b|c|d|e|f))\z/s,"$sec: $p";
#i: ^- aka:qr/^(a|b|c|d|e|f)\z/s    |||   v- qr/(a|b|c|d|e|f)/s
is tg_re($p='{a-f}',{capture=>1,anchored=>0,rewrite=>0}),qr/(?|(a)|(b)|(c)|(d)|(e)|(f))/s,"$sec: $p";
is tg_re($p='{a-f}',{capture=>1,anchored=>0,rewrite=>1}),qr/(?|(a|b|c|d|e|f))/s,"$sec: $p";
is tg_re($p='{a-f}',{capture=>1,anchored=>0,case=>2,rewrite=>0}),
         qr/(?|([aA])|([bB])|([cC])|([dD])|([eE])|([fF]))/s,"$sec: $p";
is tg_re($p='{a-f}',{capture=>1,anchored=>0,case=>2,rewrite=>1}),
         qr/(?|([aA]|[bB]|[cC]|[dD]|[eE]|[fF]))/s,"$sec: $p";
is tg_re($p='a*c', {capture=>1,unchar=>'/'}),qr{^(?|a[^/]*?c)\z}s,"$sec: $p (unchar)";
is tg_re($p='a{*}c', {capture=>1,unchar=>'/'}),qr{^(?|a([^/]*?)c)\z}s,"$sec: $p (unchar)";
is tg_re($p='a***c',{capture=>1,unchar=>'/'}),qr{^(?|a.*?c)\z}s,   "$sec: $p (unchar ***)";
is tg_re($p='a{***}c',{capture=>1,unchar=>'/'}),qr{^(?|a(.*?)c)\z}s,   "$sec: $p (unchar ***)";
#like ''.tg_re($p='a{**}c',{capture=>1,unchar=>'/'}),qr{^\Q(?^s:^(?|foo((?:},   "$sec: $p (unchar **)";
# ^^+^- todo: **
is tg_re($p='R{A-C,}W',{capture=>1,rewrite=>0}),qr/^(?|R(A)W|R(B)W|R(C)W|R()W)\z/s,"$sec: $p";
is tg_re($p='R{A-C,}W',{capture=>1,rewrite=>1}),qr/^(?|R(A|B|C|)W)\z/s,"$sec: $p";
is tg_re($p='R{[A-C],}W',{capture=>1,rewrite=>0}),qr/^(?|R((A))W|R((B))W|R((C))W|R()W)\z/s,"$sec: $p";
is tg_re($p='R{[A-C],}W',{capture=>1,rewrite=>1}),qr/^(?|R((A|B|C)|)W)\z/s,"$sec: $p";
is tg_re($p='R.{[A-C].,}W.',{capture=>1,rewrite=>0}),
   qr/^(?|R\.((A)\.)W\.|R\.((B)\.)W\.|R\.((C)\.)W\.|R\.()W\.)\z/s,"$sec: $p";
is tg_re($p='R.{[A-C].,}W.',{capture=>1,rewrite=>1}),
   qr/^(?|R\.((A|B|C)\.|)W\.)\z/s,"$sec: $p";
is tg_re($p='_{a,b}_{1,2,}_',{capture=>1,rewrite=>0}),
   qr/^(?|_(a)_(1)_|_(a)_(2)_|_(a)_()_|_(b)_(1)_|_(b)_(2)_|_(b)_()_)\z/s,"$sec: $p";
is tg_re($p='_{a,b}_{1,2,}_',{capture=>1,rewrite=>1}), qr/^(?|_(a|b)_(1|2|)_)\z/s,"$sec: $p";
for my $rwt (0,1)
{ my $re1=tg_re $p='A {{v*,} }{*} story',{capture=>1,rewrite=>$rwt};
  is $re1,(!$rwt) ? qr'^(?|A\ ((v.*?)\ )(.*?)\ story|A\ (()\ )(.*?)\ story)\z's
                  : qr'^(?|A\ ((v.*?|)\ )(.*?)\ story)\z's,"$sec: $p (re)";
  is_deeply ['A very short story'=~/$re1/],['very ','very','short'],"$sec: $p (1)";
  is_deeply ['A  short story'=~/$re1/],[' ','','short'],"$sec: $p (2)";
  is_deeply ['A short story'=~/$re1/],[],"$sec: $p (3)";
  my $re2=tg_re $p='A {v* ,}{*} story',{capture=>1,rewrite=>$rwt};
  is $re2,(!$rwt) ? qr'^(?|A\ (v.*?\ )(.*?)\ story|A\ ()(.*?)\ story)\z's
                  : qr'^(?|A\ (v.*?\ |)(.*?)\ story)\z's,"$sec: $p (re)";
  is_deeply ['A very short story'=~/$re2/],['very ','short'],"$sec: $p (1)";
  is_deeply ['A  short story'=~/$re2/],['',' short'],"$sec: $p (2)";
  is_deeply ['A short story'=~/$re2/],['','short'],"$sec: $p (3)";
  my $re3=tg_re $p='A {{v*} ,}{*} story',{capture=>1,rewrite=>$rwt};
  is $re3,(!$rwt) ? qr'^(?|A\ ((v.*?)\ )(.*?)\ story|A\ ()(.*?)\ story)\z's
                  : qr'^(?|A\ ((v.*?)\ |)(.*?)\ story)\z's,"$sec: $p (re)";
  is_deeply ['A very short story'=~/$re3/],['very ','very','short'],"$sec: $p (1)";
  is_deeply [grep defined,('A  short story'=~/$re3/)],['',' short'],"$sec: $p (2)";#,undef
  is_deeply [grep defined,('A short story'=~/$re3/)],['','short'],"$sec: $p (3)";#,undef
  my $re4=tg_re $p='A {{v*} ,{}}{*} story',{capture=>1,rewrite=>$rwt};
  is $re4,(!$rwt) ? qr'^(?|A\ ((v.*?)\ )(.*?)\ story|A\ (())(.*?)\ story)\z's
                  : qr'^(?|A\ ((v.*?)\ |())(.*?)\ story)\z's,"$sec: $p (re)";
  is_deeply [grep defined,('A very short story'=~/$re4/)],['very ','very','short'],"$sec: $p (1)";
  is_deeply [grep defined,('A  short story'=~/$re4/)],['','',' short'],"$sec: $p (2)";
  is_deeply [grep defined,('A short story'=~/$re4/)],['','','short'],"$sec: $p (3)";
}

$sec='greediness';
is tg_match($p='foo*bar*hello*','foobar hello bar',{greedy=>0}),1,"$sec: $p";
is tg_match($p='foo*bar*hello*','foobar hello bar',{greedy=>1}),1,"$sec: $p";
is tg_match($p='foo*bar*hello*','foobar hello bar',{greedy=>2}),'',"$sec: $p";
is_deeply ['foobar hello bar'=~tg_re '{foo*bar}*',{greedy=>0,capture=>1}],['foobar'],"$sec: re0";
is_deeply [($v='foobar hello bar')=~tg_re '{foo*bar}*',{greedy=>1,capture=>1}],[$v],"$sec: re1";
is_deeply [($v='foobar hello bar')=~tg_re '{foo*bar}*',{greedy=>2,capture=>1}],[],"$sec: re2";
is_deeply [($v='foobar hello/bar')=~tg_re '{foo*/bar}*',{greedy=>2,capture=>1,unchar=>'/'}],
          [$v],"$sec: re2.2";
is tg_match($p='sim*.bim', 'simsala.bim',{greedy=>2,unchar=>'.'}),1,"$sec: $p";
is tg_match($p='sim***.bim','simsala.bim',{greedy=>2,unchar=>'.'}),!1,"$sec: $p";

$sec='rewrite simple';
is_deeply [tg_expand $p='[,]',{rewrite=>1}],['{\\,}'],"$sec: $p";
is_deeply [tg_expand $p='[\,]',{rewrite=>1}],['{\\,}'],"$sec: $p";
is_deeply [tg_expand $p='[\\,]',{rewrite=>1}],['{\\,}'],"$sec: $p";
is_deeply [tg_expand $p='[\\,]',{rewrite=>1,last=>0}],['{\\,}'],"$sec: $p";
is_deeply [tg_expand $p='[\\\\,]',{rewrite=>1,last=>0}],['{\\\\,\\,}'],"$sec: $p";
is_deeply [tg_expand $p='[,]#1',{rewrite=>1}],['{\\,}'],"$sec: $p";
is_deeply [tg_expand $p='[,]#2',{rewrite=>1}],['{{\\,}{\\,}}'],"$sec: $p";
is_deeply [tg_expand $p='[,]##1',{rewrite=>1}],['{\\,}'],"$sec: $p";
is_deeply [tg_expand $p='[,]##2',{rewrite=>1}],['{\\,\\,}'],"$sec: $p";

$sec='rewrite';
is_deeply [tg_expand $p='1[,_]#0-1\200',{rewrite=>1}],['1{,{\\,,_}}200'],"$sec: $p";
is_deeply [tg_expand $p='{abc,def}{([_]#0-2)}##2[1-3]##2',{rewrite=>1}],
          ['{abc,def}{()(),(_)(_),(__)(__)}{11,22,33}'], "$sec: $p";
is_deeply [tg_expand $p='{abc,def}{([_]#0-2)}##2[[:digit2-4:]]##2',{rewrite=>1}],
          ['{abc,def}{()(),(_)(_),(__)(__)}{11,22,33}'], "$sec: $p";
is_deeply [tg_expand $p='foo{[ab][01]}#2{[ab][[:digit1-2:]]}##2ba[rz]',{rewrite=>1}],
          ['foo{{{a,b}{0,1}}{{a,b}{0,1}}}{a0a0,a1a1,b0b0,b1b1}ba{r,z}'], "$sec: $p";
is_deeply [tg_expand $p='{\,,{a-c,{e-h,\\\\}}#0-1,[1-3]##2,!a,*}[a-c]\{,},z',
           {rewrite=>1,last=>0,star=>0}],
          ['{\\,,,b,c,e,f,g,h,\\\\,11,22,33,*}{a,b,c}\\{,\\},z'], "$sec: $p";
# tree and rewrite no much sense, but chunk and rewrite, is the actual result fine?
# {{{a,b}}}, a{a,b}} , {a{{a,b}}}, {{a{a,b},a}}, a{b}c, {a{b}c}, ...{a{{{a}},b}}a}, {a{{a{b}c,b}}a}

{ $sec='horoscope';
  @v=tg_expand '[[:zodiac:]]foo bar baz'; my $horoscopes=join "\n",@v,'';
  is int(@v),12,"$sec: precond";
  #is_deeply [$horoscopes=~/${ \tg_re '[[:zodiac:]]*',{anchored=>0} }/g],
  #          [map "$_\n",@v],"$sec: c1";
  #is_deeply [$horoscopes=~/${ \tg_re '[[:zodiac:]]*',
  #                  {anchored=>0,greedy=>1,unchar=>join '',tg_expand '[[:zodiac:]]'} }/g],
  #          [map "$_\n",@v],"$sec: c2"; # ok
  is_deeply [$horoscopes=~/${ \tg_re '[[:zodiac:]]*',
                    {anchored=>0,greedy=>1,unchar=>'[[:zodiac:]]'} }/g],
            [map "$_\n",@v],"$sec: c2"; # ok
  is_deeply [$horoscopes=~/${ \tg_re '[[:zodiac:]]',{anchored=>0} } [[:punct:]\w\s]*/xg],
            [map "$_\n",@v],"$sec: c3"; # ok
  is_deeply [$horoscopes=~/${ \tg_re '[[:zodiac:]]',{anchored=>0} } [\pP\w\s]*/xg],
            [map "$_\n",@v],"$sec: c3"; # ??
  is_deeply [($horoscopes=~tg_re '{[[:zodiac:]]*}#12',{capture=>1})[map 2*$_+1,0..11]],
            [map "$_\n",@v],"$sec: c4";
  is_deeply [grep /../,splice @{[$horoscopes=~tg_re '{[[:zodiac:]]*}#12',{capture=>1}]},1],
            [map "$_\n",@v],"$sec: c4a";
  is_deeply [grep !/^.$|\Q$horoscopes/,$horoscopes=~tg_re '{[[:zodiac:]]*}#12',{capture=>1}],
            [map "$_\n",@v],"$sec: c4b";
  is_deeply [grep /^.[[:punct:]\w\s]+$/,$horoscopes=~tg_re '{[[:zodiac:]]*}#12',{capture=>1}],
            [map "$_\n",@v],"$sec: c4c";
  is_deeply [split /(?=${\tg_re '[[:zodiac:]]',{anchored=>0} })/,$horoscopes],
            [map "$_\n",@v],"$sec: c5"; # ok
}

$sec='subst fake';
{ my $ex_re=tg_re $p='{**}/{*}.tar.gz',{capture=>1,unchar=>'/'};
  my $inp='path/to/the/file.tar.gz';
  my ($r)=tg_expand(join'',map "{$_}",$inp=~$ex_re)->format('%1/new/%2.tgz'); # XXX <+v
  is $r,'path/to/the/new/file.tgz',"$sec: $p";
  ($r)=tg_expand()->_new_expand({},[[$1],[$2]])->format('%1/away/%2.tgz') if $inp=~$ex_re;
  is $r,'path/to/the/away/file.tgz',"$sec: $p";
}

had_no_warnings();