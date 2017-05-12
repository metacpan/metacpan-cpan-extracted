# -*- cperl -*-
use Test::More tests => 10;

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
    #__33#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{$__XMLtree}) {
        s{$__XMLtree}{XML};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub Xsecond {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__34#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{<d$__XMLattrs(?:/>|>$__XMLinner</d>)}) {
        s{<d$__XMLattrs(?:/>|>$__XMLinner</d>)}{XML};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub Ysecond {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__35#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{<c$__XMLattrs(?:/>|>$__XMLinner</c>)}) {
        s{<c$__XMLattrs(?:/>|>$__XMLinner</c>)}{XML};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub Zsecond {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__36#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{<b$__XMLattrs(?:/>|>$__XMLinner</b>)}) {
        s{<b$__XMLattrs(?:/>|>$__XMLinner</b>)}{XML};
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
    #__37#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{$__XMLtree}) {
        s{$__XMLtree}{$+{TAGNAME}}e;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


sub Xthird {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__38#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{$__XMLtree}) {
        s{$__XMLtree}{$+{PCDATA}}e;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


my $in = "<a><b></a></b> ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola";
my $in2 = "ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola";
my $in3 = "<foo hmm=\"bar\"/>";

is(first($in),"<a><b></a></b> ola XML ola");
is(first($in2),"ola XML ola XML ola");
is(first($in3), "XML");

is(Xsecond($in),"<a><b></a></b> ola <a hmm =\"hmm\"><b>XML<c>o</c></b></a> ola");
is(Ysecond($in),"<a><b></a></b> ola <a hmm =\"hmm\"><b><d zbr='foo'/>XML</b></a> ola");
is(Zsecond($in),"<a><b></a></b> ola <a hmm =\"hmm\">XML</a> ola");
is(Zsecond($in2),"ola <a hmm =\"hmm\">XML</a> ola <a hmm =\"hmm\">XML</a> ola");

is(third($in),"<a><b></a></b> ola a ola");
is(third($in3),"foo");
is(Xthird($in),"<a><b></a></b> ola o ola");


