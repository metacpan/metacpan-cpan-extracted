# -*- cperl -*-
use Test::More tests => 9;

our $__XMLattrs = qr/(?:
                      \s+[a-zA-Z0-9:-]+\s*
                      =
                      \s*(?: '[^']+' | "[^"]+" ))*/x;

### This (?<PCDATA>\n) is a BIG hack!
our $__XMLempty = qr/<(?<TAGNAME>[a-zA-Z0-9:-]+)(?<PCDATA>\b)$__XMLattrs\/>/x;

our $__XMLtree2  = qr/$__XMLempty |
                  (?<XML>
                      <(?<TAG>[a-zA-Z0-9:-]+)$__XMLattrs>
                        (?:  $__XMLempty  |  [^<]++  |  (?&XML) )*+
                      <\/\k<TAG>>
                  )/x;
our $__XMLtree  = qr/$__XMLempty |
                  (?<XML>
                      <(?<TAGNAME>[a-zA-Z0-9:-]+)$__XMLattrs>
                        (?<PCDATA>(?:  $__XMLempty  |  [^<]++  |  $__XMLtree2 )*+)
                      <\/\k<TAGNAME>>
                  )/x;
our $__XMLinner = qr/(?:  [^<]++ | $__XMLempty | $__XMLtree2 )*+/x;

our $__CBB = qr{ (?<cbb1> \{ (?<CBB>(?:[^\{\}]++|(?&cbb1))*+) \} ) }sx;
our $__BB  = qr{ (?<bb1>  \[ (?<BB> (?:[^\[\]]++|(?&bb1) )*+) \] ) }sx;
our $__PB  = qr{ (?<pb1>  \( (?<PB> (?:[^\(\)]++|(?&pb1) )*+) \) ) }sx;

our $__TEXENV  = qr{\\begin\{(\w+)\}(.*?)\\end\{\1\}}s;                 ## \begin{$1}$2\end
our $__TEXENV1 = qr{\\begin\{(\w+)\}($__BB?)($__CBB)(.*?)\\end\{\1\}}s; ## \begin{$1}[$2]{$3}$4\end




sub first {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__39#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{$__PB}) {
        s{$__PB}{+};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub second {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__40#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{$__BB}) {
        s{$__BB}{*};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub third {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__41#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{$__CBB}) {
        s{$__CBB}{#};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub fourth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__42#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{$__CBB}) {
        s{$__CBB}{[$+{CBB}]};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub fifth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__43#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{$__BB}) {
        s{$__BB}{{$+{BB}}};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub sixth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__44#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{$__PB}) {
        s{$__PB}{{$+{PB}}};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


my $in = "ola (a (b)(d zbr='foo')(c)) munto (c()()ba)((())) ola";
my $in2 = "ola ((a hmm =\"hmm\")(b)(d zbr='foo'/)(c)) lua ((/c)(/b)(/a) 
    ola (a hmm =\"hmm\")(b)(d zbr='foo'/))(c)(/c)(aaa()(/a) ola";

my $on = "ola [a [b][d zbr='foo'][c]] munto [c[][]ba][[[]]] ola";
my $on2 = "ola [[a hmm =\"hmm\"][b][d zbr='foo'/][c]] lua [[/c][/b][/a] 
    ola [a hmm =\"hmm\"][b][d zbr='foo'/]][c][/c][aaa[][/a] ola";

my $un = "ola {a {b}{d zbr='foo'}{c}} munto {c{}{}ba}{{{}}} ola";
my $un2 = "ola {{a hmm =\"hmm\"}{b}{d zbr='foo'/}{c}} lua {{/c}{/b}{/a} 
    ola {a hmm =\"hmm\"}{b}{d zbr='foo'/}}{c}{/c}{aaa{}{/a} ola";

is(first($in),"ola + munto ++ ola");
is(first($in2),"ola + lua +++(aaa++ ola");

is(second($on),"ola * munto ** ola");
is(second($on2),"ola * lua ***[aaa** ola");

is(third($un),"ola # munto ## ola");
is(third($un2),"ola # lua ###{aaa## ola");

is(fourth("{ xpto } {{"),"[ xpto ] {{");
is(fifth("]] [xpto] {{"),"]] {xpto} {{");
is(sixth("((xpto)(xpto){{"),"({xpto}{xpto}{{");

