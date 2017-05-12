# -*- cperl -*-
use Test::More tests => 4;

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
    #__27#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{a b c }x) {
        s{a b c }{cba}x;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(first("abc"),"cba");
is(first("a b c"), "a b c");


sub second {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__28#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{a
b
c
}x) {
        s{a
b
c
}{cba}x;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(second("abc"),"cba");
is(second("a b c"), "a b c");
