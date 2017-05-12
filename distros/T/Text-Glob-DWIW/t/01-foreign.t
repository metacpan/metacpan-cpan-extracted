#! /usr/bin/perl -Tw

use v5.10; use strict; use warnings;
use Test::More tests => 56;                   BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};
use Text::Glob::DWIW qw':all';
my $pkg; my $p;

#my $sec='rewrite to glob';
SKIP: { eval { require Text::Glob::Expand } or skip "TGE not avail",3;
  my $obj=tg_foreign $p='[[:card:]]#2' => $pkg='Text::Glob::Expand';
  my $r=$obj->explode; #my $first=$r->[0]->text;
  is int(@$r),58**2,"$pkg: size for $p";
  is $r->[0]->text,"\x{1f0a1}"x2,       "$pkg: 1. elem from $p";
  is $r->[1]->text,"\x{1f0a1}\x{1f0a2}","$pkg: 2. elem from $p";
}

#$sec='sent to index arith modules';
SKIP: { eval { require Set::CartesianProduct::Lazy } or skip "SCPL not avail",2;
   my $obj=tg_foreign $p='{1-100}#10', $pkg='Set::CartesianProduct::Lazy';
   is $obj->count,1e20,"$pkg: size for $p";
   is_deeply [$obj->get(1234567890)],[qw'1 1 1 1 1 13 35 57 79 91'],
         "S-CP-L: 1234567890. elem from $p";
}
SKIP: { eval { require List::Gen } or skip "List::Gen not avail",2;
   my $obj=tg_foreign $p='{1-100}#10', $pkg='List::Gen';
   is $obj->size,1e20,"$pkg: size for $p";
   is_deeply [$obj->get(1234567890)],[qw'1 1 1 1 1 13 35 57 79 91'],"$pkg: 1234567890. elem";
}

#$sec='self incr modules';
SKIP: { eval { require Set::CrossProduct } or skip "Set::CrossProduct not avail",3;
   my $obj=tg_foreign $p='{1-100}#10', $pkg='Set::CrossProduct';
   is defined($obj)&&$obj->cardinality,1e20,"$pkg: size for $p";
   is_deeply [$obj->get],[qw'1 1 1 1 1 1 1 1 1 1'],"$pkg: 1. elem from $p";
   is_deeply [$obj->get],[qw'1 1 1 1 1 1 1 1 1 2'],"$pkg: 2. elem from $p";
}

SKIP: { eval { require Iterator::Array::Jagged } or skip "Iterator::Array::Jagged not avail",1;
   my $obj=tg_foreign $p='{1-100}#10', $pkg='Iterator::Array::Jagged';
   is_deeply [$obj->next],[qw'1 1 1 1 1 1 1 1 1 1'],"$pkg: 1. elem from $p";
   #is_deeply [$obj->next],[qw'2 1 1 1 1 1 1 1 1 1'],"$pkg: 2. elem from $p"; # !ordered
}

SKIP: { eval { require Math::Cartesian::Product } or
             skip "Math::Cartesian::Product not avail",3;
  my @r=tg_foreign $p='[[:card:]]#2' => $pkg='Math::Cartesian::Product';
  is int(@r),58**2,"$pkg: size for $p"; my ($first,$second)=map {join'',@$_ } @r[0,1];
  is $first, "\x{1f0a1}"x2,       "M-C-P: 1. elem from $p";
  is $second,"\x{1f0a1}\x{1f0a2}","M-C-P: 2. elem from $p";
}

#$sec='iterators';
SKIP: { eval { require HOP::Stream } or skip "HOP::Stream not avail",2;
   my $obj=tg_foreign $p='{1-100}#10',{chunk=>1}, $pkg='HOP::Stream';
   is_deeply $obj->drop,[qw'1 1 1 1 1 1 1 1 1 1'],"$pkg: 1. elem from $p";
   is_deeply $obj->drop,[qw'1 1 1 1 1 1 1 1 1 2'],"$pkg: 2. elem from $p";
}

SKIP: { eval { require Iterator } or skip "Iterator not avail",2;
   my $obj=tg_foreign $p='{1-100}#10',{chunk=>1}, $pkg='Iterator';
   is_deeply $obj->value,[qw'1 1 1 1 1 1 1 1 1 1'],"$pkg: 1. elem from $p";
   is_deeply $obj->value,[qw'1 1 1 1 1 1 1 1 1 2'],"$pkg: 2. elem from $p";
}

#$sec='own iters';
my $code=tg_foreign $p='{1-100}#10',{chunk=>1}, $pkg='CODE';
is_deeply [$code->()],      [qw'1 1 1 1 1 1 1 1 1 1'],"$pkg: 1. elem from $p";
is_deeply scalar($code->()),[qw'1 1 1 1 1 1 1 1 1 2'],"$pkg: 2. elem from $p";
$code=tg_foreign $p='[a-d]',{chunk=>1}, 'CODE'; my @v=();my $i=0;
++$i while $i<10 && @v<push @v,$code->()//();
is_deeply \@v,[map [$_],qw'a b c d'],"$pkg: elems from $p";
is $i,4,"$pkg: correct stop from $p";
$code=tg_foreign $p='[a-d]', 'CODE'; @v=();$i=0;
++$i while $i<10 && @v<push @v,$code->()//();
is_deeply \@v,[qw'a b c d'],"$pkg\$: elems from $p";
is $i,4,"$pkg\$: correct stop from $p";

