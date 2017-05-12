#! /usr/bin/perl -wT

use strict; use warnings;
use Test::More tests => 22;                   BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};
use Text::Glob::DWIW qw':all';
my $p; my @v;

my $sec='quant & neg';
is_deeply [tg_expand $p='{[abcd]#2,![abcd]#2}'],
          [tg_expand '{[abcd],![abcd]}'],"$sec: $p"; # '' or ()
$sec='examples';
is_deeply [map oct, tg_expand $p='0b[01]#8'],[0..255],"$sec: $p";      # 0..255 in binary
is_deeply [tg_expand $p='{abc}#0-1'],['','abc'],    "$sec: $p";        # optional
is_deeply [tg_expand $p='{abc}#1-0'],['abc',''],    "$sec: $p";        # optional
#is_deeply [tg_expand $p='[abc]#,1'], ['',qw'a b c'],"$sec: $p";        # optional
is_deeply [tg_expand $p='[abc]#0-1'],['',qw'a b c'],"$sec: $p";        # optional
is_deeply [tg_expand $p='[abc]#1-0'],[qw'a b c',''],"$sec: $p";        # optional
is_deeply [tg_expand $p='AB{inside comment}#0BA'],['ABBA'],"$sec: $p"; # comment
is_deeply [tg_expand $p=':[-]#0-8)'],[map ':'.('-'x$_).')',0..8],"$sec: $p"; # pinocchio
is_deeply [tg_expand $p='# {-=}#38-'],['# '.('-=' x 38).'-'],"$sec: $p";    # decoration line
is_deeply [tg_expand $p='[a]#10'],['aaaaaaaaaa'],"$sec: $p";           # by the doctor
is_deeply [tg_expand $p='{[a-d]#4,!{*[a-d]}##2*}'],
          [grep !/(.).*\1/,<{a,b,c,d}{a,b,c,d}{a,b,c,d}{a,b,c,d}>],,"$sec: $p";

$sec='dequoting';
is_deeply [tg_expand $p='{([_]#2-0\0)}##2\\\\2'],
          [qw'(__0)(__0)\\2 (_0)(_0)\\2 (0)(0)\\2'],"$sec: $p";
is_deeply [tg_expand $p='{([_]#2-0\0)}##2\\2'],
          [qw'(__0)(__0)2 (_0)(_0)2 (0)(0)2'],"$sec: $p";
is_deeply [tg_expand $p='{([_]#2-0\0)}##2\2'],
          [qw'(__0)(__0)2 (_0)(_0)2 (0)(0)2'],"$sec: $p";
is_deeply [tg_expand $p='{([_]#2-0\0)}##2\\'],
          [qw'(__0)(__0)\\ (_0)(_0)\\ (0)(0)\\'],"$sec: $p";
is_deeply [tg_expand $p='{([_]#2-0\0)}\##2\2'],
          ['(__0)##2\\2','(_0)##2\\2','(0)##2\\2'],"$sec: $p";
is_deeply [tg_expand $p='{([_]#2-0\0)}\##2'],
          ['(__0)##2','(_0)##2','(0)##2'],"$sec: $p";
is_deeply [tg_expand $p='[abc]#-1'], ['a#-1','b#-1','c#-1'],"$sec: $p";
is_deeply [tg_expand $p='[abc]#a'], ['a#a','b#a','c#a'],"$sec: $p";
is_deeply [tg_expand $p='[abc]#'], ['a#','b#','c#'],"$sec: $p";
# tg_expand '[_]#\\2' => '_#\\2', use '[_]\\#2' instead

$sec='opt'; $p='{a-c}#2,[1-3]##2';
subtest "quant-opt & rewrite: $p" =>
sub { plan tests => 12;
  my $rhomb3='{{a,b,c}{a,b,c}},{11,22,33}'; my $rhomb2='{a,b,c}#2,{11,22,33}';
  my $rhomb1='{{a,b,c}{a,b,c}},{1,2,3}##2'; my $rhomb0='{a,b,c}#2,{1,2,3}##2';
  is_deeply [tg_expand $p,{rewrite=>1,quant=>'##,#'}],[$rhomb3],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>'#,##'}],[$rhomb3],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>'###'}],[$rhomb3],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>1}],[$rhomb3],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>'true'}],[$rhomb3],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>'##'}],[$rhomb2],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>'##,##'}],[$rhomb2],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>'#'}],[$rhomb1],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>'#,#'}],[$rhomb1],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>''}],[$rhomb0],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>'0'}],[$rhomb0],"$sec: $p (opt1)";
  is_deeply [tg_expand $p,{rewrite=>1,quant=>0}],[$rhomb0],"$sec: $p (opt1)";
  done_testing;
};

had_no_warnings();