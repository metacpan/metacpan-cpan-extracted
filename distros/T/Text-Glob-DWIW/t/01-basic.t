#! /usr/bin/perl -wT

use strict; use warnings; use Config;
use Test::More tests => 148+105;              BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};

use Text::Glob::DWIW qw':all';
my $p; my @v; my $sec='expand';

is_deeply [tg_expand $p='foo_{bar_,boo{a,b}_}baz'],
          ["foo_bar_baz", "foo_booa_baz", "foo_boob_baz"],"$sec: $p";
is_deeply [tg_expand $p='foo_{bar_,boo{a,b,}_}baz'],
          ["foo_bar_baz", "foo_booa_baz", "foo_boob_baz", "foo_boo_baz"],"$sec: $p";

is_deeply [tg_expand $p='a{b{r{a{c{a{d{a{b{r{a,},},},},},},},},},}'],
   [qw'abracadabra abracadabr abracadab abracada abracad abraca abrac abra abr ab a'],
   "$sec: $p";
for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ is_deeply [$f->($p='{foo,bar}')],  [qw'foo bar'], "$sec: $p";
  is_deeply [$f->([qw'foo bar'])],   [qw'foo bar'], "$sec: [qw'foo bar']";
  is_deeply [$f->(qw'foo bar')],     [qw'foo bar'], "$sec: qw'foo bar'";
  is_deeply [$f->($p='foo,bar')],    ['foo,bar'],   "$sec: $p";
  is_deeply [$f->($p='{{{{a,b,c}}}}')],[qw'a b c'], "$sec: $p";
  is_deeply [$f->($p='{{{{a}}}}')],  ['a'],         "$sec: $p";
  is_deeply [$f->($p='{y{a-c}}')],   [qw'ya yb yc'],"$sec: $p"; #hang under 5.10
  is_deeply [$f->($p='{{a-c}y}')],   [qw'ay by cy'],"$sec: $p"; #
  is_deeply [$f->($p='{y,{a-c}}')],  [qw'y a b c'], "$sec: $p"; #
  is_deeply [$f->($p='{{a-c},y}')],  [qw'a b c y'], "$sec: $p"; #
  is_deeply [$f->($p='{{{[abc]}}}')],[qw'a b c'],   "$sec: $p";
  is_deeply [$f->($p='{{{[a]}}}')],  ['a'],         "$sec: $p";
  is_deeply [$f->($p='{y[a-c]}')],   [qw'ya yb yc'],"$sec: $p"; #
  is_deeply [$f->($p='{[a-c]y}')],   [qw'ay by cy'],"$sec: $p"; #
  is_deeply [$f->($p='{y,[a-c]}')],  [qw'y a b c'], "$sec: $p"; #
  is_deeply [$f->($p='{[a-c],y}')],  [qw'a b c y'], "$sec: $p"; #
  is_deeply [$f->($p='{y[aaa]}')],   [qw'ya ya ya'],"$sec: $p"; #
  is_deeply [$f->($p='{[aaa]y}')],   [qw'ay ay ay'],"$sec: $p"; #
  is_deeply [$f->($p='{y,[aaa]}')],  [qw'y a a a'], "$sec: $p"; #
  is_deeply [$f->($p='{[aaa],y}')],  [qw'a a a y'], "$sec: $p"; #
  is_deeply [tg_expand $p='{a[,_]}'],['a,','a_'],   "$sec: $p";
  is_deeply [tg_expand $p='{a[_,]}'],['a_','a,'],   "$sec: $p";
  is_deeply [tg_expand $p='{[,_]a}'],[',a','_a'],   "$sec: $p";
  is_deeply [tg_expand $p='{[_,]a}'],['_a',',a'],   "$sec: $p";
  #{a[,_]} fail 'a[' '_]' instead of 'a,' 'a]'
  # {[,_]} a{[,_]} just fine
  is_deeply [tg_expand $p='a{[,_]}'],['a,','a_'],   "$sec: $p";
  is_deeply [tg_expand $p='a{[_,]}'],['a_','a,'],   "$sec: $p";
}

