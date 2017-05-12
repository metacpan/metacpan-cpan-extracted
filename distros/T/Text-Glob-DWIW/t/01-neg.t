#! /usr/bin/perl -wT

use strict; use warnings; use Config;
use Test::More tests => 42;                   BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};
use Text::Glob::DWIW qw':all';
my $p; my @v; my $sec='expand';

is_deeply [tg_expand $p='oo{01-04,!02-03}'],
          [qw'oo01 oo04'],"$sec: $p";
is_deeply [tg_expand $p='oo{01-04,!02}'],
          [qw'oo01 oo03 oo04'],"$sec: $p";
is_deeply [tg_expand $p='oo{01-04,!01}'],
          [qw'oo02 oo03 oo04'],"$sec: $p";
is_deeply [tg_expand $p='oo{01-04,!04}'],
          [qw'oo01 oo02 oo03'],"$sec: $p";
is_deeply [tg_expand $p='oo{01-04,!00}'],
          [qw'oo01 oo02 oo03 oo04'],"$sec: $p";
is_deeply [tg_expand $p='{oo{{x}{01-04},!x02-x03}}'],
          [qw'oox01 oox04'],"$sec: $p";
is_deeply [tg_expand $p='{oo{{x}{01-04},!{x02-x03}}}'],
          [qw'oox01 oox04'],"$sec: $p";
is_deeply [tg_expand $p='{oo{{x}{01-04},!x{02-03}}}'],
          [qw'oox01 oox04'],"$sec: $p";

is_deeply [tg_expand $p='{{00-20},!{[01][13579]}}'],
          [qw'00 02 04 06 08 10 12 14 16 18 20'],"$sec: $p";
is_deeply [tg_expand $p='{{0-120},!{*[13579]}}'],
          [map $_*2,0..60],"$sec: $p";

is_deeply [tg_expand $p='{0-20,!*[13579]}'],[map 2*$_,0..10], "$sec: p";
is_deeply [tg_expand $p='{{0-20},!{*[13579]}}'],[map 2*$_,0..10], "$sec: p";
TODO: { local $TODO='*[part of pattern]';
  is_deeply [tg_expand '{{0-20},!{*[13579]}}',{minus=>0}],
            [0..20,qw'!11 !13 !15 !17 !19'], "$sec: $p (!=0)"; # fail
}
is_deeply [tg_expand '{0-20,!{*1,*3,*5,*7,*9}}',{minus=>0}],
          [0..20,qw'!11 !13 !15 !17 !19'], "$sec: $p (!=0)"; # new
is_deeply [tg_expand '{{0-20},!{*[13579]}}',{minus=>0,star=>0}],
          [0..20,qw'!*1 !*3 !*5 !*7 !*9'], "$sec: $p (!=0,*=0)";
is_deeply [tg_expand '{{0-20},!{*[13579]}}',{minus=>0,range=>0,star=>0}],
          [qw'0-20 !*1 !*3 !*5 !*7 !*9'], "$sec: $p (!=0,*=0,r=0)";


is_deeply [tg_expand $p='oo{1-4,!2-3}'],
          [qw'oo1 oo4'],"$sec: $p";
is_deeply [tg_expand $p='oo{1-4,!{2-3}}'],
          [qw'oo1 oo4'],"$sec: $p";
is_deeply [tg_expand $p='oo{1-4,!{2,3}}'],
          [qw'oo1 oo4'],"$sec: $p";
is_deeply [tg_expand $p='oo{1-4,![2-3]}'],
          [qw'oo1 oo4'],"$sec: $p";
is_deeply [tg_expand $p='oo{1-4,![23]}'],
          [qw'oo1 oo4'],"$sec: $p";

is_deeply [tg_expand $p='!oo{1-4,![23]}'],
          [qw'!oo1 !oo4'],"$sec: $p";
is_deeply [tg_expand $p='!'],
          ['!'],"$sec: $p";
ok do{ @v=tg_expand($p='{!}'); @v==0 || @v==1 && $v[0]eq'' },"$sec: $p";
ok do{ @v=tg_expand($p='{,!}'); @v==0 || @v==1 && $v[0]eq'' },"$sec: $p";
ok do{ @v=tg_expand($p='{a,!a}'); @v==0 || @v==1 && $v[0]eq'' },"$sec: $p";
TODO: { local $TODO="() preferable over ''";
  is_deeply [tg_expand $p='{!}'],   [],"$sec: $p"; # TODO: () preferable
  is_deeply [tg_expand $p='{,!}'],  [],"$sec: $p";
  is_deeply [tg_expand $p='{a,!a}'],[],"$sec: $p";
}

is_deeply [tg_expand $p='{a{b{r{a{c{a{d{a{b{r{a,},},},},},},},},},},!abrac}'],
   [qw'abracadabra abracadabr abracadab abracada abracad abraca abra abr ab a'],
   "$sec: $p";

is_deeply [tg_expand $p='{a{b{r{a{c{a{d{a{b{r{a,},},},},},},},},},},!a*a}'],
   [qw'abracadabr abracadab abracad abrac abr ab a'], "$sec: $p";
is_deeply [tg_expand $p='{a{b{r{a{c{a{d{a{b{r{a,},},},},},},},},},},!?????*}'],
   [qw'abra abr ab a'], "$sec: $p";
is_deeply [tg_expand $p='{a{b{r{a{c{a{d{a{b{r{a,},},},},},},},},},},!?{,?}{,??}}'],
   [qw'abracadabra abracadabr abracadab abracada abracad abraca abrac'],"$sec: $p";

is_deeply [tg_expand '{0{[01][01],!10,10},1{[10][01],!00,00}}'],
   [qw'000 001 011 010 110 111 101 100'], "$sec: GrayCode";

is_deeply [tg_expand '{[01][01][01][01],!01{01,1?},!10{0?,10}}'],
   [qw'0000 0001 0010 0011 0100 1011 1100 1101 1110 1111'], "$sec: Aiken";

is_deeply [tg_expand $p='{[abc][abc][abc],!*{a*a,b*b,c*c}*}'],
          [qw'abc acb bac bca cab cba'],"$sec: $p";
is int(tg_expand $p='{[a-d][a-d][a-d][a-d],!*{a*a,b*b,c*c,d*d}*}'),24,"$sec: $p";

SKIP: { skip "not under EBCDIC",2 if exists $Config{ebcdic} && $Config{ebcdic};
  is_deeply [tg_expand $p='{\!-0,!!-/}'], [0], "$sec: $p";
  is_deeply [tg_expand $p='{\!-0,!\!-/}'],[0], "$sec: $p";
}

$sec="\\\\ & ?";
is_deeply [tg_expand $p='{\\\\c,!\\\\?}'],[''],"$sec: $p";
is_deeply [tg_expand $p='{\\\\c,!\\\\?}'],[''],"$sec: $p";

had_no_warnings();