#! /usr/bin/perl -wT

use v5.10; use strict; use warnings;
use Test::More tests => 242;                  BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};
use Text::Glob::DWIW qw':all';
my $p; my @v; my $sec='match';

is tg_match($p='a*','aaa'),1,                    "$sec: $p";
is tg_match('a*','aaa',{invert=>1}),'',          "$sec: $p (v=1)";
is tg_match('a*','bbb'),'',                      "$sec: $p !";
is tg_match('a*','bbb',{invert=>1}),1,           "$sec: $p ! (v=1)";
is scalar(tg_match 'a*','aaa'),1,                "$sec: $p [scalar forced]";
is scalar(tg_match 'a*','aaa',{invert=>1}),'',   "$sec: $p  (v=1)";
is scalar(tg_match 'a*','bbb'),'',               "$sec: $p !";
is scalar(tg_match 'a*','bbb',{invert=>1}),1,    "$sec: $p ! (v=1)";
is_deeply [tg_match 'a*','aaa'],[1],             "$sec: $p [list]";
is_deeply [tg_match 'a*','aaa',{invert=>1}],[''],"$sec: $p (v=1)";
is_deeply [tg_match 'a*','bbb'],[''],            "$sec: $p !";
is_deeply [tg_match 'a*','bbb',{invert=>1}],[1], "$sec: $p ! (v=1)";

is_deeply [tg_match 'a*',qw'aaa abc a b'],            [1,1,1,''],  "$sec: $p [multi]";
is_deeply [tg_match 'a*',qw'aaa abc a b',{invert=>1}],['','','',1],"$sec: $p (v=1)";

$sec='grep';