for my $e (qw'{} [] {!}')
{ is_deeply [tg_expand $p="${e}foobar"],['foobar'],"$sec: $p";
  is_deeply [tg_expand $p="foobar$e"],['foobar'],"$sec: $p";
  is_deeply [tg_expand $p="foo${e}bar"],['foobar'],"$sec: $p";
  is_deeply [tg_expand $p="fo${e}o${e}b${e}ar"],['foobar'],"$sec: $p";
  is_deeply [tg_expand $p="fo{o${e}b}ar"],['foobar'],"$sec: $p";
}
for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ is_deeply [$f->($p='foobar')],['foobar'],"$sec: $p";
  is_deeply [$f->($p='fo{o}bar')],['foobar'],"$sec: $p";
  is_deeply [$f->($p='fo[o]bar')],['foobar'],"$sec: $p";
  is_deeply [$f->($p='{,a,b,!}')],[qw'a b'],"$sec: $p";
  is_deeply [$f->($p='{,a,b,!}q')],[qw'aq bq'],"$sec: $p";
  is_deeply [$f->($p='{a,b,!}q')],[qw'aq bq'],"$sec: $p";
  is_deeply [$f->($p='{,!,a,b}q')],[qw'aq bq'],"$sec: $p";
  is_deeply [$f->($p='{,!}q')],['q'],"$sec: $p";

  is_deeply [$f->($p='[\]]')],[']'],"$sec: $p";
  is_deeply [$f->($p='\]')],[']'],"$sec: $p";
  is_deeply [$f->($p='[\]]')],[']'],"$sec: $p";

  is_deeply [$f->($p='\]')],[']'],"$sec: $p";
  is_deeply [$f->($p='[\]]')],[']'],"$sec: $p";
  is_deeply [$f->($p='\[')],['['],"$sec: $p";
  is_deeply [$f->($p='[\[]')],['['],"$sec: $p";
}

for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ is_deeply [$f->($p='[')],['['],"$sec: $p";
  is_deeply [$f->($p='[\[\]]')],[qw'[ ]'],"$sec: $p";
  is_deeply [$f->($p='[\]\[]')],[qw'] ['],"$sec: $p";
  is_deeply [$f->($p='[\[\-\]]')],[qw'[ - ]'],"$sec: $p";
  is_deeply [$f->($p='[\]\-\[]')],[qw'] - ['],"$sec: $p";
  is_deeply [$f->($p='[[-\]]')],[qw'[ \\ ]'],"$sec: $p";
  is_deeply [$f->($p='[\[-\]]')],[qw'[ \\ ]'],"$sec: $p";
  is_deeply [$f->($p='[\]-\[]')],[qw'] \\ ['],"$sec: $p";
  is_deeply [$f->($p='[[]')],['['],"$sec: $p";
  is_deeply [$f->($p='[]\]')],[qw']'],"$sec: $p";
  is_deeply [$f->($p='[]]')],[qw']'],"$sec: $p";
}
for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ is_deeply [$f->($p="\n")], ["\n"], "$sec: NL";
  is_deeply [$f->($p='$')], ['$'], "$sec: $p";
  is_deeply [$f->($p="[\n]")], ["\n"], "$sec: [NL]";
  is_deeply [$f->($p="[\na]")], ["\n",'a'], "$sec: NL+a";
  is_deeply [$f->($p="[\n\t]")], ["\n","\t"], "$sec: NL+TAB";
  is_deeply [$f->($p="{\n}")], ["\n"], "$sec: {NL}";
  is_deeply [$f->($p="{\n,a}")], ["\n",'a'], "$sec: NL+a";
  is_deeply [$f->($p="{\n,\t}")], ["\n","\t"], "$sec: NL+TAB";
}
for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ is_deeply [$f->($p="a{}")], [qw'a'], "$sec: $p";
  is_deeply [$f->($p="a{,}")], [qw'a a'], "$sec: $p";
  is_deeply [$f->($p="a{,,}")], [qw'a a a'], "$sec: $p";
  is_deeply [$f->($p="{,,}a")], [qw'a a a'], "$sec: $p";
  is_deeply [$f->($p="a{,,}b")], [qw'ab ab ab'], "$sec: $p";
  is_deeply [$f->($p="a{,b}")], [qw'a ab'], "$sec: $p";
  is_deeply [$f->($p="a{,b,}")], [qw'a ab a'], "$sec: $p";
  is_deeply [$f->($p="a{,bb}")], [qw'a abb'], "$sec: $p";
  is_deeply [$f->()], [], "$sec: ()";
  is_deeply [$f->($p="{}")], [''], "$sec: $p"; # or nil is a kind of view/definition
  is_deeply [$f->($p=" {}")], [' '], "$sec: $p"; # but should be the same for [] & {} :(
  is_deeply [$f->($p="{}")],[$f->($p="[]")];
  is_deeply [$f->($p="[]")], [''], "$sec: $p"; # or '' is a kind of view/definition
  is_deeply [$f->($p=" []")], [' '], "$sec: '$p'";
  is_deeply [$f->($p="[abb]")], [qw'a b b'], "$sec: $p";
  is_deeply [$f->($p="[aA]B[cC]")], [qw'aBc aBC ABc ABC'], "$sec: $p";
  is_deeply [$f->($p="a{bb,bbb,bbbb}")], [qw'abb abbb abbbb'], "$sec: $p";
  is_deeply [$f->($p="a{bb,bbb,bbbb}")], [qw'abb abbb abbbb'], "$sec: $p";
  is_deeply [$f->($p='1234567890[i]')],['1234567890i'], "$sec: $p";
}