my $sr=tg_foreign $p='{1-100}#10', $pkg='REF';
is $sr->size,1e20,"$pkg: size for $p (->)";
is int($sr),1e20,"$pkg: size for $p";
is        $$sr,  '1111111111',            "$pkg: 1. elem from $p";
is_deeply \@$sr,[qw'1 1 1 1 1 1 1 1 1 2'],"$pkg: 2. elem from $p";

{ my $i1=tg_foreign $p='{1-100}#10', $pkg='++';
  is int($i1),1e20,"$pkg: size for $p";
  is $i1->size,1e20,"$pkg: size for $p (2)";
  is ${$i1++},'1111111111',"$pkg: 1. elem from $p";
  is ${$i1++},'1111111112',"$pkg: 2. elem from $p";
}
{ my $i1=tg_expand_lazy $p='{1-100}#10';
  is int($i1),1e20,"lazy: size for $p";
  is $i1->size,1e20,"lazy: size for $p (2)";
  is ${$i1++},'1111111111',"lazy: 1. elem from $p";
  is ${$i1++},'1111111112',"lazy: 2. elem from $p";
}
{ my $i1=tg_expand_lazy $p='{,,,}';
  is int($i1),4,"lazy: size for $p";
  is $i1->size,4,"lazy: size for $p (2)"; @v=(); $i=10;
  push @v,$$i1 while $i-- && ++$i1;
  is_deeply \@v, [('')x4],"lazy: $p";
}
{ my $i1=tg_expand_lazy $p='{,,,}';
  is_deeply [int($i1),$i1->size],[4,4],"lazy<>: size for $p"; @v=(); $i=10;
  while (defined(my$v=<$i1>)) { push @v,$v }
  is_deeply \@v, [('')x4],"lazy<>: $p";
}
{ @v=(); my @r=qw'a1 a2 b1 b2 c1 c2 d1 d2';
  my $i1=tg_expand_lazy $p='[abcd][12]', CALL => sub { push @v, $_ };
  is_deeply [int($i1),$i1->size, int(@v)],[8,8,8],"CALL: size for $p";
  is_deeply \@v, \@r,"CALL: $p"; @v=();
  $i1=tg_expand_lazy $p='[abcd][12]', CALL => sub { push @v, $$_ };
  is_deeply \@v, \@r,"CALL\$: $p"; @v=();
  $i1=tg_expand_lazy $p='[abcd][12]', CALL => sub { push @v, "$_" };
  is_deeply \@v, \@r,"CALL\": $p";
}

my $i2=tg_foreign $p='[a-d]', '++'; @v=();$i=-1;
push @v,$$i2 while ++$i<10 && ++$i2;
is_deeply \@v,[qw'a b c d'],"$pkg: elems from $p";
is $i,4,"$pkg: correct stop from $p";
$i2=tg_foreign $p='[a-d]', '++'; @v=();$i=-1;
1 while ++$i<10 && @v<push @v,${$i2++}//();
is_deeply \@v,[qw'a b c d'],"$pkg: elems from $p";
is $i,4,"$pkg: correct stop from $p";
$i2=tg_foreign $p='[a-d]', '++'; @v=();$i=-1;
1 while ++$i<10 && @v<push @v,@{$i2} ? \@{$i2++} : ();
is_deeply \@v,[map [$_],qw'a b c d'],"$pkg: elems from $p";
is $i,4,"$pkg: correct stop from $p";

had_no_warnings();

#-- up here: foreign modules with warnings in it (even when no warnings pragma)
SKIP: { eval { no warnings 'deprecated'; require Iterator::Simple } or
              skip "Iterator::Simple not avail",2;
   my $obj=tg_foreign $p='{1-100}#10',{chunk=>1}, $pkg='Iterator::Simple';
   is_deeply scalar($obj->next),[qw'1 1 1 1 1 1 1 1 1 1'],"$pkg: 1. elem from $p";
   is_deeply scalar($obj->next),[qw'1 1 1 1 1 1 1 1 1 2'],"$pkg: 2. elem from $p";
}

SKIP: { eval { no warnings 'deprecated'; require Iterator::Simple::Lookahead } or
              skip "Iterator::Simple::Lookahead not avail",2;
   my $obj=tg_foreign $p='{1-100}#10', $pkg='Iterator::Simple::Lookahead';
   is scalar($obj->next),'1111111111',"$pkg: 1. elem from $p";
   is scalar($obj->next),'1111111112',"$pkg: 2. elem from $p";
}

#done_testing;