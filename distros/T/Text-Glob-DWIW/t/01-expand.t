#! /usr/bin/perl -wT
# no -T fail under v5.10 (1&2), now ok again?

use strict; use warnings;
use Test::More tests => 185;                  BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};
use Text::Glob::DWIW qw':all';
my $p; my @v; my $sec='more expand';

sub is_slow ($$$) {SKIP:{ skip"slow: $_[2].",1 if$ENV{NO_SLOW_STUFF}; &is_deeply; }}

$sec='format'; # more in tge
is_deeply [tg_expand($p='Robert {[A-C].,} Wilson')->format("'%1' is my middle name")],
          [map "'$_' is my middle name",qw'A. B. C.',''],"$sec: $p";
is_deeply [tg_expand($p)->format("'%1' is my middle initial of '%0'")],
  [map "'$_' is my middle initial of 'Robert $_ Wilson'",qw'A. B. C.',''],"$sec: $p [%1%0]";
is_deeply [tg_expand($p='{f[o]o,b[a]r}')->format("'%1.1' is the middle char\n")],
          [map "'$_' is the middle char\n",qw'o a'],"$sec: $p";
is_deeply [tg_expand($p='{foo,bar}')->format("'%0' is used far too often in examples.")],
          [map "'$_' is used far too often in examples.",qw'foo bar'],"$sec: $p";
is_deeply [tg_expand($p='{{Wallace}{Grommit},{Mutt}{Jeff}}')->format("%1.1 and %1.2")],
          ['Wallace and Grommit','Mutt and Jeff'],"$sec: $p (pairs)";
is_deeply [tg_expand($p='{{Cinderella}{before},{Alice}{behind}}')
           ->format("%1.1 is %1.2 the mirror.")],
          ['Cinderella is before the mirror.','Alice is behind the mirror.'],"$sec: $p (pairs)";
is_deeply [tg_expand($p='{f[o]o,b[a]r}')->format('%1.1',{paired=>1})],
          [qw'foo o bar a'],"$sec: $p";