for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ is_deeply [$f->($p='_{aa,bb}.{11,22,33}_')],
            [qw'_aa.11_ _aa.22_ _aa.33_ _bb.11_ _bb.22_ _bb.33_'], "$sec: $p";
  is_deeply [$f->($p='_{aa,bb,cc}.{11,22}_')],
            [qw'_aa.11_ _aa.22_ _bb.11_ _bb.22_ _cc.11_ _cc.22_'], "$sec: $p";
}

is_deeply [tg_expand $p='[a-c][-=+][0-2]'],
          [qw'a-0 a-1 a-2  a=0 a=1 a=2  a+0 a+1 a+2',
           qw'b-0 b-1 b-2  b=0 b=1 b=2  b+0 b+1 b+2',
           qw'c-0 c-1 c-2  c=0 c=1 c=2  c+0 c+1 c+2'],"$sec: $p";

is_deeply [tg_expand $p='{Granny Smith,Washington,Golden Delicious}, {Navel,Florida}'],
        ['Granny Smith, Navel','Granny Smith, Florida',
         'Washington, Navel','Washington, Florida',
         'Golden Delicious, Navel','Golden Delicious, Florida'],"$sec: apples & oranges";

is_deeply [sort +tg_expand $p='a{b,c}d{e,,f}{g,h,}'],
  [sort +qw'abdeg abdg abdfg  abdeh abdh abdfh  abde abd abdf
            acdeg acdg acdfg  acdeh acdh acdfh  acde acd acdf'], "$sec: $p";
is_deeply [tg_expand $p='{a,{b{d{}}e,f,,},c}{,g{{}h,i}}'],[<{a,{b{d{}}e,f,,},c}{,g{{}h,i}}>],
    "$sec: $p"; # aka 4+3 nested bracketed blocks
#i: '(?:a|(?:b(?:d(?:))e|f||)|c)(?:|g(?:(?:)h|i))',
#   '4+3 nested bracketed blocks'); # most likely correct, but i don't walk through mentally.

$sec='powerset';
is_deeply [tg_expand $p='{1,}{2,}{3,}'],[@v=(123, 12, 13, 1, 23, 2, 3, '')],"$sec: $p";
is_deeply [tg_expand $p='{1}#1-0{2}#1-0{3}#1-0'],\@v,"$sec: $p";
is_deeply [tg_expand $p='{,1}{,2}{,3}'],[@v=reverse @v],"$sec: $p";
is_deeply [tg_expand $p='{1}#0-1{2}#0-1{3}#0-1'],\@v,"$sec: $p";

$sec='cross empty';
for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ subtest $sec => sub { plan tests => 12;
    is_deeply [$f->($p='{a,b}{}')],  [qw'a b'],"$sec: $p";
    is_deeply [$f->($p='{}{a,b}')],  [qw'a b'],"$sec: $p";
    is_deeply [$f->($p='{}{a,b}{}')],[qw'a b'],"$sec: $p";
    is_deeply [$f->($p='{a,b}[]')],  [qw'a b'],"$sec: $p";
    is_deeply [$f->($p='[]{a,b}')],  [qw'a b'],"$sec: $p";
    is_deeply [$f->($p='[]{a,b}[]')],[qw'a b'],"$sec: $p";
    is_deeply [$f->($p='[ab]{}')],  [qw'a b'],"$sec: $p";
    is_deeply [$f->($p='{}[ab]')],  [qw'a b'],"$sec: $p";
    is_deeply [$f->($p='{}[ab]{}')],[qw'a b'],"$sec: $p";
    is_deeply [$f->($p='[ab][]')],  [qw'a b'],"$sec: $p";
    is_deeply [$f->($p='[][ab]')],  [qw'a b'],"$sec: $p";
    is_deeply [$f->($p='[][ab][]')],[qw'a b'],"$sec: $p";
    done_testing;
  }
}

