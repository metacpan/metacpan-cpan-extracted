#! /usr/bin/perl -wT
# Stuff what needs Test::Exception
# mostly: Options handling which is not tested anywhere else.

use v5.10; use strict; use warnings;
use Test::More; use Config;                   BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};
BEGIN { eval { require Test::Exception; 'Test::Exception'->import() } }
plan skip_all => 'Test::Exception needed' unless 'Test::Exception'->can('throws_ok');
plan tests => 60;
use Text::Glob::DWIW qw':all';

my $sec='unknown'; my $p;
throws_ok { tg_expand '{foo,bar}',{blabla=>23} } qr/^Useless call/,
          "$sec: void context";
throws_ok { my $dummy=tg_expand '{foo,bar}',{blabla=>23} } qr/Unknown option 'blabla'/,
          "$sec: Unknown option";

$sec='break';
for my $pi (qw'[a-y] {a-y} {aaaaa-aaaay} {0-24} {00-24}  {0-48-2} {00-72-3}  {a-aw-2}
               {0-4}{0-4} [0-4][0-4] [01234][01234]','{0-4}#2','[0-4]#2','[01234]#2')
{ is scalar(tg_expand($pi,{break=>25})->elems),25,"$sec: $pi (b=25)";
  throws_ok { my $dummy=tg_expand $pi,{break=>23} } qr/\btoo much\b/i, "$sec: $pi (b=23)";
}
for my $pi ('{![a-y]}', '{[a-y],![a-y]}')
{ cmp_ok scalar(tg_expand($pi,{break=>25})->elems),'<=',1,"$sec: $pi (b=25)";
  throws_ok { my $dummy=tg_expand $pi,{break=>23} } qr/\btoo much\b/i, "$sec: $pi (b=23)";
}
SKIP: { skip "not under EBCDIC",1 if exists $Config{ebcdic} && $Config{ebcdic};
  throws_ok { my $dummy=tg_expand '{A-\\\\}',{break=>23} } qr/\btoo much\b/i,
              "$sec: {A-\\\\}";
}
is_deeply [tg_expand $p='[a-z]',{break=>26}],['a'..'z'],"$sec: $p (b=26)";
throws_ok { my $dummy=tg_expand '{a-aa}',{break=>26} } qr/\btoo much\b/i,
          "$sec: {a-aa} (b=26)"; #

cmp_ok int(tg_expand $p='{[ab],![ab]}',{break=>2}),'<=',1,"$sec: $p (b=2)";
throws_ok { my $dummy=tg_expand '{[ab],![abc]}',{break=>2} } qr/\btoo much\b/i,
          "$sec: -\"- (b=2)";

$sec='stepsize:';
#... XXX
is_deeply [tg_expand $p='{1-100-100}',{stepsize=>-10,break=>10}],[1],"$sec: $p";
throws_ok { my $dummy=tg_expand '{1-100-100}',{stepsize=>-10,break=>9} }
   qr/\btoo much\b/i, "$sec: -\"- (ssz=-10 b=9)";
is_deeply [tg_expand '{1-10-2}',{break=>5,stepsize=>0}],[1,3,5,7,9],"$sec: $p 0";
is_deeply [tg_expand '{1-10-2}',{break=>5,stepsize=>''}],[1,3,5,7,9],"$sec: $p ''";
is_deeply [tg_expand '{1-10-2}',{break=>5}],[1,3,5,7,9],"$sec: $p -";
is_deeply [tg_expand '{1-10-2}',{break=>5,stepsize=>2}],[1,3,5,7,9],"$sec: $p 2";
is_deeply [tg_expand '{1-10-2}',{break=>5,stepsize=>-2}],[1,3,5,7,9],"$sec: $p -2";
is_deeply [tg_expand '{1-10-2}',{break=>10,stepsize=>-1}],[1,3,5,7,9],"$sec: $p -1";
throws_ok { my $dummy=tg_expand '{1-10-2}',{break=>10,stepsize=>1}} qr/\btoo wide\b/i,
          "$sec: -\"- 1,10";
throws_ok { my $dummy=tg_expand '{1-10-2}',{break=>5,stepsize=>-1}} qr/\btoo much\b/i,
          "$sec: -\"- -1,5";
throws_ok { my $dummy=tg_expand '{1-10-2}',{break=>10,stepsize=>undef}} qr/\btoo much\b/i,
          "$sec: -\"- undef,10";
is int(tg_expand $p='{1-10-2}',{stepsize=>undef}),102,"$sec: $p undef";
# tg_expand '{a-z-25}',{stepsize=>-1}"
#  tg_expand '{a-z-25}',{stepsize=>-12}"
#

$sec='break big';
throws_ok { my $dummy=tg_expand '[0123][0123][0123][0123][0123]',{break=>1000} }
          qr/\btoo much\b/i, "$sec: [0123]x5 (b=1000)";
throws_ok { my $dummy=tg_expand '{aaaaa-bbbbb}',{break=>1000} } qr/\btoo much\b/i,
          "$sec: {aaaaa-bbbbb} (b=1000)";
throws_ok { my $dummy=tg_expand '[a-z][a-z][a-z]',{break=>1000} } qr/\btoo much\b/i,
          "$sec: [a-z][a-z][a-z] (b=1000)";
throws_ok { my $dummy=tg_expand '[a-z]#3',{break=>1000} } qr/\btoo much\b/i,
          "$sec: [a-z]#3 (b=1000)";
throws_ok { my $dummy=tg_expand '[a-z]#0-3',{break=>1000} } qr/\btoo much\b/i,
          "$sec: [a-z]#,3 (b=1000)";

$sec="ouside scope";
my $def=tg_options;
subtest $sec => sub { plan tests => 4;
  {no Text::Glob::DWIW;
   #package maid; use strict; use warnings; use Test::Exception;
   { use Text::Glob::DWIW ':all' };
   throws_ok { tg_options {} } qr/scope of use/i,"$sec: { }";
   use Text::Glob::DWIW ();
   throws_ok { Text::Glob::DWIW::tg_options {} } qr/scope of use/i,"$sec: ()";
   eval "use Text::Glob::DWIW ':all'";
   throws_ok { tg_options {} } qr/scope of use/i,"$sec: eval";
  }
  is_deeply scalar tg_options,$def,"$sec: l0";
};

$sec='use & no';
subtest $sec => sub { plan tests => 4;
  use Text::Glob::DWIW { case => 2 };
  is tg_options->{case},2,"$sec: case=>2";
  { no Text::Glob::DWIW;
    throws_ok { my $dummy=Text::Glob::DWIW::tg_options } qr/scope of use/i,"$sec: no inner";
  }
  is tg_options->{case},2,"$sec: case=>2 back";
  no Text::Glob::DWIW;
  throws_ok { my $dummy=Text::Glob::DWIW::tg_options } qr/scope of use/i,"$sec: no end";
};

$sec='use & no (short)';
use Text::Glob::DWIW ':use';
subtest $sec => sub { plan tests => 4;
  use TGDWIW { case => 2 };
  is tg_options->{case},2,"$sec: case=>2";
  { no TGDWIW;
    throws_ok { my $dummy=Text::Glob::DWIW::tg_options } qr/scope of use/i,"$sec: no inner";
  }
  is tg_options->{case},2,"$sec: case=>2 back";
  no TGDWIW;
  throws_ok { my $dummy=Text::Glob::DWIW::tg_options } qr/scope of use/i,"$sec: no end";
};

had_no_warnings();