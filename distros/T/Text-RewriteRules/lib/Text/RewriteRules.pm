package Text::RewriteRules;

use Data::Dumper;
use Filter::Simple;

use warnings;
use strict;

use 5.010000; # 5.10.0

=encoding UTF-8

=head1 NAME

Text::RewriteRules - A system to rewrite text using regexp-based rules

=cut

our $VERSION = '0.25';

=head1 SYNOPSIS

    use Text::RewriteRules;

    RULES email
    \.==> DOT 
    @==> AT 
    ENDRULES

    print email("ambs@cpan.org") # prints ambs AT cpan DOT org

    RULES/m inc
    (\d+)=e=> $1+1
    ENDRULES

    print inc("I saw 11 cats and 23 dogs") # prints I saw 12 cats and 24 dogs

=head1 ABSTRACT

This module uses a simplified syntax for regexp-based rules for
rewriting text. You define a set of rules, and the system applies them
until no more rule can be applied.

Two variants are provided: 

=over 4

=item 1

traditional rewrite (RULES function):

 while it is possible do substitute
 | apply first substitution rule 

=item 2

cursor based rewrite (RULES/m function):

 add a cursor to the beginning of the string
 while not reach end of string
 | apply substitute just after cursor and advance cursor
 | or advance cursor if no rule can be applied

=back

=head1 DESCRIPTION

A lot of computer science problems can be solved using rewriting
rules.

Rewriting rules consist of mainly two parts: a regexp (LHS: Left Hand
Side) that is matched with the text, and the string to use to
substitute the content matched with the regexp (RHS: Right Hand Side).

Now, why don't use a simple substitute? Because we want to define a
set of rules and match them again and again, until no more regexp of
the LHS matches.

A point of discussion is the syntax to define this system. A brief
discussion shown that some users would prefer a function to receive an
hash with the rules, some other, prefer some syntax sugar.

The approach used is the last: we use C<Filter::Simple> such that we
can add a specific non-perl syntax inside the Perl script. This
improves legibility of big rewriting rules systems.

This documentation is divided in two parts: first we will see the
reference of the module. Kind of, what it does, with a brief
explanation. Follows a tutorial which will be growing through time and
releases.

=head1 SYNTAX REFERENCE

Note: most of the examples are very stupid, but that is the easiest
way to explain the basic syntax.

The basic syntax for the rewrite rules is a block, started by the
keyword C<RULES> and ended by the C<ENDRULES>. Everything between
them is handled by the module and interpreted as rules or comments.

The C<RULES> keyword can handle a set of flags (we will see that
later), and requires a name for the rule-set. This name will be used
to define a function for that rewriting system.

   RULES functioname
    ...
   ENDRULES

The function is defined in the main namespace where the C<RULES>
block appears.

In this block, each line can be a comment (Perl style), an empty line
or a rule.

=head2 Basic Rule

A basic rule is a simple substitution:

  RULES foobar
  foo==>bar
  ENDRULES

The arrow C<==E<gt>> is used as delimiter. At its left is the regexp
to match, at the right side, the substitution. So, the previous block
defines a C<foobar> function that substitutes all C<foo> by
C<bar>.

Although this can seems similar to a global substitution, it is
not. With a global substitution you can't do an endless loop. With
this module it is very simple. I know you will get the idea.

You can use the syntax of Perl both on the left and right hand side of
the rule, including C<$1...>.

=head2 Execution Rule

If the Perl substitution supports execution, why not to support it,
also? So, you got the idea. Here is an example:

  RULES foo
  (\d+)b=e=>'b' x $1
  (\d+)a=eval=>'a' x ($1*2)
  ENDRULES

So, for any number followed by a C<b>, we replace by that number of
C<b's>. For each number followed by an C<a>, we replace them by twice
that number of C<a's>.

Also, you mean evaluation using an C<e> or C<eval> inside the arrow. I
should remind you can mix all these rules together in the same
rewriting system.

=head2 Conditional Rule

