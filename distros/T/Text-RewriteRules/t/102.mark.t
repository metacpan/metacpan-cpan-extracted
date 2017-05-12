# -*- cperl -*-
use warnings;
use strict;
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




## Replace
sub first {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__18#
    my $iteration = 0;
    MAIN: while ($modified) {
      $iteration++;
      $modified = 0;
      if (m{${_M}(?:b)}) {
        s{${_M}(?:b)}{bb${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}) {
        s{${_M}(?:r)}{${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(.|\n)}) {
        s{${_M}(.|\n)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(first("bar"),"bba");



## Replace (ignore case)
sub ifirst {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__25#
    my $iteration = 0;
    MAIN: while ($modified) {
      $iteration++;
      $modified = 0;
      if (m{${_M}(?:b)}i) {
        s{${_M}(?:b)}{bb${_M}}i;
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}i) {
        s{${_M}(?:r)}{${_M}}i;
        $modified = 1;
        next
      }
      if (m{${_M}(.|\n)}) {
        s{${_M}(.|\n)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(ifirst("Bar"),"bba");



## Eval
sub second {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__19#
    my $iteration = 0;
    MAIN: while ($modified) {
      $iteration++;
      $modified = 0;
      if (m{${_M}(?:b)}) {
        s{${_M}(?:b)}{eval{'b' x 2}."$_M"}e;
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}) {
        s{${_M}(?:r)}{${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(.|\n)}) {
        s{${_M}(.|\n)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(second("bar"),"bba");



## Eval with ignore case
sub isecond {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__20#
    my $iteration = 0;
    MAIN: while ($modified) {
      $iteration++;
      $modified = 0;
      if (m{${_M}(?:(b))}i) {
        s{${_M}(?:(b))}{eval{$1 x 2}."$_M"}ei;
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}i) {
        s{${_M}(?:r)}{${_M}}i;
        $modified = 1;
        next
      }
      if (m{${_M}(.|\n)}) {
        s{${_M}(.|\n)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(isecond("Bar"),"BBa");


sub third {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__21#
    my $iteration = 0;
    MAIN: while ($modified) {
      $iteration++;
      $modified = 0;
      while (m{${_M}(?:a)}g) {
        if (1) {
          s{${_M}(?:a)}{b${_M}};
          pos = undef;
          $modified = 1;
          next MAIN
        }
      }
      if (m{${_M}(.|\n)}) {
        s{${_M}(.|\n)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(third("bab"),"bbb");

## use of flag instead of MRULES
sub fourth {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__26#
    my $iteration = 0;
    MAIN: while ($modified) {
      $iteration++;
      $modified = 0;
      if (m{${_M}(?:b)}) {
        s{${_M}(?:b)}{bb${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}) {
        s{${_M}(?:r)}{${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(.|\n)}) {
        s{${_M}(.|\n)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(fourth("bar"),"bba");

## Eval
sub fifth {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__22#
    my $iteration = 0;
    MAIN: while ($modified) {
      $iteration++;
      $modified = 0;
      if (m{${_M}(?:b)}) {
        s{${_M}(?:b)}{eval{$a = log(2); $a = sin($a);'b' x 2}."$_M"}e;
        $modified = 1;
        next
      }
      if (m{${_M}(?:r)}) {
        s{${_M}(?:r)}{${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(.|\n)}) {
        s{${_M}(.|\n)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(fifth("bar"),"bba");

## Simple Last 
sub sixth {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__23#
    my $iteration = 0;
    MAIN: while ($modified) {
      $iteration++;
      $modified = 0;
      if (m{${_M}(?:bar)}) {
        s{${_M}(?:bar)}{ugh${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(?:foo)}) {
        s{${_M}}{};
        last
      }
      if (m{${_M}(.|\n)}) {
        s{${_M}(.|\n)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(sixth("barfoobar"),"ughfoobar");

## Last with condition
sub seventh {
  my $p = shift;
  my $_M = "\x01";
  for ($p) {
    my $modified = 1;
    $_ = $_M.$_;
    #__24#
    my $iteration = 0;
    MAIN: while ($modified) {
      $iteration++;
      $modified = 0;
      if (m{${_M}(?:bar)}) {
        s{${_M}(?:bar)}{ugh${_M}};
        $modified = 1;
        next
      }
      if (m{${_M}(?:f(o+))}) {
        if (length($1)>2) {
          s{${_M}}{};
          last
        }
      }
      if (m{${_M}(.|\n)}) {
        s{${_M}(.|\n)}{$1${_M}};
        $modified = 1;
        next
      }
    }
    s/$_M//;
  }
  return $p;
}


is(seventh("barfoobarfooobar"),"ughfooughfooobar");