my @samples=(qw'abc abcd abbc ac'); my @foo=(qw'foo/bar foobaz foo*bam');
my @dose=(qw'12345678.a 12345678.ab 12345678.abc 12345678.abcd 12345678.
             12345678 12345678abcd 12345678abc 12345678ab 12345678a
             1234567.a 1234567.ab 1234567.abc 1234567.abcd ou.bla ou*bla
             12345678.abc 12345678.abc 123456789.abc 123456.abc .abc');

is_deeply [tg_grep $p='a*c',@samples],     [qw'abc abbc ac'],"$sec: $p";
is_deeply [tg_grep $p='z*c',@samples],     [],               "$sec: $p";
is_deeply [tg_grep $p='z*c',()],           [],               "$sec: $p nil";
is_deeply [tg_grep $p='a?c',@samples],     [qw'abc'],        "$sec: $p";
is_deeply [tg_grep $p='a??c',@samples],    [qw'abbc'],       "$sec: $p";

is_deeply [tg_grep $p='a\*c',@samples],           [],        "$sec: $p";
is_deeply [tg_grep $p='a\*c',@samples,'a*c'],     ['a*c'],   "$sec: $p +";

is_deeply [tg_grep $p='a\bc',@samples],           [],        "$sec: $p";
is_deeply [tg_grep $p='a\bc',@samples,'a\bc'],    ['a\bc'],  "$sec: $p +";
is_deeply [tg_grep $p='a\\bc',@samples,'a\\bc'],  ['a\bc'],  "$sec: $p +";
is_deeply [tg_grep $p='a\\b\\',@samples,'a\\b\\'],['a\\b\\'],"$sec: $p +";

is_deeply [tg_grep $p='{abc,wert}',@samples],     ['abc'],   "$sec: $p";

is_deeply [tg_grep $p='fo*ba*',@foo],\@foo,"$sec: $p";
is_deeply [tg_grep $p='a*a', @v=qw'aa abba abracadabra'],\@v,"$sec: $p";

is_deeply [tg_grep $p='{foo,bar}']  ,           [],     "$sec: $p";
is_deeply [tg_grep $p=[qw'foo bar']],           [],     "$sec: [qw'foo bar']";
is_deeply [tg_grep $p='{foo,bar}','foo'],       ['foo'],"$sec: $p +";
is_deeply [tg_grep $p=[qw'foo bar'],'foo'],     ['foo'],"$sec: [qw'foo bar'] +";
is_deeply [tg_grep $p='{foo,bar}',@v=qw'foo bar'],\@v,  "$sec: $p +";
is_deeply [tg_grep $p=[qw'foo bar'],@v=qw'foo bar'],\@v,"$sec: [qw'foo bar'] +";
is_deeply [tg_grep $p='a ', 'a'],[],"$sec: '$p'";
is_deeply [tg_grep $p='a', 'a '],[],"$sec: '$p'";

$sec='casing';
my @casecases=(qw'ABC abc Abc aBC aBc      Abd  A AAA');
is_deeply [tg_grep {case=>0}, 'Abc', @casecases], [@casecases[0..4]],"$sec: 0 # all except Abd+";
is_deeply [tg_grep {case=>1}, 'Abc', @casecases], ['Abc'],      "$sec: 1 # only Abc";
is_deeply [tg_grep {case=>2}, 'Abc', @casecases], ['ABC','Abc'],"$sec: 2 # ABC Abc";
is_deeply [tg_grep {case=>-1},'Abc', @casecases], ['aBC'],      "$sec:-1 # aBC";
is_deeply [tg_grep {case=>-2},'Abc', @casecases], ['ABC','aBC'],"$sec:-2 # ABC aBC";

$sec='glob';
is_deeply [tg_glob $p='{foo,bar}']  ,[qw'foo bar'],"$sec: $p";
is_deeply [tg_glob $p=[qw'foo bar']],[qw'foo bar'],"$sec: [qw'foo bar']";

is_deeply [tg_glob $p='whatever',@samples],  ['whatever'],"$sec: $p";
is_deeply [tg_glob $p='{whatever}',@samples],['whatever'],"$sec: $p";
is_deeply [tg_glob $p='{whatever,whatever}',@samples],['whatever','whatever'],"$sec: $p";
is_deeply [tg_glob $p='a*c',@samples],     [qw'abc abbc ac'],"$sec: $p";
is_deeply [tg_glob $p='z*c',@samples],            [],        "$sec: $p";
is_deeply [tg_glob $p='z*c',()],                  [],        "$sec: $p nil";
is_deeply [tg_glob $p='a?c',@samples],            ['abc'],   "$sec: $p";
is_deeply [tg_glob $p='a??c',@samples],           ['abbc'],  "$sec: $p";
is_deeply [tg_glob $p='a\*c',@samples],           ['a\*c'],  "$sec: $p";
is_deeply [tg_glob $p='a\*c',@samples,'a*c'],     ['a*c'],   "$sec: $p +";
is_deeply [tg_glob $p='a\*c',@samples,{star=>0}], ['a\*c'],  "$sec: $p (*=0)";
is_deeply [tg_glob $p='a*c',@samples,'a*c',{star=>0}],     ['a*c'],"$sec: $p  (*=0) +";
is_deeply [tg_glob $p='a\bc',@samples],['a\bc'],"$sec: $p"; # don't exist, but non ?*
is_deeply [tg_glob $p='a\bc',@samples,'a\bc'],    ['a\bc'],  "$sec: $p +";
is_deeply [tg_glob $p='a\\bc',@samples,'a\\bc'],  ['a\bc'],  "$sec: $p +";
is_deeply [tg_glob $p='a\\b\\',@samples,'a\\b\\'],['a\\b\\'],"$sec: $p +";

is_deeply [tg_glob $p='{abc,wert}',@samples],['abc','wert'],"$sec: $p";

is_deeply [tg_glob $p='a\*c',@samples,'a\*c',{star=>0}],['a\*c'],"$sec: $p (*=0) +";
is_deeply [tg_glob $p='a\*c',@samples,'a*c',{star=>0}],['a\*c'],"$sec: $p (*=0) +";
   # ^- defined that way: when *=0 then \*==\* and not *, => don't match

is_deeply [tg_glob $p='*',qw(a b c d)],[qw(a b c d)],"$sec: $p";
is_deeply [tg_glob $p='{a,b}'],[qw(a b)],"$sec: $p";
is_deeply [tg_glob $p='{a,b}',{}],[qw(a b)],"$sec: $p";
is_deeply [tg_glob {},$p='{a,b}'],[qw(a b)],"$sec: $p";
is_deeply [tg_glob $p='{BlaGlob.p*,doesntexist*,a,b}','BlaGlob.pm'],
          [qw(BlaGlob.pm a b)],"$sec: $p";
is_deeply [tg_glob $p='*[Gg]lo[bp]*',@v=qw'bla_a bla_b bla_c bla_d'],[],"$sec: $p";
is_deeply [tg_glob $p='*[Gg]lo[bp]*',@v=qw'Glob glob aaglob globbb aaglobbb xx::glop'],
          \@v,"$sec: $p";
is_deeply [tg_glob $p='????????.??*',@dose],
          [grep /^.{8}\..{2,}$/, @dose],          "$sec: $p";
is_deeply [sort +tg_glob $p='{ou,????????.??}*',@dose],
          [sort +grep /^(?:ou|.{8}\...).*/,@dose],"$sec: $p";
is_deeply [tg_glob $p='bogus{1,2,3}','bogus2'],[qw'bogus1 bogus2 bogus3'],"$sec: $p";
is_deeply [tg_glob $p='{TES*,doesntexist*,a,b}','TEST'],[qw'TEST a b'],   "$sec: $p";
is_deeply [tg_glob $p='a*{d[e]}j',qw'a_dej a_ghj a_qej'],['a_dej'],       "$sec: $p";
for my $pl ('a b',"a'b'",'a"b"','a"b',"a'b",'"a" "b"')
{ is_deeply [tg_glob $pl],    [$pl], "$sec: $pl (1:1)";
  is_deeply [tg_glob $pl,$pl],[$pl], "$sec: $pl (1:1) +";
}
is_deeply [tg_glob $p='op\\g*.t', 'op\\glob.t'],['op\\glob.t'],"$sec: $p";
is_deeply [tg_glob $p='\\[\\]', '[]'],['[]'],"$sec: $p"; # native \\ vs. quoting \\

is_deeply [tg_glob $p='foo (*', @v='foo (123) bar'],       \@v,"$sec: $p"; # ()
is_deeply [tg_glob $p='*) bar', @v='foo (123) bar'],       \@v,"$sec: $p";
is_deeply [tg_glob $p='foo (1*3) bar', @v='foo (123) bar'],\@v,"$sec: $p";
is_deeply [tg_glob $p='foo |1*3| bar', @v='foo |123| bar'],\@v,"$sec: $p";
is_deeply [tg_glob $p=' ', ' '],[' '],"$sec: '$p'";
is_deeply [tg_glob $p='a ', 'a '],['a '],"$sec: '$p'";
is_deeply [tg_glob $p='a ', 'a'],['a '],"$sec: '$p'";
is_deeply [tg_glob $p='a', 'a '],['a'],"$sec: '$p'";

$sec='opt'; # glob or grep
my $oc={qw'unchar /'}; my $oh={qw'unhead .'}; my $o2={qw'unchar /  unhead .'};
for my $o ({},$oc,$oh,$o2)
{ is_deeply [tg_glob $p='*/*',@v=qw'bla/a bla/b bla/c bla/d',$o],\@v,      "$sec: $p (/)";
  is_deeply [tg_glob $p='*/*',@v=qw'bla_a bla_b bla_c bla_d',$o],[],       "$sec: $p (/)";
}
for my $o ($oc,$o2)
{ is_deeply [tg_glob $p='fo*ba*',@foo,$o],['foobaz','foo*bam'],"$sec: $p";
  is_deeply [tg_glob $p='a*c',qw'a/b/c',$o],      [],                      "$sec: $p (/)";
}
for my $o ($oh,$o2)#$oh
{ is_deeply [tg_glob $p='*',qw'abc .abc a.bc',$o],[qw'abc a.bc'],          "$sec: $p (.)";
  is_deeply [tg_glob $p='.*',qw'abc .abc a.bc',$o],   [qw'.abc'],          "$sec: $p (.)";
  is_deeply [tg_glob $p='{,.}*',qw'abc a.bc .abc',$o],[qw'abc a.bc .abc'], "$sec: $p (.)";
  is_deeply [tg_glob $p='{.,}*',qw'abc a.bc .abc',$o],[qw'.abc abc a.bc'], "$sec: $p (.)";
  is_deeply [tg_glob $p='{*,.*}',qw'abc a.bc .abc',$o],[qw'abc a.bc .abc'], "$sec: $p (.)";
  is_deeply [tg_glob $p='{.*,*}',qw'abc a.bc .abc',$o],[qw'.abc abc a.bc'], "$sec: $p (.)";
  is_deeply [textglob '*', qw'. .. .bashrc fine your.txt',$o],[qw'fine your.txt'],"$sec: * (.)";
}

$sec='wildcards under unchar (simple)';
is_deeply [tg_grep $p='',''],[''], "$sec: $p ''";
is_deeply [tg_grep $p='?',''],[], "$sec: $p ''";
is_deeply [tg_grep $p='*',''],[''], "$sec: $p ''";
is_deeply [tg_grep $p='**',''],[''], "$sec: $p ''";
is_deeply [tg_grep $p='***',''],[''], "$sec: $p ''";
is_deeply [tg_grep $p='','',$o2],[''], "$sec: $p '' (./)";
is_deeply [tg_grep $p='?','',$o2],[], "$sec: $p '' (./)";
is_deeply [tg_grep $p='*','',$o2],[''], "$sec: $p '' (./)";
is_deeply [tg_grep $p='**','',$o2],[''], "$sec: $p '' (./)";
is_deeply [tg_grep $p='***','',$o2],[''], "$sec: $p '' (./)";
is_deeply [tg_grep $p='','/'],[], "$sec: $p ''";
is_deeply [tg_grep $p='/','/'],['/'], "$sec: $p ''";
is_deeply [tg_grep $p='?','/'],['/'], "$sec: $p ''";
is_deeply [tg_grep $p='*','/'],['/'], "$sec: $p ''";
is_deeply [tg_grep $p='**','/'],['/'], "$sec: $p ''";
is_deeply [tg_grep $p='***','/'],['/'], "$sec: $p ''";
is_deeply [tg_grep $p='','/',$o2],[], "$sec: $p '' (./)";
is_deeply [tg_grep $p='/','/',$o2],['/'], "$sec: $p '' (./)";
is_deeply [tg_grep $p='?','/',$o2],[], "$sec: $p '' (./)";
is_deeply [tg_grep $p='*','/',$o2],[], "$sec: $p '' (./)";
is_deeply [tg_grep $p='**','/',$o2],['/'], "$sec: $p '' (./)";
is_deeply [tg_grep $p='***','/',$o2],['/'], "$sec: $p '' (./)";

$sec='wildcards under unchar';
is_deeply [tg '*{,/*}', qw'. .. .bashrc home/.rc bla/.. fine your.txt',$o2],
          [qw'fine your.txt'],"$sec: * (./)";
is_deeply [tg $p='foo?bar?foo','foo/bar.foo'],['foo/bar.foo'],"$sec: $p";
is_deeply [tg $p='foo*bar*foo','foo/bar.foo'],['foo/bar.foo'],"$sec: $p";
is_deeply [tg $p='foo**bar**foo','foo/bar.foo'],['foo/bar.foo'],"$sec: $p";
is_deeply [tg $p='foo***bar***foo','foo/bar.foo'],['foo/bar.foo'],"$sec: $p";
is_deeply [tg $p='foo?bar?foo','foo/bar.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='foo*bar*foo','foo/bar.foo',$o2],[],"$sec: $p";
is_deeply [tg $p='foo**bar**foo','foo/bar.foo',$o2],[],"$sec: $p";
is_deeply [tg $p='foo***bar***foo','foo/bar.foo',$o2],['foo/bar.foo'],"$sec: $p";
is_deeply [tg $p='foo??foo','foo/.foo'],['foo/.foo'],"$sec: $p";
is_deeply [tg $p='foo*foo','foo/.foo'],['foo/.foo'],"$sec: $p";
is_deeply [tg $p='foo??foo','foo/.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='foo*foo','foo/.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='foo/*foo','foo/.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='foo/*.foo','foo/.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='foo*.foo','foo/.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='foo***foo','foo/.foo',$o2],['foo/.foo'],"$sec: $p (./)";
is_deeply [tg $p='foo**foo','foo/.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='foo/.*foo','foo/.foo',$o2],['foo/.foo'],"$sec: $p (./)";
is_deeply [tg $p='foo/**.*foo','foo/.foo',$o2],['foo/.foo'],"$sec: $p (./)";
is_deeply [tg $p='foo/*.*foo','foo/.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='?foo','.foo'],['.foo'],"$sec: $p";
is_deeply [tg $p='*foo','.foo'],['.foo'],"$sec: $p";
is_deeply [tg $p='?foo','.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='*foo','.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='*.foo','.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='***foo','.foo',$o2],['.foo'],"$sec: $p (./)";
is_deeply [tg $p='**foo','.foo',$o2],[],"$sec: $p (./)";
is_deeply [tg $p='.*foo','.foo',$o2],['.foo'],"$sec: $p (./)";
is_deeply [tg $p='**.*foo','.foo',$o2],['.foo'],"$sec: $p (./)";
is_deeply [tg $p='*.*foo','.foo',$o2],[],"$sec: $p (./)";

$sec='twin and triplet';
sub ttt ($$)
{ my ($sec,$sep)=@_; my $v=join $sep,qw'ab cd ef'; my $o2={unchar=>$sep,unhead=>'.'};
  my $psep=$sep eq '\\' ? quotemeta $sep : $sep;
  sub resl ($); local *resl=sub ($) { (my $t=$_[0])=~s{/}{$psep}g; $t };
  subtest $sec => sub {
    plan tests => 64;
    is_deeply [tg $p='*',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='**',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='***',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='**'.$sep,$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='***'.$sep,$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='**'.$sep,"$v$sep",$o2],["$v$sep"],"$sec: $p +$sep";
    is_deeply [tg $p='***'.$sep,"$v$sep",$o2],["$v$sep"],"$sec: $p +$sep";
    is_deeply [tg $p='**',"$v$sep",$o2],["$v$sep"],"$sec: $p +$sep";
    is_deeply [tg $p='***',"$v$sep",$o2],["$v$sep"],"$sec: $p +$sep";
    is_deeply [tg $p='*f',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='**f',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='***f',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='*ef',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='**ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='***ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='a*',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='a**',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='a***',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='ab*',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='ab**',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='ab***',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p="ab$psep*",$v,$o2],[],"$sec: $p";
    is_deeply [tg $p="ab$psep**",$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p="ab$psep***",$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='a*f',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='a**f',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='a***f',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='ab*ef',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='ab**ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='ab***ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p="ab$psep*${sep}ef",$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p="ab$psep**${sep}ef",$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p="ab$psep***${sep}ef",$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='*c*',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='**c**',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='***c***',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='*cd*',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p='**cd**',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p='***cd***',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl('*/cd/*'),$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl '**/cd/**',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl '***/cd/***',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'a**cd/ef',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p=resl 'a***cd/ef',$v,{%$o2,twin=>'***-'}],[],"$sec: $p";
    is_deeply [tg $p=resl 'a***cd/ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'a**cd/ef',$v,{%$o2,twin=>'**+'}],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'a**/cd/ef',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p=resl 'a***/cd/ef',$v,{%$o2,twin=>'***-'}],[],"$sec: $p";
    is_deeply [tg $p=resl 'a***/cd/ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'a**/cd/ef',$v,{%$o2,twin=>'**+'}],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'a/**cd/ef',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p=resl 'a/***cd/ef',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p=resl 'ab*cd/ef',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p=resl 'ab**cd/ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'ab***cd/ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'ab*/cd/ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'ab**/cd/ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'ab***/cd/ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'ab/*cd/ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'ab/**cd/ef',$v,$o2],[$v],"$sec: $p";
    is_deeply [tg $p=resl 'ab/***cd/ef',$v,$o2],[$v],"$sec: $p";

    is_deeply [tg $p=resl 'ab/*/cd/ef',$v,$o2],[],"$sec: $p";

    is_deeply [tg $p=resl 'ab/**/cd/ef',$v,$o2],[],"$sec: $p";
    is_deeply [tg $p=resl 'ab/***/cd/ef',$v,$o2],[],"$sec: $p";
    done_testing;
  }
}
ttt $sec,'/';
ttt "$sec (windows-like)", '\\';
ttt "$sec (NL)", "\n";
ttt "$sec (X)", "X";

$sec="path semantic";
subtest $sec => sub {
  sub _visible { grep !m'^\.|/\.',@_ }
  plan tests => 37;
  my @p=(qw'/aa/bb/cc/dd /aa/bb/cc/dd/ /aa/bb/cc/dd.e /aa/bb/cc/dd.e/
            /aa/bb/cc/.dd  /aa/bb/cc/.dd/  /.aa/bb/cc/dd  /.aa/bb/cc/dd/
            / x 11 11.e 11/ 11.e/ /11 /11.e /11/ /11.e/
            rr/ss/tt/uu rr/ss/tt/uu/ rr/ss/tt/uu.e rr/ss/tt/uu.e/
            ./vv/ww/xx/yy ./vv/ww/xx/yy/ ./vv/ww/xx/yy.e ./vv/ww/xx/yy.e/
            /aa /aa/ r rr rr/ ./v ./vv ./vv/ . .. ./ ../ /. /.. /./ /../ //
            a. a./ /a. /a./ a.b a.b/ /a.b /a.b/','');
  my @all_abs =grep m'^/',@p;    my @all_visabs =_visible @all_abs;
  my @all_rels=grep m'^[^/]',@p; my @all_visrels=_visible @all_rels;
  my @all_dirs=grep m'/$',@p;    my @all_visdirs=_visible @all_dirs;
  my $o2={unchar=>'/',unhead=>'.'};
  is_deeply [tg_grep $p='/*', @p,$o2],[grep m'^/([^/.][^/]*)?$',@p],"$sec: $p";
  is_deeply [tg_grep $p='/**', @p,$o2],\@all_visabs,"$sec: $p";
  is_deeply [tg_grep $p='{/**}', @p,$o2],\@all_visabs,"$sec: $p";
  is_deeply [tg_grep $p='/{**}', @p,$o2],\@all_visabs,"$sec: $p";
  is_deeply [tg_grep $p='{/}**', @p,$o2],\@all_visabs,"$sec: $p";
  is_deeply [tg_grep $p='{/}{**}', @p,$o2],\@all_visabs,"$sec: $p";
  is_deeply [tg_grep $p='/***', @p,$o2],\@all_abs,"$sec: $p";
  is_deeply [tg_grep $p='/*', @p],\@all_abs,"$sec: $p";
  is_deeply [tg_grep $p='/**', @p],\@all_abs,"$sec: $p";
  is_deeply [tg_grep $p='/***', @p],\@all_abs,"$sec: $p";
  is_deeply [tg_grep $p='?**', @p,$o2],[grep m'^[^/.](?:$|/)',@p],"$sec: $p";
  is_deeply [tg_grep $p='?**', @p,$o2],[tg_grep '{?,?/***}',@p,$o2],"$sec: $p";
  is_deeply [tg_grep $p='?**', @p,$o2],[tg_grep '?{,/***}',@p,$o2],"$sec: $p";
  is_deeply [tg_grep $p='?***', @p,$o2],[grep !/^\./,@all_rels],"$sec: $p";
  is_deeply [tg_grep $p='*/', @p,$o2],[grep m'^(?:[^/.][^/]*)?/$',@p],"$sec: $p";
  is_deeply [tg_grep $p='**/', @p,$o2],\@all_visdirs,"$sec: $p";
  is_deeply [tg_grep $p='{**/}', @p,$o2],\@all_visdirs,"$sec: $p";
  is_deeply [tg_grep $p='{**}/', @p,$o2],\@all_visdirs,"$sec: $p";
  is_deeply [tg_grep $p='**{/}', @p,$o2],\@all_visdirs,"$sec: $p";
  is_deeply [tg_grep $p='{**}{/}', @p,$o2],\@all_visdirs,"$sec: $p";
  is_deeply [tg_grep $p='***/', @p,$o2],\@all_dirs,"$sec: $p";
  is_deeply [tg_grep $p='*/', @p],\@all_dirs,"$sec: $p";
  is_deeply [tg_grep $p='**/', @p],\@all_dirs,"$sec: $p";
  is_deeply [tg_grep $p='***/', @p],\@all_dirs,"$sec: $p";
  is_deeply [tg_grep $p='**??', @p,$o2],[_visible grep m'(?:^|/)[^/.][^/]$',@p],"$sec: $p";
  is_deeply [tg_grep $p='**.e', @p,$o2],[],"$sec: $p";
  is_deeply [tg_grep $p='***.e', @p,$o2],[grep m'\.e$',@p],"$sec: $p";
  is_deeply [tg_grep $p='**??.*',@p,$o2],
            [_visible grep m'(?:^|/)[^/][^/]\.[^/]*$',@p],"$sec: $p";
  is_deeply [tg_grep $p='**??.*{,/}',@p,$o2],
            [_visible grep m'(?:^|/)[^/][^/]\..*',@p],"$sec: $p";
  is_deeply [tg_grep $p='**{bb,ss}**',@p,$o2],
            [grep !m'/\.',grep m'(?:^|/)(?:bb|ss)(?:$|/)',@p],"$sec: $p";
  is_deeply [tg_grep $p='***/{bb,ss}/***',@p,$o2],[grep m'/(?:bb|ss)/',@p],"$sec: $p";
  is_deeply [tg_grep $p='**/{bb,ss}/**',@p,$o2],[grep !m'/\.',grep m'/(?:bb|ss)/',@p],"$sec: $p";
  is_deeply [tg_grep $p='***{bb,ss}***',@p,$o2],[grep m'(?:bb|ss)',@p],"$sec: $p";
  is_deeply [tg_grep $p='**{b,s}**',@p,$o2],[],"$sec: $p";
  is_deeply [tg_grep $p='***{b,s}***',@p,$o2],[grep m'(?:b|s)',@p],"$sec: $p";
  is_deeply [tg_grep $p='{,/}aa/***.e',@p,$o2],[grep m'^/?aa/.*\.e$',@p],"$sec: $p";
  is_deeply [tg_grep $p='{,/}aa/**.e',@p,$o2],[],"$sec: $p";

  done_testing;
};

is_deeply [tg_glob $p='a*c',@v="a\nb\nc"],      \@v,           "$sec: $p (NL)";
is_deeply [tg_glob $p='a*c',"a\nb\nc",{unchar=>"\n"}],      [],           "$sec: $p (NL)";

{ my @r=tg_glob $p='a*c',@samples,{star=>0};
  ok @r==0||@r==1&&$r[0]eq'a*c',"$sec: $p  (*=0)";
  #i: ok(eg_array(\@r,['a*c'])||eg_array(\@r,[]),"$sec: $p  (*=0)");
  #   is_deeply [tg_glob $p='a*c',@samples,{star=>0}], ['a*c'],"$sec: $p  (*=0)";
  #   or [] ok?, otherwise useless anyway (for now: let it undefined)
}

$sec='string overloaded';
SKIP: { eval { require Path::Class } or skip "Path::Class not installed",2;
  my @v=map Path::Class::foreign_dir('Unix',$_), qw'bla/a bla/b bla/c bla/d';
  is_deeply [tg_glob $p='*/*',@v],    \@v,      "$sec: $p";
  is_deeply [tg_glob $p='*/*',@v,$o2],\@v,      "$sec: $p (/)";
}

$sec='chameleon';
is_deeply [textglob $p='{foo,bar}']  , [qw'foo bar'],"$sec: $p";
is_deeply [textglob $p=[qw'foo bar']], [qw'foo bar'],"$sec: [qw'foo bar']";

is_deeply [textglob $p='z*c',@samples],[],           "$sec: $p";
is_deeply [textglob $p='z*c',()],      ['z*c'],      "$sec: $p";

for (qw'a b c') { is_deeply [textglob],[$_], "$sec: \$_";}

$sec='\\ & ?';
is_deeply [tg_grep $p='??','\\\\c',{backslash=>1}],['\\\\c'],"$sec: $p";
is_deeply [tg_grep $p='?c','\\\\c',{backslash=>1}],['\\\\c'],"$sec: $p"; # ???
is_deeply [tg_grep $p='??','\\\\c',{backslash=>'\\'}],['\\\\c'],"$sec: $p";
is_deeply [tg_grep $p='?c','\\\\c',{backslash=>'\\'}],['\\\\c'],"$sec: $p"; # ???
is_deeply [tg_grep $p='??','\\\\c',{unchar=>'\\',backslash=>1}],['\\\\c'],"$sec: $p";
is_deeply [tg_grep $p='?c','\\\\c',{unchar=>'\\',backslash=>1}],['\\\\c'],"$sec: $p"; # ???
is_deeply [tg_grep $p='??','\\\\c',{unchar=>'\\',backslash=>'\\'}],['\\\\c'],"$sec: $p";
is_deeply [tg_grep $p='?c','\\\\c',{unchar=>'\\',backslash=>'\\'}],['\\\\c'],"$sec: $p"; # ???
is_deeply [tg_grep $p='?c','\\c'],['\\c'],"$sec: $p"; # ???
is_deeply [tg_grep $p='??','\\c'],['\\c'],"$sec: $p";
is_deeply [tg_grep $p='?','\\c',{backslash=>1}],['\\c'],"$sec: $p";
is_deeply [tg_grep $p='?','\\c',{backslash=>'\\'}],[],"$sec: $p";
is_deeply [tg_grep $p='?','\\c',{unchar=>'\\',backslash=>'\\'}],[],"$sec: $p"; # XXX
is_deeply [tg_grep $p='?','\\c',{unchar=>'\\',backslash=>1}],['\\c'],"$sec: $p";
is_deeply [tg_grep $p='?','\\c'],[],"$sec: $p";
is_deeply [tg_grep $p='\\\\?','\\c'],['\\c'],"$sec: $p";
is_deeply [tg_grep $p='\\\\?','\\\\c',{backslash=>1}],['\\\\c'],"$sec: $p";
is_deeply [tg_grep $p='\\\\?','\\\\c',{unchar=>'\\',backslash=>1}],['\\\\c'],"$sec: $p";
is_deeply [tg_grep $p='?c','\\\\c',{backslash=>'\\'}],['\\\\c'],"$sec: $p"; # FAIL
is_deeply [tg_grep $p='?c','\\\\c',{unchar=>'\\',backslash=>'\\'}],['\\\\c'],"$sec: $p";
is_deeply [tg_grep '\\\\\\\\?','\\\\c'],['\\\\c'],"$sec: $p";
is_deeply [tg_grep $p='\\\\?','\\\\c',{backslash=>'\\'}],[],"$sec: $p"; # no
is_deeply [tg_grep $p='\\\\?','\\\\c',{unchar=>'\\',backslash=>'\\'}],[],"$sec: $p";

$sec='bs & unchar';
is_deeply [tg_grep $p='**aa','aa\/aa',{unchar=>'/',backslash=>'/'}],[],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa\/aa',{unchar=>'/',backslash=>1}],[],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa\\\\aa',{unchar=>'\\',backslash=>'\\'}],[],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa\\\\aa',{unchar=>'\\',backslash=>1}],[],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa',{unchar=>'\\',backslash=>'\\'}],['aa'],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa',{unchar=>'\\',backslash=>1}],['aa'],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa\/aa',{unchar=>'\\/',backslash=>'/'}],[],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa\/aa',{unchar=>'\\/',backslash=>1}],[],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa\\\\aa',{unchar=>'\\/',backslash=>'\\'}],[],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa\\\\aa',{unchar=>'\\/',backslash=>1}],[],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa',{unchar=>'\\/',backslash=>'\\'}],['aa'],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa',{unchar=>'\\/',backslash=>1}],['aa'],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa\/aa',{unchar=>'/',backslash=>'\\/'}],[],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa\\\\aa',{unchar=>'\\',backslash=>'\\/'}],[],"$sec: $p";
is_deeply [tg_grep $p='**aa','aa',{unchar=>'\\',backslash=>'\\/'}],['aa'],"$sec: $p";