is_deeply [tg_expand($p='[bcfglptwz]oo')->format('%1',{paired=>1})],
          [map {$_.'oo'=>$_} split//,'bcfglptwz'],"$sec: $p";
is_deeply [tg_expand($p='[1-9]oo')->format('%0%%=%1x')],
          [map $_."oo%=${_}x",1..9],"$sec: $p";
is_deeply [tg_expand($p='{[1-9]oo}')->format('%1%%=%1.1x')],
          [map $_."oo%=${_}x",1..9],"$sec: $p";
is_deeply [tg_expand($p='{file{0-100}}.tar.gz')->format("mv %0 %1.tgz")],
          [map "mv file$_.tar.gz file$_.tgz",0..100],"$sec: $p";

$sec='to looking to deep (into glass)';
is tg_expand($p='[1]oo')->capture(0,2),undef,"$sec: capture 0 2";
TODO: { local $TODO='undef instead of "".';
  is tg_expand($p='[1]oo')->capture(2,0),undef,"$sec: capture 2 0";
}

$sec='expand & *';
is_deeply [tg_expand $p='{a,*}'],   [qw'a a'],  "$sec: $p";
is_deeply [tg_expand $p='{a,?}'],   [qw'a a'],  "$sec: $p";
is_deeply [tg_expand $p='{{a},*}'], [qw'a a'],"$sec: $p";
is_deeply [tg_expand $p='{{a},?}'], [qw'a a'],  "$sec: $p";
is_deeply [tg_expand $p='{[a],*}'], [qw'a a'],"$sec: $p";
is_deeply [tg_expand $p='{[a],?}'], [qw'a a'],  "$sec: $p";
is_deeply [tg_expand $p='{aa,*a}'], [qw'aa aa'],"$sec: $p";
is_deeply [tg_expand $p='{aa,a*}'], [qw'aa aa'],"$sec: $p";
is_deeply [tg_expand $p='{aa,a*a}'],[qw'aa aa'],"$sec: $p";
is_deeply [tg_expand $p='{aa,*a*}'],[qw'aa aa'],"$sec: $p";
is_deeply [tg_expand $p='{{abra},{*}cad{*}}'],['abra', 'abracadabra'],"$sec: $p";
is_deeply [tg_expand $p='{abra,{*}cad{*}}'],['abra', 'abracadabra'],"$sec: $p";
is_deeply [tg_expand $p='{*}'],['*'],"$sec: $p";

$sec='todo';
TODO: { local $TODO='mixing * and braces';  # "*{1}" "*[1]" "[1]*" ....
  is_deeply [tg_expand $p='{a}*'],    [qw'aa'],   "$sec: $p";
  is_deeply [tg_expand $p='{{a}*}'],  [qw'aa'],   "$sec: $p";
  is_deeply [tg_expand $p='{aa,*{a}}'],   [qw'aa aa'],"$sec: $p";
  is_deeply [tg_expand $p='{aa,{a}*}'],   [qw'aa aa'],"$sec: $p";
  is_deeply [tg_expand $p='{aa,{a}*{a}}'],[qw'aa aa'],"$sec: $p";
  is_deeply [tg_expand $p='{aa,*{a}*}'],  [qw'aa aa'],"$sec: $p";
  is_deeply [tg_expand $p='{aa,*[a]}'],   [qw'aa aa'],"$sec: $p";
  is_deeply [tg_expand $p='{aa,[a]*}'],   [qw'aa aa'],"$sec: $p";
  is_deeply [tg_expand $p='{aa,[a]*[a]}'],[qw'aa aa'],"$sec: $p";
  is_deeply [tg_expand $p='{aa,*[a]*}'],  [qw'aa aa'],"$sec: $p";
  is_deeply [tg_expand $p='{a}?'],        [qw'aa'],   "$sec: $p";
  is_deeply [tg_expand $p='{a}{?}'],      [qw'aa'],   "$sec: $p";
  is_deeply [tg_expand $p='{{a}b,?}'],    [qw'ab a'], "$sec: $p";
}

# v- slow stuff
$sec='base counter'; # counting in different bases
is_deeply [map oct,tg_expand $p='0x[0-9a-f][0-9a-f]'],[0..255],"$sec: $p";
is_deeply [map oct,tg_expand $p='0[0-3][0-7][0-7]'],  [0..255],"$sec: $p";
is_slow   [map oct,tg_expand $p='0b[01][01][01][01][01][01][01][01]'],[0..255],"$sec: $p";
is_deeply [tg_expand $p='{0-255}'],[0..255],"$sec: $p (simple)";
is_deeply [map 0+$_,tg_expand $p='{[01][0-9][0-9],2{00-55}}'],[0..255],"$sec: $p (silly)";
is_slow   [map 0+$_,tg_expand $p='{[0-2][0-9][0-9],!{256-299}}'],[0..255],"$sec: $p (slow)";

$sec='big ranges & again quoting';# aaa-ddd is time consuming
is_deeply [tg_expand $p='{aaa,ddd}'],  ['aaa','ddd'], "$sec: $p";
is_deeply [tg_expand $p='{aaa\,ddd}'], ['aaa,ddd'],   "$sec: $p";
is_deeply [tg_expand $p='{aaa-ddd}'],  ['aaa'..'ddd'],"$sec: $p"; # 2110
is_slow   [tg_expand $p='{aaa\-ddd}'], ['aaa-ddd'],   "$sec: $p";

$sec='ranges with neg numbers';
is_deeply [tg_expand $p='{\-5-5}'],[-5..5],"$sec: $p";
is_deeply [tg_expand $p='{-5-5}'],[-5..5],"$sec: $p";
is_deeply [tg_expand $p='{5--5}'],[reverse -5..5],"$sec: $p";
is_deeply [tg_expand $p='{5-\-5}'],[reverse -5..5],"$sec: $p";
is_deeply [tg_expand $p='{-10-10-2}'],[map 2*$_,-5..5],"$sec: $p";
is_deeply [tg_expand $p='{\-10-10-2}'],[map 2*$_,-5..5],"$sec: $p";
is_deeply [tg_expand $p='{10--10-2}'],[reverse map 2*$_,-5..5],"$sec: $p";
is_deeply [tg_expand $p='{10-\-10-2}'],[reverse map 2*$_,-5..5],"$sec: $p";
is_deeply [tg_expand $p='{\-15-\-5}'],[-15..-5],"$sec: $p";
is_deeply [tg_expand $p='{-15--5}'],[-15..-5],"$sec: $p";
is_deeply [tg_expand $p='{-5--15}'],[reverse -15..-5],"$sec: $p";
is_deeply [tg_expand $p='{\-5-\-15}'],[reverse -15..-5],"$sec: $p";
is_deeply [tg_expand $p='{-20--10-2}'],[map 2*$_,-10..-5],"$sec: $p";
is_deeply [tg_expand $p='{\-20-\-10-2}'],[map 2*$_,-10..-5],"$sec: $p";
is_deeply [tg_expand $p='{-10--20-2}'],[reverse map 2*$_,-10..-5],"$sec: $p";
is_deeply [tg_expand $p='{-10-\-20-2}'],[reverse map 2*$_,-10..-5],"$sec: $p";

$sec='different ranges';
is_deeply [tg_expand $p='{bb-aa}'],[reverse 'aa'..'bb'],"$sec: $p";
cmp_ok int(tg_expand $p='{aa-a9}'), '<=', 28,
          "$sec: $p (whatever semantic, but not silly range op)";
is_deeply [tg_expand $p='{995-1_001}'],[@v=qw'995 996 997 998 999 1_000 1_001'],"$sec: $p";
is_deeply [tg_expand $p='{1_001-995}'],[reverse @v],"$sec: $p";
#is_deeply [tg_expand $p='{1_001-0}'],[reverse @v],"$sec: $p";
is_deeply [tg_expand $p='{9.8-10.4}'],[@v=qw'9.8 9.9 10.0 10.1 10.2 10.3 10.4'],"$sec: $p";
is_deeply [tg_expand $p='{10.4-9.8}'],[reverse @v],"$sec: $p";
is_deeply [tg_expand $p="{1'1-1#1}"],["1'1","1#1"],"$sec: $p";
is_deeply [tg_expand $p="{1#1-1'1}"],["1#1","1'1"],"$sec: $p";
is_deeply [tg_expand $p="{1'1-1#1-1}"],["1'1","1#1"],"$sec: $p";
is_deeply [tg_expand $p="{1#1-1'1-1}"],["1#1","1'1"],"$sec: $p";
is_deeply [tg_expand $p="{1'1-1#1-2}"],["1'1"],"$sec: $p";
is_deeply [tg_expand $p="{1#1-1'1-2}"],["1#1"],"$sec: $p";
is_deeply [tg_expand $p="{1#1-1#1}"],["1#1"],"$sec: $p";
is_deeply [tg_expand $p="{1'1-1'1}"],["1'1"],"$sec: $p";
is_deeply [tg_expand $p="{1#1}"],["1#1"],"$sec: $p";
is_deeply [tg_expand $p="{1'1}"],["1'1"],"$sec: $p";
is_deeply [tg_expand $p='{1\-0-2\-0-2}'],[qw'1-0 1-2 1-4 1-6 1-8 2-0'],"$sec: $p";
is_deeply [tg_expand $p='{10\--20\--2}'],[qw'10- 12- 14- 16- 18- 20-'],"$sec: $p";
is_deeply [tg_expand $p='{10\--20--2}'],[qw'10- 12- 14- 16- 18- 20-'],"$sec: $p";
is_deeply [tg_expand $p='{-10\---20--2}'],[qw'-10- -12- -14- -16- -18- -20-'],"$sec: $p";
is_deeply [tg_expand $p="{0%-11%}"],[map "$_%", 0..11 ],"$sec: $p";
is_deeply [tg_expand $p="{%0-%11}"],[map "%$_", 0..11 ],"$sec: $p";
is_deeply [tg_expand $p="{(0)-(99)}"],[map "($_)", 0..99 ],"$sec: $p";
is_deeply [tg_expand $p="{(0)-(111)}"],[map "($_)", 0..111 ],"$sec: $p"; # front
is_deeply [tg_expand $p="{0-11'9}"],[@v=(0..9,map /^(.+)(.)$/&&"$1'$2",10..119)],"$sec: $p";
is_deeply [tg_expand $p="{11'9-0}"],[reverse @v],"$sec: $p"; # front
is_deeply [tg_expand $p='{5-9%}'],[qw'5 6% 7% 8% 9%'], "$sec: $p";
is_deeply [tg_expand $p='{%-8%}'],['%','8%'], "$sec: $p"; # ?: % 1% ... 8%?
#i: a-9%  a 9 (where is the % sign gone), now 9% and 9-a%=9.a%
#   y-8% is actually 9 8% instead y z%, file it under GIGO.

$sec='step size';
is_deeply [tg_expand $p='{001-100-9}'],
          [qw'001 010 019 028 037 046 055 064 073 082 091 100'],"$sec: $p";
is_deeply [tg_expand $p='{\-10-10-2}'],[qw'-10 -8 -6 -4 -2 0 2 4 6 8 10'],"$sec: $p";
is_deeply [tg_expand $p='{10-\-10-2}'],[qw'10 8 6 4 2 0 -2 -4 -6 -8 -10'],"$sec: $p";
is_deeply [tg_expand $p='{10--10-2}'],[qw'10 8 6 4 2 0 -2 -4 -6 -8 -10'],"$sec: $p";
is_deeply [tg_expand $p='{1-15-5}'],[qw'1 6 11'],"$sec: $p";
is_deeply [tg_expand $p='{$1-$15-5}'],[qw'$1 $6 $11'],"$sec: $p";
is_deeply [tg_expand $p='{%1-%15-5}'],[qw'%1 %6 %11'],"$sec: $p";
is_deeply [tg_expand $p='{1-10-5}'],[qw'1 6'],"$sec: $p";
is_deeply [tg_expand $p='{$1-$10-5}'],[qw'$1 $6'],"$sec: $p";
is_deeply [tg_expand $p='{%1-%10-5}'],[qw'%1 %6'],"$sec: $p";
is_deeply [tg_expand $p='{1-1+1_1+9-80}'],
  [@v=qw'1 8+1 1_6+1 2_4+1 3_2+1 4_0+1 4_8+1 5_6+1 6_4+1 7_2+1 8_0+1 8_8+1 9_6+1 1+0_4+1'],
  "$sec: $p";
is_deeply [tg_expand $p='{1+1_1+9-1-80}'],[reverse @v],"$sec: $p";
my @r=tg_expand $p='{1.0-1+1_1+9-80}'; splice @r,3,-3;
is_deeply \@r,[qw'1.0 9.0 1_7+0   8_9+0 9_7+0 1+0_5+0'],"$sec: $p";
is_deeply [tg_expand $p='{1-1_1_0-9}'],
  [qw'1 1_0 1_9 2_8 3_7 4_6 5_5 6_4 7_3 8_2 9_1 1_0_0 1_0_9'],"$sec: $p";
is_deeply [tg_expand $p='{1-1_01_00-99}'],
  [1,'1_00',(map {sprintf'%d_%02d',$_,100-$_} 1..99),qw'1_00_00 1_00_99'],"$sec: $p";

$sec='printable or not';
is_deeply [tg_expand $p="[\0-\40]"],[map chr,0..32],"$sec: [\0-...]";
is_deeply [tg_expand $p="[\t- ]"],
          [grep /[[:print:]\s\v\h\a]/,map chr,ord("\t")..ord(' ')],"$sec: $p";

$sec='punctation and symbol lines';
is_deeply [tg_expand $p='{******-*}'],[qw'****** ***** **** *** ** *'], "$sec: $p";
is_deeply [tg_expand $p='{*-******}'],[qw'* ** *** **** ***** ******'], "$sec: $p";
is_deeply [tg_expand $p='{******-*-2}'],[qw'****** **** **'],           "$sec: $p";
is_deeply [tg_expand $p='{*-******-2}'],[qw'* *** *****'],              "$sec: $p";
is_deeply [tg_expand $p='{%%%%-%}'],[qw'%%%% %%% %% %'],                "$sec: $p";
is_deeply [tg_expand $p='{%-%%%%}'],[qw'% %% %%% %%%%'],                "$sec: $p";
is_deeply [tg_expand $p=':{,\----------})'],[map ':'.('-'x$_).')',0..8],"$sec: $p";
is_deeply [tg_expand $p=':{,----------})'],[':)',':----------)'],"$sec: $p"; # ++

$sec='counter to ..';
is_deeply [tg_expand $p='{9y-10b}'],[qw'9y 9z 10a 10b'],"$sec: $p";
is_deeply [tg_expand $p='{z8-aa1}'],[qw'z8 z9 aa0 aa1'],"$sec: $p";
is_deeply [tg_expand $p='{az-b1}'], ['az'..'bz'],       "$sec: $p";
is_deeply [tg_expand $p='{aa-b0}'], ['aa'..'bz'],       "$sec: $p";
is_deeply [tg_expand $p='{a9-bb}'], ['a9'..'b9'],       "$sec: $p";
is_deeply [tg_expand $p='{y-ba}'],  ['y'..'ba'],        "$sec: $p";
is_deeply [tg_expand $p='{y0-2b0}'],[map /^0*(.*)/,tg_expand '{0y0-2b0}'],"$sec: $p";
is_deeply [tg_expand $p='{a-20}'],  [tg_expand '{,1,2}[a-z]'],            "$sec: $p";
is_deeply [tg_expand $p='{z-a1a}'], [tg_expand 'z','{1-9,a0}[a-z]','a1a'],"$sec: $p";
is_deeply [tg_expand $p='{8a-9z}'], [tg_expand '[89][a-z]'],"$sec: $p";
is_deeply [tg_expand $p='{a8-z9}'], [tg_expand 'a[89]','[b-z][0-9]'],"$sec: $p";
#i: a9..aa: a9 aa, 9z..99: 9z 99 but over 2 ...: definition thing only => no test
cmp_ok int(tg_expand $p='{a9-aa}'),'<=', 2,"$sec: ok";
cmp_ok int(tg_expand $p='{9z-99}'),'<=', 2,"$sec: ok";

$sec="partial sort";
subtest $sec => sub { plan tests => 11;
  $p='[acb][132]'; @v=qw'a1 a3 a2 c1 c3 c2 b1 b3 b2';
  is_deeply [tg_expand $p],\@v,"$sec: $p";
  is_deeply [tg_expand $p,{charclass=>'sort0'}],\@v,"$sec: $p sort0";
  is_deeply [tg_expand $p,{charclass=>'sort=0'}],\@v,"$sec: $p sort=0";
  is_deeply [tg_expand $p,{charclass=>'sort!'}],\@v,"$sec: $p sort!";
  is_deeply [tg_expand $p,{charclass=>'sort'}],[sort +@v],"$sec: $p sort";
  is_deeply [tg_expand $p,{charclass=>'sort1'}],[sort +@v],"$sec: $p sort1";
  is_deeply [tg_expand $p,{charclass=>'sort+'}],[sort +@v],"$sec: $p sort+";
  is_deeply [tg_expand $p,{charclass=>'sort<'}],[sort +@v],"$sec: $p sort<";
  is_deeply [tg_expand $p,{charclass=>'sort-'}],[reverse sort +@v],"$sec: $p sort-";
  is_deeply [tg_expand $p,{charclass=>'sort-1'}],[reverse sort +@v],"$sec: $p sort-1";
  is_deeply [tg_expand $p,{charclass=>'sort>'}],[reverse sort +@v],"$sec: $p sort>";
};
$sec="defined charclasses";
is_deeply [tg_expand $p='[[:lower:]]'],['a'..'z'],"$sec: $p";
is_deeply [tg_expand $p='[[:upper:]]'],['A'..'Z'],"$sec: $p";
is_deeply [tg_expand $p='[[:alpha:]]'],['A'..'Z','a'..'z'],"$sec: $p";
is_deeply [tg_expand $p='[[:lowernum:]]'],['a'..'z',0..9],"$sec: $p";
is_deeply [tg_expand $p='[[:uppernum:]]'],['A'..'Z',0..9],"$sec: $p";
is_deeply [tg_expand $p='[[:alnum:]]'],['A'..'Z','a'..'z',0..9],"$sec: $p";
is_deeply [tg_expand $p='[[:digit:]]'],[0..9],"$sec: $p";
is_deeply [tg_expand $p='[[:xdigit:]]'],[0..9,'a'..'f'],"$sec: $p";
is int(tg_expand $p='[[:punct:]]'),35,"$sec: $p";
is int(tg_expand $p='[[:punct:][:punct:]]'),35*2,"$sec: $p";
is int(tg_expand $p='[abc[:punct:]]'),35+3,"$sec: $p";
is int(tg_expand $p='[[:blank:][:punct:]]'),35+2,"$sec: $p";
is int(tg_expand $p='[a[:blank:]b[:punct:]c]'),35+2+3,"$sec: $p";
is int(tg_expand $p='[-,.[:punct:]]'),35+3,"$sec: $p"; # no uniq
is_deeply [tg_expand $p='[a[:digit:]]'],['a',0..9],"$sec: $p";
is_deeply [tg_expand $p='[[:digit:]a]'],[0..9,'a'],"$sec: $p";
is_deeply [tg_expand $p='[[[:digit:]]'],['[',0..9],"$sec: $p";
is_deeply [tg_expand $p='[[:digit:][]'],[0..9,'['],"$sec: $p";

$sec="charclasses subsets";
is int(@v=tg_expand $p='[[:card1-11,13-25,27-39,41-53,55-56:]]'),52,"$sec: $p";
is_deeply [tg_expand $p='{[[:card1-56:]],![[:card12:][:card26:][:card40:][:card54:]]}'],\@v,"$sec: $p";
is_deeply [tg_expand $p='{[[:card1-56:]],![[:card12,26,40,54:]]}'],\@v,"$sec: $p";
is_deeply [tg_expand $p='[[:punct:]]',{charclass=>'def-'}],
          [qw'[] :] p] u] n] c] t] :]'],"$sec: $p dcc=0";
is_deeply [tg_expand $p='[[:punct:]]',{charclass=>'def-sort0'}],
          [qw'[] :] p] u] n] c] t] :]'],"$sec: $p dcc=0";
is_deeply [tg_expand $p='[[:punct:]]',{charclass=>'sort,def-'}],
          [qw':] :] [] c] n] p] t] u]'],"$sec: $p dcc=0,sort+";
is_deeply [tg_expand $p='[[:punct:]]',{charclass=>'sort-,def-'}],
          [qw'u] t] p] n] c] [] :] :]'],"$sec: $p dcc=0,sort-";
is_deeply [tg_expand $p='[\[:punct:]]'],[qw'[] :] p] u] n] c] t] :]'],"$sec: $p";
is_deeply [tg_expand $p='[\[:punct:\]]'],[qw'[ : p u n c t : ]'],"$sec: $p";
is_deeply [tg_expand $p='[[:punct:\]]'],[qw'[ : p u n c t : ]'],"$sec: $p";
is_deeply [tg_expand $p='[[:lowernum-27:]]'],[@v=qw'9 8 7 6 5 4 3 2 1 0'],"$sec: $p";
is_deeply [tg_expand $p='[[:digit-1:]]'],\@v,"$sec: $p";
is_deeply [tg_expand $p='[[:digit-:]]'],\@v,"$sec: $p";
is_deeply [tg_expand $p='[[:card1,1,1,1:]]'],[("\x{1f0a1}")x 4],"$sec: $p";

#  \\* \* []
$sec='dequ';
is_deeply [tg_expand '\\a', '\\?', $p='\\*'],        [qw'\\a ? *'],"$sec: $p ...";
is_deeply [tg_expand '\\b', '\\{\\}', $p='\\[\\]'],[qw'\\b {} []'],"$sec: $p ...";
is_deeply [tg_expand $p='\\\\?'],[qw'\\?'],"$sec: $p ...";
is_deeply [tg_expand '\\\\c', '\\\\{?}', $p='\\\\{*}'],[qw'\\c \\? \\\\c'],"$sec: $p ...";
is_deeply [tg_expand $p='{\\\\c,\\\\*}'],[qw'\\c \\c'],"$sec: $p";
is_deeply [tg_expand $p='\\\\*'],[qw'\\*'],"$sec: $p";
is_deeply [tg_expand $p='\\\\\*'],[qw'\\*'],"$sec: $p";
is_deeply [tg_expand '\\\\{}\*', $p='\\\\[]\*'],[qw'\\* \\*'],"$sec: $p ...";

is_deeply [tg_expand '{\\\\}', $p='[\\\\]'],           [qw'\\ \\'],"$sec: $p ...";
is_deeply [tg_expand '{\\\\}\*', $p='[\\\\]\*'],     [qw'\\* \\*'],"$sec: $p ...";
is_deeply [tg_expand '{\\\\}\?', $p='[\\\\]\?'],     [qw'\\? \\?'],"$sec: $p ...";
is_deeply [tg_expand '{\\\\}?', $p='[\\\\]?'],       [qw'\\? \\?'],"$sec: $p ...";

$sec='last=0';
subtest $sec => sub { plan tests => 6;
  is_deeply [tg_expand '{\\\\}', $p='[\\\\]',{last=>0}],[qw'\\\\ \\\\'],"$sec: $p ...";
  is_deeply [tg_expand $p='\\\\?',{last=>0}],[qw'\\\\?'],"$sec: $p ...";
  is_deeply [tg_expand '\\a', '\\?', $p='\\*',{last=>0}], [qw'\\a ? *'],"$sec: $p ...";
  is_deeply [tg_expand '\\b', '\\{\\}', $p='\\[\\]',{last=>0}],[qw'\\b {} []'],"$sec: $p ...";
  is_deeply [tg_expand '\\\\c', '\\\\{?}', $p='\\\\{*}',{last=>0}],
            [qw'\\\\c \\\\? \\\\\\\\c'],"$sec: $p ...";
  is_deeply [tg_expand $p='{\\\\c,\\\\*}',{last=>0}],[qw'\\\\c \\\\c'],"$sec: $p";
};
$sec='\\ & ?';
# v- tg_expand '{\\\\c,???}'" # no because \\\\c is also pattern => ??
is_deeply [tg_expand $p='{\\\\c,??}'],[qw'\\c \\c'],"$sec: $p";
is_deeply [tg_expand $p='{\\\\c,?c}'],[qw'\\c \\c'],"$sec: $p"; # ???
is_deeply [tg_expand $p='{\\c,?c}'],[qw'\\c \\c'],"$sec: $p"; # ???
is_deeply [tg_expand $p='{\\c,??}'],[qw'\\c \\c'],"$sec: $p";
is_deeply [tg_expand $p='{\\c,?}'],[qw'\\c ?'],"$sec: $p";
# ^- but {\\c,??} instead of {\\c,?}
TODO: { local $TODO='...';
  is_deeply [tg_expand '\\\\c', $p='\\\\?'],[qw'\\c \\c'],"$sec: $p ...";
  is_deeply [tg_expand $p='{\\\\c,\\\\?}'],[qw'\\c \\c'],"$sec: $p";
}

had_no_warnings();