# -*- cperl -*-
use Test::More tests => 54;

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




## Replace
sub first {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__1#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{a}) {
        s{a}{b};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(first("bar"),"bbr");

## Replace Ignore Case
sub ifirst {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__2#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{a}i) {
        s{a}{b}i;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(ifirst("BAR"),"BbR");


### --- ###


## Replace with references...
sub second {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__3#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{a(\d+)}) {
        s{a(\d+)}{$1};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(second("a342"),"342");
is(second("b342"),"b342");
is(second("ba2cd"),"b2cd");


## Replace Ignore Case with references...
sub isecond {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__4#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{a(\d+)}i) {
        s{a(\d+)}{$1}i;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(isecond("A342"),"342");
is(isecond("b342"),"b342");
is(isecond("ba2cd"),"b2cd");


### --- ###


## Conditional
sub third {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__5#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      while (m{b(a+)b}g) {
        if ( length($1)>5) {
          s{b(a+)b\G}{bbb};
          pos = undef;
          $modified = 1;
          next MAIN
        }
      }
    }
  }
  return $p;
}


is(third("bab"), "bab");
is(third("baab"), "baab");
is(third("baaab"), "baaab");
is(third("baaaab"), "baaaab");
is(third("baaaaab"), "baaaaab");
is(third("baaaaaab"), "bbb");
is(third("baaaaaaab"), "bbb");


## Conditional Ignore Case
sub ithird {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__6#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      while (m{b(a+)b}gi) {
        if ( length($1)>5) {
          s{b(a+)b\G}{bbb}i;
          pos = undef;
          $modified = 1;
          next MAIN
        }
      }
    }
  }
  return $p;
}


is(ithird("bAb"), "bAb");
is(ithird("baab"), "baab");
is(ithird("bAaAb"), "bAaAb");
is(ithird("baAaAb"), "baAaAb");
is(ithird("bAaAaAb"), "bAaAaAb");
is(ithird("baAaAaAb"), "bbb");
is(ithird("bAaAaAaAb"), "bbb");


### --- ###


## Eval Conditional
sub fourth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__7#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      while (m{b(\d+)}g) {
        if ( $1 > 5) {
          s{b(\d+)\G}{'b' x $1 }e;
          pos = undef;
          $modified = 1;
          next MAIN
        }
      }
    }
  }
  return $p;
}


is(fourth("b1"), "b1");
is(fourth("b2"), "b2");
is(fourth("b5"), "b5");
is(fourth("b6"), "bbbbbb");
is(fourth("b8"), "bbbbbbbb");


## Eval Conditional with Ignore Case
sub ifourth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__8#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      while (m{b(\d+)}gi) {
        if ( $1 > 5) {
          s{b(\d+)\G}{'b' x $1 }ei;
          pos = undef;
          $modified = 1;
          next MAIN
        }
      }
    }
  }
  return $p;
}


is(ifourth("b1"), "b1");
is(ifourth("B2"), "B2");
is(ifourth("b5"), "b5");
is(ifourth("B6"), "bbbbbb");
is(ifourth("b8"), "bbbbbbbb");


### --- ###


## Eval
sub fifth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__9#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{b(\d+)}) {
        s{b(\d+)}{'b' x $1}e;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(fifth("b1"), "b");
is(fifth("b2"), "bb");
is(fifth("b5"), "bbbbb");
is(fifth("b8"), "bbbbbbbb");


## Eval with ignore case
sub ififth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__10#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{(b)(\d+)}i) {
        s{(b)(\d+)}{$1 x $2}ei;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(ififth("b1"), "b");
is(ififth("B2"), "BB");
is(ififth("b5"), "bbbbb");
is(ififth("B8"), "BBBBBBBB");


### --- ###


### Don't like this
### the return value should be used, I think.
sub sixth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
     $_="AA${_}AA";
#__11#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
    }
  }
  return $p;
}


is(sixth("foo"),"AAfooAA");


### --- ###


## Last...
sub seventh {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__12#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{bbbbbb}) {
        last
      }
      if (m{b}) {
        s{b}{bb};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(seventh("b"),"bbbbbb");

## Last... with ignore case
sub iseventh {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__13#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{bbbbbb}i) {
        last
      }
      if (m{b}) {
        s{b}{bB};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(iseventh("b"),"bBBBBB");




### --- ###

# ignore and NOT ignore

sub eigth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__14#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{a}i) {
        s{a}{c}i;
        $modified = 1;
        next
      }
      if (m{b}) {
        s{b}{d};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(eigth("abc"),"cdc");
is(eigth("Abc"),"cdc");
is(eigth("aBc"),"cBc");

# ignore all

sub ieigth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__15#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{a}i) {
        s{a}{c}i;
        $modified = 1;
        next
      }
      if (m{b}i) {
        s{b}{d}i;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}



is(ieigth("abc"),"cdc");
is(ieigth("Abc"),"cdc");
is(ieigth("aBc"),"cdc");


# ignore all... =i= does nothing

sub iieigth {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__16#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{a}i) {
        s{a}{c}i;
        $modified = 1;
        next
      }
      if (m{b}i) {
        s{b}{d}i;
        $modified = 1;
        next
      }
    }
  }
  return $p;
}



is(iieigth("abc"),"cdc");
is(iieigth("Abc"),"cdc");
is(iieigth("aBc"),"cdc");


# Test last with condition

sub more {
  my $p = shift;
  for ($p) {
    my $modified = 1;
    #__17#
    my $iteration = 0;
    MAIN: while($modified) {
      $modified = 0;
      $iteration++;
      if (m{(...)}) {
        if ($1 eq "bar") {
          last
        }
      }
      if (m{ar}) {
        s{ar}{oo};
        $modified = 1;
        next
      }
    }
  }
  return $p;
}


is(more("bar"),"bar");
is(more("arre"),"oore");