On some cases we want to perform a substitution if the pattern matches
B<and> a set of conditions about that pattern (or not) are true.

For that, we use a three part rule. We have the common rule plus the
condition part, separated from the rule by C<!!>. These conditional
rules can be applied both for basic and execution rules.

  RULES translate
  ([[:alpha:]]+)=e=>$dic{$1}!! exists($dic{$1})
  ENDRULES

The previous example would translate all words that exist on the
dictionary.

=head2 Begin Rule

Sometimes it is useful to change something on the string before
starting to apply the rules. For that, there is a special rule named
C<begin> (or C<b> for abbreviate) just with a RHS. This RHS is Perl
code. Any Perl code. If you want to modify the string, use C<$_>.

  RULES foo
  =b=> $_.=" END"
  ENDRULES

=head2 Last Rule

As you use C<last> on Perl to skip the remaining code on a loop, you
can also call a C<last> (or C<l>) rule when a specific pattern
matches.

Like the C<begin> rule with only a RHS, the C<last> rule has only a
LHS:

  RULES foo
  foobar=l=>
  ENDRULES

This way, the rules iterate until the string matches with C<foobar>.

You can also supply a condition in a last rule:

  RULES bar
  f(o+)b(a+)r=l=> !! length($1) == 2 * length($2);

=head2 Rules with /x mode

It is possible to use the regular expressions /x mode in the rewrite rules.
In this case:

=over 4

=item 1

there must be an empty line between rules

=item 2

you can insert space and line breaks into the regular expression:

 RULES/x f1
 (\d+) 
 (\d{3}) 
 (000) 
 ==>$1 milhao e $2 mil!! $1 == 1

 ENDRULES

=back

=head1 POWER EXPRESSIONS

To facilitate matching complex languages Text::RewriteRules defines a
set of regular expressions that you can use (without defining them).

=head2 Parenthesis

There are three kind of usual parenthesis: the standard parenthesis,
brackets or curly braces. You can match a balanced string of
parenthesis using the power expressions C<[[:PB:]]>, C<[[:BB:]]> and
C<[[:CBB:]]> for these three kind of parenthesis.

For instance, if you apply this rule:

   [[:BB:]]==>foo

to this string

  something [ a [ b] c [d ]] and something more

then, you will get

  something foo and something more

