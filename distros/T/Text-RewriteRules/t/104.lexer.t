# -*- cperl -*-
use Test::More tests => 17;

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




my $lexer_input = "";
sub lexer_init {
  $lexer_input = shift;
  return 1;
}

sub lexer {
  return undef if not defined $lexer_input;
  for ($lexer_input) {
      if (m{^foo}g) {
        s{foo}{};
        pos = undef;
        return "zbr"
      }
      if (m{^bar}g) {
        s{bar}{};
        pos = undef;
        return "ugh"
      }
  }
  return undef;
}


is(lexer(),undef);

lexer_init("foobar");
is(lexer(),"zbr");
is(lexer(),"ugh");
is(lexer(),undef);

# (4 tests above)---------------

my $lex_input = "";
sub lex_init {
  $lex_input = shift;
  return 1;
}

sub lex {
  return undef if not defined $lex_input;
  for ($lex_input) {
      if (m{^(\d+)}g) {
        s{(\d+)}{};
        pos = undef;
        return ["INT",$1];
      }
      if (m{^([A-Z]+)}g) {
        s{([A-Z]+)}{};
        pos = undef;
        return ["STR",$1];
      }
  }
  return undef;
}


is(lex(),undef);
lex_init("ID25");
is_deeply(lex(),["STR","ID"]);
is_deeply(lex(),["INT", 25]);
is(lex(),undef);

# (8 tests above)-----------------

my $yylex_input = "";
sub yylex_init {
  $yylex_input = shift;
  return 1;
}

sub yylex {
  return undef if not defined $yylex_input;
  for ($yylex_input) {
      if (m{^IF}g) {
        s{IF}{};
        pos = undef;
        return ["IF","IF"];
      }
      if (m{^(\w+)}g) {
        s{(\w+)}{};
        pos = undef;
        return ["ID",$1];
      }
      if (m{^\s+}gi) {
        s{\s+}{}i;
        pos = undef;
        return yylex();
      }
  }
  return undef;
}


is(yylex(),undef);
yylex_init("  IF XPTO");
is_deeply(yylex(),["IF","IF"]);
is_deeply(yylex(),["ID","XPTO"]);
is(yylex(),undef);

# (12 tests above)----------------

my $foo_input = "";
sub foo_init {
  $foo_input = shift;
  return 1;
}

sub foo {
  return undef if not defined $foo_input;
  for ($foo_input) {
      if (m{^IF}gx) {
        s{IF}{}x;
        pos = undef;
        return ("IF","IF");
      }
      if (m{^(\w+)}gx) {
        s{(\w+)}{}x;
        pos = undef;
        return ("ID",$1);
      }
      if (m{^\s+}gix) {
        s{\s+}{}ix;
        pos = undef;
        return foo();
      }
      if (m{^$}) {
         $foo_input = undef;
         return ('',undef);
      }
  }
  return undef;
}


=head Fix Highlight
=cut

is(foo(),undef);
foo_init("  IF XPTO");
is_deeply([foo()],["IF","IF"]);
is_deeply([foo()],["ID","XPTO"]);
is_deeply([foo()],['',undef]);
is(foo(),undef);