$sec='expand *';
for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ is_deeply [$f->($p='{aaa,aaaaa,aaaaaaa,bbbbbbb,*}')],
            [ qw'aaa aaaaa aaaaaaa bbbbbbb aaaaaaa'],"$sec: $p";
  is_deeply [$f->($p='{aaa,aaaaa,bbbbbbb,aaaaaaa,*}')],
            [ qw'aaa aaaaa bbbbbbb aaaaaaa bbbbbbb'],"$sec: $p";
  is_deeply [$f->($p='{aaa,aaaaaaa,bbbbbbb,ss{aa*2}}','aaa[1-3]')],
            [ qw'aaa aaaaaaa bbbbbbb ssaaa2 aaa1 aaa2 aaa3' ],"$sec: $p";
  is_deeply [$f->($p='{aaa,aaaaaaa,bbbbbbb,ss{aa*}}','aaa[1-3]')],
            [ qw'aaa aaaaaaa bbbbbbb ssaaaaaaa aaa1 aaa2 aaa3' ],"$sec: $p (order)";
  is_deeply [$f->($p='{aaa,aaaaaaa,bbbbbbb,ss{aa*9}}','aaa[1-3]')],
            [ qw'aaa aaaaaaa bbbbbbb ssaa*9 aaa1 aaa2 aaa3' ],"$sec: $p";
  is_deeply [$f->($p='\*{\,,\},\{}')],[ '*,', '*}', '*{' ],"$sec: $p";
}

$sec='tree expand';
is_deeply [tg_expand $p='foo_{bar_,boo{a,b}_}baz',{chunk=>1}],
   [[qw"foo_ bar_ baz"],[qw"foo_ boo a _ baz"],[qw"foo_ boo b _ baz"] ],
   "$sec: $p (chunk)";
is_deeply [tg_expand $p='foo_{bar_,boo{a,b}_}baz',{tree=>1}],
  [["foo_",\"bar_","baz"],["foo_",["boo",\"a","_"],"baz"],
                          ["foo_",["boo",\"b","_"],"baz"]],"$sec: $p (tree)";

$sec='oo';
is_deeply [tg_expand($p='foo_{bar_,boo{a,b}_}baz')->elems],
          [@v=("foo_bar_baz", "foo_booa_baz", "foo_boob_baz")],"$sec: $p";
is_deeply [tg_expand($p)->expand],\@v,"$sec: $p"; # mainly another alias
is_deeply [tg_expand($p='foo_{bar_,boo{a,b,}_}baz')->elems],
          [@v=("foo_bar_baz","foo_booa_baz","foo_boob_baz","foo_boo_baz")],"$sec: $p";