Note that if you apply it to

  something [[ not ] balanced [ here

then you will get

  something [foo balanced [ here

=head2 XML tags

The power expression C<[[:XML:]]> match a XML tag (with or without
children XML tags. Note that this expression matches only well formed
XML tags.

As an example, the rule

  [[:XML:]]=>tag

applied to the string

  <a><b></a></b> and <more><img src="foo"/></more>

will result in

  <a><b></a></b> and tag


=cut

our $DEBUG = 0;
our $count = 0;
our $NL = qr/\r?\n\r?/;
my %pseudo_classes=(
                    TEXENV => 'TEXENV',
                    PB     => 'PB',
                    BB     => 'BB',
                    CBB    => 'CBB',
                    XML    => 'XMLtree',
                    'XML+1' => \&_tag_re,
);

sub _regular_expressions {
    return <<'EORE';

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


EORE
}

sub _tag_re {
    my $tagname = shift;
    return "<$tagname\$__XMLattrs(?:\/>|>\$__XMLinner<\/$tagname>)";
}


sub _expand_pseudo_classes {
    my $rules = shift;

    $rules =~ s/(\[\[:(\w+):\]\])/$pseudo_classes{$2}?"\$__$pseudo_classes{$2}":$1/ge;
    $rules =~ s/\[\[:(\w+)\(([^,\(\)]+)\):\]\]/$pseudo_classes{"$1+1"}->($2)/ge;

    return $rules;
}

sub _mrules {
    my ($conf, $name, $rules) = @_;
    ++$count;

    my $code = "sub $name {\n";
    $code .= "  my \$p = shift;\n";
    $code .= "  my \$_M = \"\\x01\";\n";
    $code .= "  for (\$p) {\n";
    $code .= "    my \$modified = 1;\n";
    $code .= "    \$_ = \$_M.\$_;\n";
    $code .= "    #__$count#\n";
    $code .= "    my \$iteration = 0;\n";
    $code .= "    MAIN: while (\$modified) {\n";
    $code .= "      \$iteration++;\n";

    if ($DEBUG) {
        $code .= "      print STDERR \" >\$_\\n\";\n"
    }

    $code .= "      \$modified = 0;\n";

    my $ICASE = exists($conf->{i})?"i":"";
    my $DX    = exists($conf->{x})?"x":"";
    if (exists($conf->{d})) {
        $code .= "      print STDERR \"Iteration on $name: \$iteration\n\$p\n\";";
    }

    my @rules;
    if ($DX eq "x") {
        @rules = split /$NL$NL/, $rules;
    } else {
        @rules = split /$NL/, $rules;
    }

    for my $rule (@rules) {
        $rule =~ s/$NL$//;
	
        if ($rule =~ m/(.*?)(=i?=>)(.*)!!(.*)/) {
            my ($ant,$con,$cond) = ($1,$3,$4);
            $ICASE = "i" if $2 =~ m!i!;
            $ant = _expand_pseudo_classes($ant);

            $code .= "      while (m{\${_M}(?:$ant)}g$ICASE) {\n";
            $code .= "        if ($cond) {\n";
            $code .= "          s{\${_M}(?:$ant)}{$con\${_M}}$ICASE;\n";
            $code .= "          pos = undef;\n";
            $code .= "          \$modified = 1;\n";
            $code .= "          next MAIN\n";
            $code .= "        }\n";
            $code .= "      }\n";

        } elsif ($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)!!(.*)/) {
            my ($ant,$con,$cond) = ($1,$3,$4);
            $ICASE = "i" if $2 =~ m!i!;
            $ant = _expand_pseudo_classes($ant);

            $code .= "      while (m{\${_M}(?:$ant)}g$ICASE) {\n";
            $code .= "        if ($cond) {\n";
            $code .= "          s{\${_M}(?:$ant)}{eval{$con}.\${_M}}e$ICASE;\n";
            $code .= "          pos = undef;\n";
            $code .= "          \$modified = 1;\n";
            $code .= "          next MAIN\n";
            $code .= "        }\n";
            $code .= "      }\n";

        } elsif ($rule =~ m/(.*?)(=i?=>)(.*)/) {
            my ($ant,$con) = ($1,$3);
            $ICASE = "i" if $2 =~ m!i!;
            $ant = _expand_pseudo_classes($ant);

            $code .= "      if (m{\${_M}(?:$ant)}$ICASE) {\n";
            $code .= "        s{\${_M}(?:$ant)}{$con\${_M}}$ICASE;\n";
            $code .= "        \$modified = 1;\n";
            $code .= "        next\n";
            $code .= "      }\n";

        } elsif($rule =~ m/=b(?:egin)?=>(.*)/s) {

            my $ac = $1;
            $code =~ s/(#__$count#\n)/$ac;\n$1/;

        } elsif ($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)/) {
            my ($ant,$con) = ($1,$3);
            $ICASE = "i" if $2 =~ m!i!;
            $ant = _expand_pseudo_classes($ant);

            $code .= "      if (m{\${_M}(?:$ant)}$ICASE) {\n";
            $code .= "        s{\${_M}(?:$ant)}{eval{$con}.\"\$_M\"}e$ICASE;\n";
            $code .= "        \$modified = 1;\n";
            $code .= "        next\n";
            $code .= "      }\n";

        } elsif($rule =~ m/(.*?)(=(?:i=)?l(?:ast)?=>\s*!!(.*))/s) {
            my ($ant,$cond) = ($1,$3);
            $ICASE = "i" if $2 =~ m!i!;
            $ant = _expand_pseudo_classes($ant);

            $code .= "      if (m{\${_M}(?:$ant)}$ICASE$DX) {\n";
            $code .= "        if ($cond) {\n";
            $code .= "          s{\${_M}}{};\n";
            $code .= "          last\n";
            $code .= "        }\n";
            $code .= "      }\n";

        } elsif($rule =~ m/(.*?)(=(?:i=)?l(?:ast)?=>)/s) {
            my ($ant) = ($1);
            $ICASE = "i" if $2 =~ m!i!;
            $ant = _expand_pseudo_classes($ant);

            $code .= "      if (m{\${_M}(?:$ant)}$ICASE$DX) {\n";
            $code .= "        s{\${_M}}{};\n";
            $code .= "        last\n";
            $code .= "      }\n";

        } else {
            warn "Unknown rule: $rule\n" unless $rule =~ m!^\s*(#|$)!;
        }
    }
    ##---

    # Make it walk...
    $code .= "      if (m{\${_M}(.|\\n)}) {\n";
    $code .= "        s{\${_M}(.|\\n)}{\$1\${_M}};\n";
    $code .= "        \$modified = 1;\n";
    $code .= "        next\n";
    $code .= "      }\n";

    $code .= "    }\n";
    $code .= "    s/\$_M//;\n";
    $code .= "  }\n";
    $code .= "  return \$p;\n";
    $code .= "}\n";

    $code;
}

sub _rules {
  my ($conf, $name, $rules) = @_;
  ++$count;

  my $code = "sub $name {\n";
  $code .= "  my \$p = shift;\n";
  $code .= "  for (\$p) {\n";
  $code .= "    my \$modified = 1;\n";
  $code .= "    #__$count#\n";
  $code .= "    my \$iteration = 0;\n";
  $code .= "    MAIN: while(\$modified) {\n";
  $code .= "      print STDERR \$_;\n" if $DEBUG > 1;
  $code .= "      \$modified = 0;\n";
  $code .= "      \$iteration++;\n";

  ##---

  my $DICASE      = exists($conf->{i})?"i":"";
  my $DX          = exists($conf->{x})?"x":"";
  if (exists($conf->{d})) {
      $code .= "      print STDERR \"Iteration on $name: \$iteration\n\$p\n\";";
  }

  my @rules;
  if ($DX eq "x") {
    @rules = split /$NL$NL/, $rules;
  } else {
    @rules = split /$NL/, $rules;
  }

  for my $rule (@rules) {
		$rule =~ s/$NL$//;

    my $ICASE = $DICASE;

    if($rule =~ m/(.*?)(=i?=>)(.*)!!(.*)/s) {
      my ($ant,$con,$cond) = ($1,$3,$4);
      $ICASE = "i" if $2 =~ m!i!;
      $ant = _expand_pseudo_classes($ant);

      $code .= "      while (m{$ant}g$ICASE$DX) {\n";
      $code .= "        if ($cond) {\n";
      $code .= "          s{$ant\\G}{$con}$ICASE$DX;\n";
      $code .= "          pos = undef;\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)!!(.*)/s) {
      my ($ant,$con,$cond) = ($1,$3,$4);
      $ICASE = "i" if $2 =~ m!i!;
      $ant = _expand_pseudo_classes($ant);

      $code .= "      while (m{$ant}g$ICASE$DX) {\n";
      $code .= "        if ($cond) {\n";
      $code .= "          s{$ant\\G}{$con}e${ICASE}${DX};\n";
      $code .= "          pos = undef;\n";
      $code .= "          \$modified = 1;\n";
      $code .= "          next MAIN\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*?)(=i?=>)(.*)/s) {
      my ($ant,$con) = ($1,$3);
      $ICASE = "i" if $2 =~ m!i!;
      $ant = _expand_pseudo_classes($ant);

      $code .= "      if (m{$ant}$ICASE$DX) {\n";
      $code .= "        s{$ant}{$con}$ICASE$DX;\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";

    } elsif ($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)/s) {
      my ($ant,$con) = ($1,$3);
      $ICASE = "i" if $2 =~ m!i!;
      $ant = _expand_pseudo_classes($ant);

      $code .= "      if (m{$ant}$ICASE$DX) {\n";
      $code .= "        s{$ant}{$con}e$ICASE$DX;\n";
      $code .= "        \$modified = 1;\n";
      $code .= "        next\n";
      $code .= "      }\n";

    } elsif($rule =~ m/=b(?:egin)?=>(.*)/s) {

      my $ac = $1;
      $code =~ s/(#__$count#\n)/$ac;\n$1/;

    } elsif($rule =~ m/(.*?)(=(i=)?l(ast)?=>\s*!!(.*))/s) {
      my ($ant,$cond) = ($1,$5);
      $ICASE = "i" if $2 =~ m!i!;
      $ant = _expand_pseudo_classes($ant);

      $code .= "      if (m{$ant}$ICASE$DX) {\n";
			$code .= "        if ($cond) {\n";
      $code .= "          last\n";
      $code .= "        }\n";
      $code .= "      }\n";

    } elsif($rule =~ m/(.*?)(=(i=)?l(ast)?=>)/s) {
      my ($ant) = ($1);
      $ICASE = "i" if $2 =~ m!i!;
      $ant = _expand_pseudo_classes($ant);

      $code .= "      if (m{$ant}$ICASE$DX) {\n";
      $code .= "        last\n";
      $code .= "      }\n";

    } else {
      warn "Unknown rule: $rule\n" unless $rule =~ m!^\s*(#|$)!;
    }
  }

  ##---

  $code .= "    }\n";
  $code .= "  }\n";
  $code .= "  return \$p;\n";
  $code .= "}\n";

  $code;
}

sub _lrules {
  my ($conf, $name, $rules) = @_;
  ++$count;

  my $code = "my \$${name}_input = \"\";\n";
  $code .= "sub ${name}_init {\n";
  $code .= "  \$${name}_input = shift;\n";
  $code .= "  return 1;\n";
  $code .= "}\n\n";

  $code .= "sub $name {\n";
  $code .= "  return undef if not defined \$${name}_input;\n";
  $code .= "  print STDERR \$_;\n" if $DEBUG > 1;
  $code .= "  for (\$${name}_input) {\n";

  ##---

  my $DICASE = exists($conf->{i})?"i":"";
  my $DX = exists($conf->{x})?"x":"";

  my @rules;
  if ($DX eq "x") {
      @rules = split /$NL$NL/, $rules;
  } else {
      @rules = split /$NL/, $rules;
  }

  for my $rule (@rules) {
      $rule =~ s/$NL$//;

      my $ICASE = $DICASE;

      if ($rule =~ m/=EOF=>(.*)/s) {

          my $act = $1;			
          $code .= "      if (m{^\$}) {\n";
          $code .= "         \$${name}_input = undef;\n";
          $code .= "         return \"$act\";\n";
          $code .= "      }\n";

      } elsif ($rule =~ m/=EOF=e=>(.*)/s) {

          my $act = $1;
          $code .= "      if (m{^\$}) {\n";
          $code .= "         \$${name}_input = undef;\n";
          $code .= "         return $act;\n";
          $code .= "      }\n";
			
      } elsif ($rule =~ m/(.*?)(=(?:i=)?ignore=>)(.*)!!(.*)/s) {
          my ($ant,$cond) = ($1, $4);		
          $ICASE = "i" if $2 =~ m!i!;
          $ant = _expand_pseudo_classes($ant);

          $code .= "      if (m{^$ant}g$ICASE$DX) {\n";
          $code .= "        if ($cond) {\n";
          $code .= "          s{$ant}{}$ICASE$DX;\n";
          $code .= "          pos = undef;\n";
          $code .= "          return $name();\n";
          $code .= "        }\n";
          $code .= "      }\n";

      } elsif ($rule =~ m/(.*?)(=(?:i=)?ignore=>)(.*)/s) {
          my ($ant) = ($1);
          $ICASE = "i" if $2 =~ m!i!;
          $ant = _expand_pseudo_classes($ant);

          $code .= "      if (m{^$ant}g$ICASE$DX) {\n";
          $code .= "        s{$ant}{}$ICASE$DX;\n";
          $code .= "        pos = undef;\n";
          $code .= "        return $name();\n";
          $code .= "      }\n";

      } elsif($rule =~ m/(.*?)(=i?=>)(.*)!!(.*)/s) {
          my ($ant,$con,$cond) = ($1,$3,$4);
          $ICASE = "i" if $2 =~ m!i!;
          $ant = _expand_pseudo_classes($ant);

          $code .= "      if (m{^$ant}g$ICASE$DX) {\n";
          $code .= "        if ($cond) {\n";
          $code .= "          s{$ant}{}$ICASE$DX;\n";
          $code .= "          pos = undef;\n";
          $code .= "          return \"$con\"\n";
          $code .= "        }\n";
          $code .= "      }\n";

      } elsif($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)!!(.*)/s) {
          my ($ant,$con,$cond) = ($1,$3,$4);
          $ICASE = "i" if $2 =~ m!i!;
          $ant = _expand_pseudo_classes($ant);

          $code .= "      if (m{^$ant}g$ICASE$DX) {\n";
          $code .= "        if ($cond) {\n";
          $code .= "          s{$ant}{}${ICASE}${DX};\n";
          $code .= "          pos = undef;\n";
          $code .= "          return $con;\n";
          $code .= "        }\n";
          $code .= "      }\n";

      } elsif($rule =~ m/(.*?)(=i?=>)(.*)/s) {
	
          my ($ant,$con) = ($1,$3);
          $ICASE = "i" if $2 =~ m!i!;
          $ant = _expand_pseudo_classes($ant);

          $code .= "      if (m{^$ant}g$ICASE$DX) {\n";
          $code .= "        s{$ant}{}$ICASE$DX;\n";
          $code .= "        pos = undef;\n";
          $code .= "        return \"$con\"\n";
          $code .= "      }\n";

      } elsif($rule =~ m/(.*?)(=(?:i=)?e(?:val)?=>)(.*)/s) {
          my ($ant,$con) = ($1,$3);
          $ICASE = "i" if $2 =~ m!i!;
          $ant = _expand_pseudo_classes($ant);

          $code .= "      if (m{^$ant}g$ICASE$DX) {\n";
          $code .= "        s{$ant}{}${ICASE}${DX};\n";
          $code .= "        pos = undef;\n";
          $code .= "        return $con;\n";
          $code .= "      }\n";

      } else {
          warn "Unknown rule in lexer mode: $rule\n" unless $rule =~ m!^\s*(#|$)!;
      }
  }

  ##---

  $code .= "  }\n";
  $code .= "  return undef;\n";
  $code .= "}\n";

  $code;
}


FILTER {
  return if m!^(\s|\n)*$!;

  s!^!_regular_expressions()!e;

  print STDERR "BEFORE>>>>\n$_\n<<<<\n" if $DEBUG;

  s!^MRULES +(\w+)\s*?\n((?:.|\n)*?)^ENDRULES!_mrules({}, $1,$2)!gem;

  s!^LRULES +(\w+)\s*?\n((?:.|\n)*?)^ENDRULES!_lrules({}, $1,$2)!gem;

  s{^RULES((?:\/\w+)?) +(\w+)\s*?\n((?:.|\n)*?)^ENDRULES}{
    my ($a,$b,$c) = ($1,$2,$3);
    my $conf = {map {($_=>$_)} split //,$a};
	 	if (exists($conf->{'l'})) {
			_lrules($conf, $b, $c)
	 	} elsif (exists($conf->{'m'})) {
    	_mrules($conf,$b,$c)
    } else {
    	_rules($conf,$b,$c)
    }
   }gem;



  print STDERR "AFTER>>>>\n$_\n<<<<\n" if $DEBUG;

  $_
};

sub _compiler{

  local $/ = undef;
  $_ = <>;

  print __compiler($_);
}

sub __compiler {
    my $str = shift;

    for ($str) {

        s!use Text::RewriteRules;!_regular_expressions()!e;

        s!^MRULES +(\w+)\s*\n((?:.|\n)*?)^ENDRULES!_mrules({}, $1,$2)!gem;

        s!^LRULES +(\w+)\s*\n((?:.|\n)*?)^ENDRULES!_lrules({}, $1,$2)!gem;

        s{^RULES((?:\/\w+)?) +(\w+)\s*\n((?:.|\n)*?)^ENDRULES}{
            my ($a,$b,$c) = ($1,$2,$3);

            my $conf = {map {($_=>$_)} split //,$a};
            if (exists($conf->{'l'})) {
		_lrules($conf,$b,$c)
            } elsif (exists($conf->{'m'})) {
		_mrules($conf,$b,$c)
            } else {
		_rules($conf,$b,$c)
            }
        }gem;
    }

    return $str;
}

=head1 TUTORIAL

At the moment, just a set of commented examples.

Example1 -- from number to portuguese words  (using traditional rewriting)

Example2 -- Naif translator (using cursor-based rewriting)

=head1 Conversion between numbers and words

Yes, you can use L<Lingua::PT::Nums2Words> and similar (for other
languages). Meanwhile, before it existed we needed to write such a
conversion tool.

Here I present a subset of the rules (for numbers bellow 1000). The
generated text is Portuguese but I think you can get the idea. I'll
try to create a version for English very soon.

You can check the full code on the samples directory (file
C<num2words>).

  use Text::RewriteRules;

  RULES num2words
  100==>cem 
  1(\d\d)==>cento e $1 
  0(\d\d)==>$1
  200==>duzentos 
  300==>trezentos 
  400==>quatrocentos 
  500==>quinhentos 
  600==>seiscentos 
  700==>setecentos 
  800==>oitocentos 
  900==>novecentos 
  (\d)(\d\d)==>${1}00 e $2

  10==>dez 
  11==>onze 
  12==>doze 
  13==>treze 
  14==>catorze 
  15==>quinze 
  16==>dezasseis 
  17==>dezassete 
  18==>dezoito 
  19==>dezanove 
  20==>vinte 
  30==>trinta 
  40==>quarenta 
  50==>cinquenta 
  60==>sessenta 
  70==>setenta 
  80==>oitenta 
  90==>noventa 
  0(\d)==>$1
  (\d)(\d)==>${1}0 e $2

  1==>um 
  2==>dois 
  3==>três 
  4==>quatro 
  5==>cinco 
  6==>seis 
  7==>sete 
  8==>oito 
  9==>nove 
  0$==>zero 
  0==> 
    ==> 
   ,==>,
  ENDRULES

  num2words(123); # returns "cento e vinte e três"

=head2 Naif translator (using cursor-based rewriting)

 use Text::RewriteRules;
 %dict=(driver=>"motorista",
        the=>"o",
        of=>"de",
        car=>"carro");

 $word='\b\w+\b';

 if( b(a("I see the Driver of the car")) eq "(I) (see) o Motorista do carro" )
      {print "ok\n"}
 else {print "ko\n"}

 RULES/m a
 ($word)==>$dict{$1}!!                  defined($dict{$1})
 ($word)=e=> ucfirst($dict{lc($1)}) !!  defined($dict{lc($1)})
 ($word)==>($1)
 ENDRULES

 RULES/m b
 \bde o\b==>do
 ENDRULES

=head1 AUTHOR

Alberto Simões, C<< <ambs@cpan.org> >>

José João Almeida, C<< <jjoao@cpan.org> >>

=head1 BUGS

We know documentation is missing and you all want to use this module.
In fact we are using it a lot, what explains why we don't have the
time to write documentation.

Please report any bugs or feature requests to
C<bug-text-rewrite@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Damian Conway for Filter::Simple

=head1 COPYRIGHT & LICENSE

Copyright 2004-2012 Alberto Simões and José João Almeida, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::RewriteRules