$sec='unhead alone';
is_deeply [tg_grep $p='???', '.aa',{unhead=>'.'}],[],"$sec: $p";
is_deeply [tg_grep $p='*',   '.aa',{unhead=>'.'}],[],"$sec: $p";
is_deeply [tg_grep $p='**',  '.aa',{unhead=>'.'}],[],"$sec: $p";
is_deeply [tg_grep $p='***', '.aa',{unhead=>'.'}],['.aa'],"$sec: $p";
is_deeply [tg_grep $p='.??', '.aa',{unhead=>'.'}],['.aa'],"$sec: $p";
is_deeply [tg_grep $p='.*',  '.aa',{unhead=>'.'}],['.aa'],"$sec: $p";
is_deeply [tg_grep $p='.*',  '.aa',{unhead=>'.',unchar=>'/'}],['.aa'],"$sec: $p";
is_deeply [tg_grep $p='.**', '.aa',{unhead=>'.'}],['.aa'],"$sec: $p";
is_deeply [tg_grep $p='.**', '.aa',{unhead=>'.',unchar=>'/'}],[],"$sec: $p";
is_deeply [tg_grep $p='.***','.aa',{unhead=>'.'}],['.aa'],"$sec: $p";

$sec="anchored off";
is_deeply [tg_grep $p='jam', @v=qw'pyjamas jamboree',{anchored=>0}],\@v,"$sec: $p";


had_no_warnings();
#done_testing;

# Todo Tests:
# anchored=>0 & backslash=>1 & unchar=>'/' and ...
# unhead & backslash ?
