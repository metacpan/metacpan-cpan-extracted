#! /usr/bin/perl -wT

use strict; use warnings; use Config;
use Test::More tests => 53;                   BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};

use Text::Glob::DWIW qw':all';
my $p; my @v; my $sec='error';

is_deeply [tg_expand $p="{{]}"],["{]"],"$sec: ${p}";
is_deeply [tg_expand $p="{{a]}"],["{a]"],"$sec: ${p}";
is_deeply [tg_expand $p="{{aa]}"],["{aa]"],"$sec: ${p}";
is_deeply [tg_expand $p="{a{b,b"],[$p],"$sec: ${p}";
is_deeply [tg_expand $p="{{a{b,b}"],[qw'{{ab {{ab'],"$sec: ${p}";
is_deeply [tg_expand $p="{aa{aa}aa"],['{aaaaaa'],"$sec: ${p}";
is_deeply [tg_expand "{$p}"],['{aaaaaa'],"$sec: {$p}";
is_deeply [tg_expand $p="{a{b,c\\}d,e}"],[qw'{ab {ac}d {ae'],"$sec: ${p}";

for my $c (1..5)
{ for my $t (qw'{ } [ ] {] {a] [a} [}') # [a},[}&{}
  { subtest scalar('$sec: '."${t}_"x$c) => sub
    { plan tests => 3*12;
      for my $x ('','a','aa')
      { is_deeply [tg_expand $p="$t$x"x$c],[$p],"$sec: $p";
        is_deeply [tg_expand "${p}a"],["${p}a"],"$sec: ${p}a";
        is_deeply [tg_expand "a$p"],["a$p"],"$sec: a$p";
        is_deeply [tg_expand "a${p}a"],["a${p}a"],"$sec: a${p}a";
        #is_deeply [tg_expand "{${p}}"],[$p],"$sec: {${p}}";
        is_deeply [tg_expand "${p}{a}"],["${p}a"],"$sec: ${p}{a}";
        is_deeply [tg_expand "{a}$p"],["a$p"],"$sec: {a}$p";
        is_deeply [tg_expand "{a}${p}{a}"],["a${p}a"],"$sec: {a}${p}{a}";
        is_deeply [tg_expand "{a}{a}${p}{a}{a}"],["aa${p}aa"],"$sec: {a}{a}${p}{a}{a}";
        is_deeply [tg_expand "${p}{}"],[$p],"$sec: ${p}{}";
        is_deeply [tg_expand "{}$p"],[$p],"$sec: {}$p";
        is_deeply [tg_expand "{}${p}{}"],[$p],"$sec: {}${p}{}";
        ##is_deeply [tg_expand "${p}[]"],[$p],"$sec: ${p}[]";
        is_deeply [tg_expand "[]$p"],[$p],"$sec: []$p";
        ##is_deeply [tg_expand "[]${p}[]"],[$p],"$sec: []${p}[]";
        #is_deeply [tg_expand "{$p"],[],"$sec: $p}";
        #is_deeply [tg_expand "{$p"],[],"$sec: $p}";
      }
    }
  }
}

for my $c (1..5)
{ for my $t (qw'\{ \} [ ]  [a\}')#{] {a]
  { for my $x ('','a','aa')
    { #is_deeply [tg_expand "{${p}}"],[$p],"$sec: {${p}}";
      #is_deeply [tg_expand "{$p"],[],"$sec: $p}";
      #is_deeply [tg_expand "{$p"],[],"$sec: $p}";
    }
  }
}

$sec="single char";
subtest "single char fallthrough" => sub {
  plan tests => 256;
  for my $i (0..255)
  { my $p=chr $i; (my $pp=$p)=~s/[^[:print:]]//g;
    is_deeply [tg_expand $p],[$p],"$sec: $i $pp";
  }
};

$sec="double char";
subtest "double char fallthrough" => sub {
  plan tests => 255;
  for my $i (0..255)
  { next if $i==ord '\\'; # \\ => \
    my $p=chr $i; (my $pp=$p)=~s/[^[:print:]]//g;
    is_deeply [tg_expand "$p$p",{star=>0}],["$p$p"],"$sec: $i $pp";
  }
};

$sec="other";
is_deeply [tg_expand tg_expand $p='\{({_}#0-4)\}#2'],
    [qw'()() (_)(_) (__)(__) (___)(___) (____)(____)'],"$sec: $p (S-XXL) recall";
is_deeply [tg_expand tg_expand $p='{({_}#0-4)}##2'],
    [qw'()() (_)(_) (__)(__) (___)(___) (____)(____)'],"$sec: $p (S-XXL)";

had_no_warnings();
done_testing;