is_deeply [tg_expand($p)->expand],\@v,"$sec: $p";
{ my @r; my @s; my @t; my($next,$n2); my $tg=tg_expand $p='foo_{bar_,boo{a,b,}_}baz';
  push @r,$next while defined($next=$$tg); my $tg2=tg_expand $p;
  is_deeply \@r,\@v,"$sec: $p (iter)";
  while (defined($next=$$tg)) { push @s,$next; @t=(); push @t,$n2 while defined($n2=$$tg2) }
  is_deeply \@s,\@v,"$sec: $p (iter deep: outer)"; # XXX Every
  is_deeply \@t,\@v,"$sec: $p (iter deep: inner)";
}
is scalar(tg_expand($p='foo_{bar_,boo{a,b,}_}baz')->elems), 4,"$sec: $p (count)";
is_deeply [@{tg_expand $p='foo_{bar_,boo{a,b}_}baz'}],
          ["foo_bar_baz", "foo_booa_baz", "foo_boob_baz"],"$sec: $p @";
is_deeply [@{tg_expand $p='foo_{bar_,boo{a,b,}_}baz'}],
          ["foo_bar_baz", "foo_booa_baz", "foo_boob_baz", "foo_boo_baz"],"$sec: $p @";
is_deeply [tg_expand($p='foo_{bar_,boo{a,b}_}baz')->chunks],
   [[qw"foo_ bar_ baz"],[qw"foo_ boo a _ baz"],[qw"foo_ boo b _ baz"] ],
   "$sec: $p (chunk)";
is_deeply [tg_expand($p='foo_{bar_,boo{a,b}_}baz')->tree],
  [["foo_",\"bar_","baz"],["foo_",["boo",\"a","_"],"baz"],
                          ["foo_",["boo",\"b","_"],"baz"]],"$sec: $p (tree)";

$sec='examples';     #zsh ug examples
for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ is_deeply [$f->($p='{\,,.}')],[',','.'],"$sec: $p";
  is_deeply [$f->($p='zle_{tricky,vi,word}.c')],[qw'zle_tricky.c zle_vi.c zle_word.c'],"$sec: $p";
  is_deeply [$f->($p='{now,th{en,ere{,abouts}}}')],[qw'now then there thereabouts'],"$sec: $p";
}
$sec='ranges';
for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ is_deeply [$f->($p="[A-Z]")],   [@v='A'..'Z'],"$sec: $p";
  is_deeply [$f->($p="[Z-A]")],   [reverse @v],"$sec: $p";
  is_deeply [$f->($p="{1-111}")], [@v=1..111],"$sec: $p";
  is_deeply [$f->($p="{111-1}")], [reverse @v],"$sec: $p";
  is_deeply [$f->($p='{{,1-11}[02468],120}')],[map $_*2,0..60],"$sec: $p (even)";
  is_deeply [$f->($p="[\0-\040]")],[map chr,0..32], "$sec: [\0-\040] (gigo)"
}
SKIP: { skip "not under EBCDIC",6 if exists $Config{ebcdic} && $Config{ebcdic};
  for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
  { is_deeply [$f->($p="['-?]")], [@v=split'',"'()*+,-./0123456789:;<=>?"],"$sec: $p";
    is_deeply [$f->($p="[?-']")], [reverse @v],        "$sec: $p";
    is_deeply [$f->($p='{a-\\\\}')],  [qw'a ` _ ^ ] \\'],  "$sec: $p"; }
}
for my $f (\&tg_expand, sub { &tg_expand(@_)->elems })
{ is_deeply [$f->($p='{\-\--\-\-}')],['--'],        "$sec: $p --";
  is_deeply [$f->($p='{\-\----}')],  ['--'],        "$sec: $p --";
  is_deeply [$f->($p='{\\-\\----}')],['--'],        "$sec: $p --"; # detto, perl ''
  is_deeply [$f->($p='{\\\\-\\\\}')],   ['\\'],   "$sec: $p"; # better than ..
  is_deeply [$f->($p='{%-%%}')],   ['%','%%'],   "$sec: $p"; # -"-
  is_deeply [$f->($p='{%%-%}')],   ['%%','%'],   "$sec: $p"; # -"-
}

had_no_warnings();
#done_testing;