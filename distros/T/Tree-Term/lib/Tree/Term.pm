#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Create a parse tree from an array of terms representing an expression.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Tree::Term;
use v5.26;
our $VERSION = 20210810;                                                        # Version
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump ddx pp);
use Data::Table::Text qw(:all);
use feature qw(say state current_sub);

#D1 Parse                                                                       # Create a parse tree from an array of terms representing an expression.
my $stack      = undef;                                                         # Stack of lexical items
my $expression = undef;                                                         # Expression being parsed
my $position   = undef;                                                         # Position in expression
our %tested;                                                                    # Pairs of lexical items (b, a) such that 'b' is observed to follow 'a' in a test.
our %follows;                                                                   # Pairs of lexical items (b, a) such that 'b' is observed to follow 'a' in a test without causing a syntax error.
our %first;                                                                     # Lexical elements that can come first
our %last;                                                                      # Lexical elements that can come last

sub new($)                                                                      #P Create a new term from the indicated number of items on top of the stack
 {my ($count) = @_;                                                             # Number of terms

  @$stack >= $count or confess "Stack underflow";

  my ($operator, @operands) = splice  @$stack, -$count;                         # Remove lexical items from stack

  my $t = genHash(__PACKAGE__,                                                  # Description of a term in the expression.
     operands => @operands ? [@operands] : undef,                               # Operands to which the operator will be applied.
     operator => $operator,                                                     # Operator to be applied to one or more operands.
     up       => undef,                                                         # Parent term if this is a sub term.
   );

  $_->up = $t for grep {ref $_} @operands;                                      # Link to parent if possible

  push @$stack, $t;                                                             # Save newly created term on the stack
 }

sub LexicalCode($$$$)                                                           #P Lexical code definition
 {my ($letter, $next, $name, $short) = @_;                                      # Letter used to refer to the lexical item, letters of items that can follow this lexical item, descriptive name of lexical item, short name
  genHash(q(Tree::Term::LexicalCode),                                           # Lexical item codes.
    letter => $letter,                                                          # Letter code used to refer to the lexical item.
    next   => $next,                                                            # Letters codes of items that can follow this lexical item.
    name   => $name,                                                            # Descriptive name of lexical item.
    short  => $short,                                                           # Short name of lexical item.
   );
 }

my $LexicalCodes = genHash(q(Tree::Term::Codes),                                # Lexical item codes.
  a => LexicalCode('a', 'bpv',   q(assignment operator), qq(assign)),           # Infix operator with priority 2 binding right to left typically used in an assignment.
  b => LexicalCode('b', 'bBpsv', q(opening parenthesis), qq(OpenBracket)),      # Opening parenthesis.
  B => LexicalCode('B', 'aBdqs', q(closing parenthesis), qq(CloseBracket)),     # Closing parenthesis.
  d => LexicalCode('d', 'bpv',   q(dyadic operator),     qq(dyad)),             # Infix operator with priority 3 binding left to right typically used in arithmetic.
  p => LexicalCode('p', 'bpv',   q(prefix operator),     qq(prefix)),           # Monadic prefix operator.
  q => LexicalCode('q', 'aBdqs', q(suffix operator),     qq(suffix)),           # Monadic suffix operator.
  s => LexicalCode('s', 'bBpsv', q(semi-colon),          qq(semiColon)),        # Infix operator with priority 1 binding left to right typically used to separate statements.
  t => LexicalCode('t', 'aBdqs', q(term),                qq(term)),             # A term in the expression.
  v => LexicalCode('v', 'aBdqs', q(variable),            qq(variable)),         # A variable in the expression.
 );

my $first = 'bpsv';                                                             # First element
my $last  = 'Bqsv';                                                             # Last element

sub LexicalStructure()                                                          # Return the lexical codes and their relationships in a data structure so this information can be used in other contexts.
 {genHash(q(Tree::Term::LexicalStructure),                                      # Lexical item codes.
    codes => $LexicalCodes,                                                     # Code describing each lexical item
    first => $first,                                                            # Lexical items we can start with
    last  => $last,                                                             # Lexical items we can end with
   );
 }

sub type($)                                                                     #P Type of term
 {my ($s) = @_;                                                                 # Term to test
  return 't' if ref $s;                                                         # Term on top of stack
  substr($s, 0, 1);                                                             # Something other than a term defines its type by its first letter
 }

sub expandElement($)                                                            #P Describe a lexical element
 {my ($e) = @_;                                                                 # Element to expand
  my $x = $LexicalCodes->{type $e}->name;                                       # Expansion
   "'$x': $e"
 }

sub expandCodes($)                                                              #P Expand a string of codes
 {my ($e) = @_;                                                                 # Codes to expand
  my @c = map {qq('$_')} sort map {$LexicalCodes->{$_}->name} split //, $e;     # Codes  for next possible items
  my $c = pop @c;
  my $t = join ', ', @c;
  "$t or $c"
 }

sub expected($)                                                                 #P String of next possible lexical items
 {my ($s) = @_;                                                                 # Lexical item
  my $e = expandCodes $LexicalCodes->{type $s}->next;                           # Codes for next possible items
  "Expected: $e"
 }

sub unexpected($$$)                                                             #P Complain about an unexpected element
 {my ($element, $unexpected, $position) = @_;                                   # Last good element, unexpected element, position
  my $j = $position + 1;
  my $E = expandElement $unexpected;
  my $X = expected $element;

  my sub de($)                                                                  # Extract an error message and die
   {my ($message) = @_;                                                         # Message
    $message =~ s(\n) ( )gs;
    die "$message\n";
   }

  de <<END if ref $element;
Unexpected $E following term ending at position $j.
$X.
END
  my $S = expandElement $element;
  de <<END;
Unexpected $E following $S at position $j.
$X.
END
 }

sub syntaxError(@)                                                              # Check the syntax of an expression without parsing it. Die with a helpful message if an error occurs.  The helpful message will be slightly different from that produced by L<parse> as it cannot contain information from the non existent parse tree.
 {my (@expression) = @_;                                                        # Expression to parse
  my @e = @_;

  return '' unless @e;                                                          # An empty string is valid

  my sub test($$$)                                                              # Test a transition
   {my ($current, $following, $position) = @_;                                  # Current element, following element, position
    my $n = $LexicalCodes->{type $current}->next;                               # Elements expected next
    return if index($n, type $following) > -1;                                  # Transition allowed
    unexpected $current, $following, $position - 1;                             # Complain about the unexpected element
   }

  my sub testFirst                                                              # Test first transition
   {return if index($first, type $e[0]) > -1;                                   # Transition allowed
    my $E = expandElement $e[0];
    my $C = expandCodes $first;
    die <<END;
Expression must start with $C, not $E.
END
   }

  my sub testLast($$)                                                           # Test last transition
   {my ($current, $position) = @_;                                              # Current element, position
    return if index($last, type $current) > -1;                                 # Transition allowed
    my $C = expandElement $current;
    my $E = expected $current;
    die <<END;
$E after final $C.
END
   }

  if (1)                                                                        # Test parentheses
   {my @b;
    for my $i(keys @e)                                                          # Each element
     {my $e = $e[$i];
      if (type($e) eq 'b')                                                      # Open
       {push @b, [$i, $e];
       }
      elsif (type($e) eq 'B')                                                   # Close
       {if (@b > 0)
         {my ($h, $a) = pop(@b)->@*;
          my $j = $i + 1;
          my $g = $h + 1;
          die <<END if substr($a, 1) ne substr($e, 1);                          # Close fails to match
Parenthesis mismatch between $a at position $g and $e at position $j.
END
         }
        else                                                                    # No corresponding open
         {my $j = $i + 1;
          my $E = $i ? expected($e[$i-1]) : testFirst;                          # What we might have had instead
          die <<END;
Unexpected closing parenthesis $e at position $j. $E.
END
         }
       }
     }
    if (@b > 0)                                                                 # Closing parentheses at end
     {my ($h, $a) = pop(@b)->@*;
      my $g = $h + 1;
          die <<END;
No closing parenthesis matching $a at position $g.
END
     }
   }

  if (1)                                                                        # Test transitions
   {testFirst $e[0];                                                            # First transition
    test      $e[$_-1], $e[$_], $_+1 for 1..$#e;                                # Each element beyond the first
    testLast  $e[-1], scalar @e;                                                # Final transition
   }
 }

BEGIN                                                                           # Generate recognition routines.
 {for my $t(qw(abdps bst t))
   {my $c = <<'END';
sub check_XXXX()                                                                #P Check that the top of the stack has one of XXXX
 {$tested   {type $$expression[$position]}{type $$expression[$position-1]}++;   # Check that one lexical item has been seen to follow after another
  if (index("XXXX", type($$stack[-1])) > -1)                                    # Check type allowed
   {$follows{type $$expression[$position]}{type $$expression[$position-1]}++;   # Shows that one lexical item can possibly follow after another in some circumstances
    return 1;                                                                   # Type allowed
   }
  unexpected $$stack[-1], $$expression[$position], $position;                   # Complain about an unexpected type
 }
END
         $c =~ s(XXXX) ($t)gs;
    eval $c; $@ and confess "$@\n";
   }

  for my $t(qw(ads b B bpsv bst d p s v))                                       # Test various sets of items
   {my $c = <<'END';
sub test_XXXX($)                                                                #P Check that we have XXXX
 {my ($item) = @_;                                                              # Item to test
  !ref($item) and index('XXXX',  substr($item, 0, 1)) > -1
 }
END
         $c =~ s(XXXX) ($t)gs;
    eval $c; $@ and confess "$@\n";
   }
 }

sub test_t($)                                                                   #P Check that we have a term
 {my ($item) = @_;                                                              # Item to test
  ref $item
 }

sub reduce($)                                                                   #P Reduce the stack at the specified priority
 {my ($priority) = @_;                                                          # Priority
  #lll "Reduce at $priority: ", scalar(@s), "\n", dump([@s]);

  if (@$stack >= 3)                                                             # term infix-operator term
   {my ($l, $d, $r) = ($$stack[-3], $$stack[-2], $$stack[-1]);                  # Left infix right

    if     (test_t($l))                                                         # Parse out infix operator expression
     {if   (test_t($r))
       {if ($priority == 1 ? test_ads($d) :  test_d($d))                        # Amount of reduction
         {pop  @$stack for 1..3;
          push @$stack, $d, $l, $r;
          new 3;
          return 1;
         }
       }
     }

    if     (test_b($l))                                                         # Parse parenthesized term keeping the opening parenthesis
     {if   (test_B($r))
       {if (test_t($d))
         {pop  @$stack for 1..3;
          push @$stack, "$l$r", $d;
          new 2;
          return 1;
         }
       }
     }
   }

  if (@$stack >= 2)                                                             # Convert an empty pair of parentheses to an empty term
   {my ($l, $r) = ($$stack[-2], $$stack[-1]);
    if   (test_b($l))                                                           # Empty pair of parentheses
     {if (test_B($r))
       {pop  @$stack for 1..2;
        push @$stack, "$l$r";
        new 1;
        return 1;
       }
     }
    if (test_s($l))                                                             # Semi-colon, close implies remove unneeded semi
     {if (test_B($r))
       {pop  @$stack for 1..2;
        push @$stack, $r;
        return 1;
       }
     }
    if (test_p($l))                                                             # Prefix, term
     {if (test_t($r))
       {new 2;
        return 1;
       }
     }
   }

  0                                                                             # No move made
 }

sub reduce1()                                                                   #P Reduce the stack at priority 1
 {reduce 1;
 }

sub reduce2()                                                                   #P Reduce the stack at priority 2
 {reduce 2;
 }

sub pushElement()                                                               #P Push an element
 {push @$stack, $$expression[$position];
 }

sub accept_a()                                                                  #P Assign
 {check_t;
  1 while reduce2;
  pushElement;
 }

sub accept_b()                                                                  #P Open
 {check_abdps;
  pushElement;
 }

sub accept_B()                                                                  #P Closing parenthesis
 {check_bst;
  1 while reduce1;
  pushElement;
  1 while reduce1;
  check_bst;
 }

sub accept_d()                                                                  #P Infix but not assign or semi-colon
 {check_t;
  pushElement;
 }

sub accept_p()                                                                  #P Prefix
 {check_abdps;
  pushElement;
 }

sub accept_q()                                                                  #P Post fix
 {check_t;
  my $p = pop @$stack;
  pushElement;
  push @$stack, $p;
  new 2;
 }

sub accept_s()                                                                  #P Semi colon
 {check_bst;
  if (!test_t($$stack[-1]))                                                     # Insert an empty element between two consecutive semicolons
   {push @$stack, 'empty1';
    new 1;
   }
  1 while reduce1;
  pushElement;
 }

sub accept_v()                                                                  #P Variable
 {check_abdps;
  pushElement;
  new 1;
  new 2 while @$stack >= 2 and test_p($$stack[-2]);                             # Check for preceding prefix operators
 }
                                                                                # Action on each lexical item
my $Accept =                                                                    # Dispatch the action associated with the lexical item
 {a => \&accept_a,                                                              # Assign
  b => \&accept_b,                                                              # Open
  B => \&accept_B,                                                              # Closing parenthesis
  d => \&accept_d,                                                              # Infix but not assign or semi-colon
  p => \&accept_p,                                                              # Prefix
  q => \&accept_q,                                                              # Post fix
  s => \&accept_s,                                                              # Semi colon
  v => \&accept_v,                                                              # Variable
 };

sub parseExpression()                                                           #P Parse an expression.
 {if (@$expression)
   {my $e = $$expression[$position = 0];

    my $E = expandElement $e;
    die <<END =~ s(\n) ( )gsr =~ s(\s+\Z) (\n)gsr if !test_bpsv($e);
Expression must start with 'opening parenthesis', 'prefix
operator', 'semi-colon' or 'variable', not $E.
END
    if    (test_v($e))                                                          # Single variable
     {push @$stack, $e;
      new 1;
     }
    else
     {if (test_s($e))                                                           # Semi
       {push @$stack, 'empty2';
        new 1;
       }
      push @$stack, $e;
     }
   }
  else                                                                          # Empty expression
   {return undef;
   }

  for(1..$#$expression)                                                         # Each input element
   {$$Accept{substr($$expression[$position = $_], 0, 1)}();                     # Dispatch the action associated with the lexical item
   }

  if (index($last,   type $$expression[-1]) == -1)                              # Check for incomplete expression
   {my $C = expandElement $$expression[-1];
    my $E = expected      $$expression[-1];
    die <<END;
$E after final $C.
END
   }

  pop @$stack while @$stack > 1 and $$stack[-1] =~ m(s);                        # Remove any trailing semi colons
  1 while reduce1;                                                              # Final reductions

  if (@$stack != 1)                                                             # Incomplete expression
   {my $E = expected $$expression[-1];
    die "Incomplete expression. $E.\n";
   }

  $first{type $$expression[ 0]}++;                                              # Capture valid first and last lexical elements
  $last {type $$expression[-1]}++;

  $$stack[0]                                                                    # The resulting parse tree
 } # parseExpression

sub parse(@)                                                                    # Parse an expression.
 {my (@expression)    = @_;                                                     # Expression to parse
  my $s = $stack;
          $stack      = [];                                                     # Clear the current stack - the things we do to speed things up.
  my $x = $expression;
          $expression = \@expression;                                           # Clear the current expression
  my $p = $position;
          $position   = 0;                                                      # Clear the current parse position

  my $e = eval {parseExpression};
  my $r = $@;                                                                   # Save any error message
  $stack = $s; $expression = $x; $position = $p;                                # Restore the stack and expression being parsed
  die $r if $r;                                                                 # Die again if we died the last time

  $e                                                                            # Otherwise return the parse tree
 } # parse

#D1 Validate                                                                    # Validating is the same as parsing except we do not start at the beginning, instead we start at any lexical element and proceed a few steps from there.

sub validPair($$)                                                               # Confirm that the specified pair of lexical elements can occur as a sequence.
 {my ($A, $B) = @_;                                                             # First element, second element
  my $a = type $A;
  my $b = type $B;
  if (my $l = $$LexicalCodes{$a})
   {return 1 if (index $l->next, $b) > -1;
   }
  undef
 }

#D1 Print                                                                       # Print a parse tree to make it easy to visualize its structure.

sub depth($)                                                                    #P Depth of a term in an expression.
 {my ($term) = @_;                                                              # Term
  my $d = 0;
  for(my $t = $term; $t; $t = $t->up) {++$d}
  $d
 }

sub listTerms($)                                                                #P List the terms in an expression in post order
 {my ($expression) = @_;                                                        # Root term
  my @t;                                                                        # Terms

  sub                                                                           # Recurse through terms
   {my ($e) = @_;                                                               # Term
    my $o = $e->operands;
    return unless $e;                                                           # Operator
    if (my @o = $o ? grep {ref $_} @$o : ())                                    # Operands
     {my ($p, @p) = @o;
      __SUB__->($p);                                                            # First operand
      push @t, $e;                                                              # Operator
      __SUB__->($_) for @p;                                                     # Second and subsequent operands
     }
    else                                                                        # No operands
     {push @t, $e;                                                              # Operator
     }
   } ->($expression);

  @t
 }

sub flat($@)                                                                    # Print the terms in the expression as a tree from left right to make it easier to visualize the structure of the tree.
 {my ($expression, @title) = @_;                                                # Root term, optional title
  my @t = $expression->listTerms;                                               # Terms in expression in post order
  my @s;                                                                        # Print

  my sub align                                                                  # Align the ends of the lines
   {my $L = 0;                                                                  # Longest line
    for my $s(@s)
     {my $l = length $s; $L = $l if $l > $L;
     }

    for my $i(keys @s)                                                          # Pad to longest
     {my $s = $s[$i] =~ s/\s+\Z//rs;
      my $l = length($s);
      if ($l < $L)
       {my $p = ' ' x ($L - $l);
        $s[$i] = $s . $p;
       }
     }
   };

  for my $t(@t)                                                                 # Initialize output rectangle
   {$s[$_] //= '' for 0..$t->depth;
   }

  for my $t(@t)                                                                 # Traverse tree
   {my $d = $t->depth;
    my $p = $t->operator;                                                       # Operator
    my $P = $p =~ s(\A\w+?_) ()gsr;                                              # Remove leading type character if followed by underscore as this make for clearer results

    align if $p =~ m(\A(a|d|s));                                                # Shift over for some components

    $s[$d] .= " $P";                                                            # Describe operator or operand with type component removed if requested
    align if $p !~ m(\A(p|q|v));                                                # Vertical for some components
   }

  shift @s while @s and $s[ 0] =~ m(\A\s*\Z)s;                                  # Remove leading blank lines

  for(@s)                                                                       # Clean up trailing blanks so that tests are not affected by spurious white space mismatches
   {s/\s+\n/\n/gs; s/\s+\Z//gs;
   }

  unshift @s, join(' ', @title) if @title;                                      # Add title

  join "\n", @s, '';
 }

#D
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(
 );
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Tree::Term - Create a parse tree from an array of terms representing an expression.

=head1 Synopsis

The expression to L<parse> is presented as an array of words, the first letter
of each word indicates its lexical role as in:

  my @e = qw(

  v_sub a_is v_array as
    v1 d_== v2  a_then v3 d_plus  v4 a_else
    v5 d_== v6  a_then v7 d_minus v8 a_else v9 d_times b v10 a_+ v11 B);

Where:

  a assign     - infix operator with priority 2 binding right to left
  b open       - open parenthesis
  B close      - close parenthesis
  d dyad       - infix operator with priority 3 binding left to right
  p prefix     - monadic prefix operator
  q suffix     - monadic suffix operator
  s semi-colon - infix operator with priority 1 binding left to right
  v variable   - a variable in the expression

The results of parsing the expression can be printed with L<flat> which
provides a left to right representation of the parse tree.

  is_deeply parse(@e)->flat, <<END;
     is
 sub          as
        array             then
                    ==                    else
                 v1    v2         plus                  then
                               v3      v4         ==                     else
                                               v5    v6         minus            times
                                                             v7       v8      v9           +
                                                                                       v10   v11
END

=head1 Description

Create a parse tree from an array of terms representing an expression.


Version 20210724.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Parse

Create a parse tree from an array of terms representing an expression.

=head2 LexicalStructure()

Return the lexical codes and their relationships in a data structure so this information can be used in other contexts.


B<Example:>



  is_deeply LexicalStructure,                                                       # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 syntaxError(@expression)

Check the syntax of an expression without parsing it. Die with a helpful message if an error occurs.  The helpful message will be slightly different from that produced by L<parse|https://en.wikipedia.org/wiki/Parsing> as it cannot contain information from the non existent parse tree.

     Parameter    Description
  1  @expression  Expression to parse

B<Example:>


  if (1)

   {eval {syntaxError(qw(v1 p1))};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok -1 < index $@, <<END =~ s({a}) ( )gsr;
  Unexpected 'prefix operator': p1 following 'variable': v1 at position 2.
  Expected: 'assignment operator', 'closing parenthesis',
  'dyadic operator', 'semi-colon' or 'suffix operator'.
  END
   }


=head2 parse(@expression)

Parse an expression.

     Parameter    Description
  1  @expression  Expression to parse

B<Example:>


  ok T [qw(v_sub a_is v_array as v1 d_== v2 a_then v3 d_plus v4 a_else v5 d_== v6 a_then v7 d_minus v8 a_else v9 d_times b v10 a_+ v11 B)], <<END;
       is
   sub          as
          array             then
                      ==                    else
                   v1    v2         plus                  then
                                 v3      v4         ==                     else
                                                 v5    v6         minus            times
                                                               v7       v8      v9           +
                                                                                         v10   v11
  END
  }

  if (1) {
    ok  validPair('B', 'd');
    ok  validPair('b', 'B');
    ok  validPair('v', 'a');
    ok !validPair('v', 'v');


=head1 Validate

Validating is the same as parsing except we do not start at the beginning, instead we start at any lexical element and proceed a few steps from there.

=head2 validPair($A, $B)

Confirm that the specified pair of lexical elements can occur as a sequence.

     Parameter  Description
  1  $A         First element
  2  $B         Second element

B<Example:>



    ok  validPair('B', 'd');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  validPair('b', 'B');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  validPair('v', 'a');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !validPair('v', 'v');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head1 Print

Print a parse tree to make it easy to visualize its structure.

=head2 flat($expression, @title)

Print the terms in the expression as a tree from left right to make it easier to visualize the structure of the tree.

     Parameter    Description
  1  $expression  Root term
  2  @title       Optional title

B<Example:>



   my @e = qw(v1 a2 v3 d4 v5 s6 v8 a9 v10);


   is_deeply parse(@e)->flat, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                  s6
      a2                a9
   v1       d4       v8    v10
         v3    v5
  END
  }

  ok T [qw(v1 a2 v3 s s s  v4 a5 v6 s s)], <<END;
                                         s
                              s            empty1
                     s             a5
            s          empty1   v4    v6
      a2      empty1
   v1    v3
  END

  ok T [qw(b B)], <<END;
   empty1
  END

  ok T [qw(b b B B)], <<END;
   empty1
  END

  ok T [qw(b b v1 B B)], <<END;
   v1
  END

  ok T [qw(b b v1 a2 v3 B B)], <<END;
      a2
   v1    v3
  END

  ok T [qw(b b v1 a2 v3 d4 v5 B B)], <<END;
      a2
   v1       d4
         v3    v5
  END

  ok T [qw(p1 v1)], <<END;
   p1
   v1
  END

  ok T [qw(p2 p1 v1)], <<END;
   p2
   p1
   v1
  END

  ok T [qw(v1 q1)], <<END;
   q1
   v1
  END

  ok T [qw(v1 q1 q2)], <<END;
   q2
   q1
   v1
  END

  ok T [qw(p2 p1 v1 q1 q2)], <<END;
   q2
   q1
   p2
   p1
   v1
  END

  ok T [qw(p2 p1 v1 q1 q2 d3 p4 p3 v2 q3 q4)], <<END;
      d3
   q2    q4
   q1    q3
   p2    p4
   p1    p3
   v1    v2
  END

  ok T [qw(p2 p1 v1 q1 q2 d3 p4 p3 v2 q3 q4  d4 p6 p5 v3 q5 q6 s)], <<END;
      d3
   q2       d4
   q1    q4    q6
   p2    q3    q5
   p1    p4    p6
   v1    p3    p5
         v2    v3
  END

  ok T [qw(b s B)], <<END;
   empty1
  END

  ok T [qw(b s s B)], <<END;
          s
   empty1   empty1
  END


  if (1) {

   my @e = qw(b b p2 p1 v1 q1 q2 B d3 b p4 p3 v2 q3 q4 d4 p6 p5 v3 q5 q6 B s B s);


   is_deeply parse(@e)->flat, <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      d3
   q2       d4
   q1    q4    q6
   p2    q3    q5
   p1    p4    p6
   v1    p3    p5
         v2    v3
  END

  }

  ok T [qw(b b v1 B s B s)], <<END;
   v1
  END

  ok T [qw(v1 q1 s)], <<END;
   q1
   v1
  END

  ok T [qw(b b v1 q1 q2 B q3 q4 s B q5 q6  s)], <<END;
   q6
   q5
   q4
   q3
   q2
   q1
   v1
  END

  ok T [qw(p1 p2 b v1 B)], <<END;
   p1
   p2
   v1
  END

  ok T [qw(v1 d1 p1 p2 v2)], <<END;
      d1
   v1    p1
         p2
         v2
  END

  ok T [qw(p1 p2 b p3 p4 b p5 p6 v1 d1 v2 q1 q2 B q3 q4 s B q5 q6  s)], <<END;
         q6
         q5
         p1
         p2
         q4
         q3
         p3
         p4
      d1
   p5    q2
   p6    q1
   v1    v2
  END

  ok T [qw(p1 p2 b p3 p4 b p5 p6 v1 a1 v2 q1 q2 B q3 q4 s B q5 q6  s)], <<END;
         q6
         q5
         p1
         p2
         q4
         q3
         p3
         p4
      a1
   p5    q2
   p6    q1
   v1    v2
  END

  ok T [qw(b v1 B d1 b v2 B)], <<END;
      d1
   v1    v2
  END

  ok T [qw(b v1 B q1 q2 d1 b v2 B)], <<END;
      d1
   q2    v2
   q1
   v1
  END

  ok T [qw(v1 s)], <<END;
   v1
  END

  ok T [qw(v1 s s)], <<END;
      s
   v1   empty1
  END

  ok T [qw(v1 s b s B)], <<END;
      s
   v1   empty1
  END

  ok T [qw(v1 s b b s s B B)], <<END;
      s
   v1          s
        empty1   empty1
  END

  ok T [qw(b v1 s B s s)], <<END;
      s
   v1   empty1
  END

  ok T [qw(v1 a b1 b2 v2 B2 B1 s)], <<END;
      a
   v1   v2
  END

  ok T [qw(v1 a1 b1 v2 a2 b2 v3 B2 B1 s)], <<END;
      a1
   v1       a2
         v2    v3
  END

  ok T [qw(v1 a1 p1 v2)], <<END;
      a1
   v1    p1
         v2
  END

  ok T [qw(b1 v1 q1 q2 B1)], <<END;
   q2
   q1
   v1
  END

  ok T [qw(b1 v1 q1 q2 s B1)], <<END;
   q2
   q1
   v1
  END

  ok T [qw(p1 b1 v1 B1 q1)], <<END;
   q1
   p1
   v1
  END

  ok T [qw(b1 v1 B1 a1 v2)], <<END;
      a1
   v1    v2
  END

  ok T [qw(v1 q1 a1 v2)], <<END;
      a1
   q1    v2
   v1
  END

  ok T [qw(s1 p1 v1)], <<END;
          s1
   empty2    p1
             v1
  END

  ok E <<END;
  a
  Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'assignment operator': a.
  Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'assignment operator': a.
  END

  ok E <<END;
  B
  Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'closing parenthesis': B.
  Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'closing parenthesis': B.
  END

  ok E <<END;
  d1
  Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'dyadic operator': d1.
  Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'dyadic operator': d1.
  END

  ok E <<END;
  p1
  Expected: 'opening parenthesis', 'prefix operator' or 'variable' after final 'prefix operator': p1.
  Expected: 'opening parenthesis', 'prefix operator' or 'variable' after final 'prefix operator': p1.
  END

  ok E <<END;
  q1
  Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'suffix operator': q1.
  Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'suffix operator': q1.
  END

  ok E <<END;
  s


  END

  ok E <<END;
  v1


  END

  ok E <<END;
  b v1
  Incomplete expression. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
  No closing parenthesis matching b at position 1.
  END

  ok E <<END;
  b v1 B B
  Unexpected 'closing parenthesis': B following 'closing parenthesis': B at position 4. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
  Unexpected closing parenthesis B at position 4. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
  END

  ok E <<END;
  v1 d1 d2 v2
  Unexpected 'dyadic operator': d2 following 'dyadic operator': d1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
  Unexpected 'dyadic operator': d2 following 'dyadic operator': d1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
  END

  ok E <<END;
  v1 p1
  Unexpected 'prefix operator': p1 following term ending at position 2. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
  Unexpected 'prefix operator': p1 following 'variable': v1 at position 2. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
  END

  ok E <<END;
  b1 B1 v1
  Unexpected 'variable': v1 following term ending at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
  Unexpected 'variable': v1 following 'closing parenthesis': B1 at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
  END

  ok E <<END;
  b1 B1 p1 v1
  Unexpected 'prefix operator': p1 following term ending at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
  Unexpected 'prefix operator': p1 following 'closing parenthesis': B1 at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
  END

  if (1)
   {eval {syntaxError(qw(v1 p1))};
    ok -1 < index $@, <<END =~ s({a}) ( )gsr;
  Unexpected 'prefix operator': p1 following 'variable': v1 at position 2.
  Expected: 'assignment operator', 'closing parenthesis',
  'dyadic operator', 'semi-colon' or 'suffix operator'.
  END



=head1 Hash Definitions




=head2 Tree::Term Definition


Description of a term in the expression.




=head3 Output fields


=head4 operands

Operands to which the operator will be applied.

=head4 operator

Operator to be applied to one or more operands.

=head4 up

Parent term if this is a sub term.



=head2 Tree::Term::Codes Definition


Lexical item codes.




=head3 Output fields


=head4 B

Closing parenthesis.

=head4 a

Infix operator with priority 2 binding right to left typically used in an assignment.

=head4 b

Opening parenthesis.

=head4 d

Infix operator with priority 3 binding left to right typically used in arithmetic.

=head4 p

Monadic prefix operator.

=head4 q

Monadic suffix operator.

=head4 s

Infix operator with priority 1 binding left to right typically used to separate statements.

=head4 t

A term in the expression.

=head4 v

A variable in the expression.



=head2 Tree::Term::LexicalCode Definition


Lexical item codes.




=head3 Output fields


=head4 letter

Letter code used to refer to the lexical item.

=head4 name

Descriptive name of lexical item.

=head4 next

Letters codes of items that can follow this lexical item.



=head2 Tree::Term::LexicalStructure Definition


Lexical item codes.




=head3 Output fields


=head4 codes

Code describing each lexical item

=head4 first

Lexical items we can start with

=head4 last

Lexical items we can end with



=head1 Private Methods

=head2 new($count)

Create a new term from the indicated number of items on top of the stack

     Parameter  Description
  1  $count     Number of terms

=head2 LexicalCode($letter, $next, $name)

Lexical code definition

     Parameter  Description
  1  $letter    Letter used to refer to the lexical item
  2  $next      Letters of items that can follow this lexical item
  3  $name      Descriptive name of lexical item

=head2 type($s)

Type of term

     Parameter  Description
  1  $s         Term to test

=head2 expandElement($e)

Describe a lexical element

     Parameter  Description
  1  $e         Element to expand

=head2 expandCodes($e)

Expand a string of codes

     Parameter  Description
  1  $e         Codes to expand

=head2 expected($s)

String of next possible lexical items

     Parameter  Description
  1  $s         Lexical item

=head2 unexpected($element, $unexpected, $position)

Complain about an unexpected element

     Parameter    Description
  1  $element     Last good element
  2  $unexpected  Unexpected element
  3  $position    Position

=head2 check_XXXX()

Check that the top of the stack has one of XXXX


=head2 test_XXXX($item)

Check that we have XXXX

     Parameter  Description
  1  $item      Item to test

=head2 test_t($item)

Check that we have a term

     Parameter  Description
  1  $item      Item to test

=head2 reduce($priority)

Reduce the stack at the specified priority

     Parameter  Description
  1  $priority  Priority

=head2 reduce1()

Reduce the stack at priority 1


=head2 reduce2()

Reduce the stack at priority 2


=head2 pushElement()

Push an element


=head2 accept_a()

Assign


=head2 accept_b()

Open


=head2 accept_B()

Closing parenthesis


=head2 accept_d()

Infix but not assign or semi-colon


=head2 accept_p()

Prefix


=head2 accept_q()

Post fix


=head2 accept_s()

Semi colon


=head2 accept_v()

Variable


=head2 parseExpression()

Parse an expression.


=head2 depth($term)

Depth of a term in an expression.

     Parameter  Description
  1  $term      Term

=head2 listTerms($expression)

List the terms in an expression in post order

     Parameter    Description
  1  $expression  Root term


=head1 Index


1 L<accept_a|/accept_a> - Assign

2 L<accept_B|/accept_B> - Closing parenthesis

3 L<accept_b|/accept_b> - Open

4 L<accept_d|/accept_d> - Infix but not assign or semi-colon

5 L<accept_p|/accept_p> - Prefix

6 L<accept_q|/accept_q> - Post fix

7 L<accept_s|/accept_s> - Semi colon

8 L<accept_v|/accept_v> - Variable

9 L<check_XXXX|/check_XXXX> - Check that the top of the stack has one of XXXX

10 L<depth|/depth> - Depth of a term in an expression.

11 L<expandCodes|/expandCodes> - Expand a string of codes

12 L<expandElement|/expandElement> - Describe a lexical element

13 L<expected|/expected> - String of next possible lexical items

14 L<flat|/flat> - Print the terms in the expression as a tree from left right to make it easier to visualize the structure of the tree.

15 L<LexicalCode|/LexicalCode> - Lexical code definition

16 L<LexicalStructure|/LexicalStructure> - Return the lexical codes and their relationships in a data structure so this information can be used in other contexts.

17 L<listTerms|/listTerms> - List the terms in an expression in post order

18 L<new|/new> - Create a new term from the indicated number of items on top of the stack

19 L<parse|/parse> - Parse an expression.

20 L<parseExpression|/parseExpression> - Parse an expression.

21 L<pushElement|/pushElement> - Push an element

22 L<reduce|/reduce> - Reduce the stack at the specified priority

23 L<reduce1|/reduce1> - Reduce the stack at priority 1

24 L<reduce2|/reduce2> - Reduce the stack at priority 2

25 L<syntaxError|/syntaxError> - Check the syntax of an expression without parsing it.

26 L<test_t|/test_t> - Check that we have a term

27 L<test_XXXX|/test_XXXX> - Check that we have XXXX

28 L<type|/type> - Type of term

29 L<unexpected|/unexpected> - Complain about an unexpected element

30 L<validPair|/validPair> - Confirm that the specified pair of lexical elements can occur as a sequence.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Tree::Term

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
#__DATA__
use Time::HiRes qw(time);
use Test::More;

my $develop   = -e q(/home/phil/);                                              # Developing
my $log       = q(/home/phil/perl/cpan/TreeTerm/lib/Tree/zzz.txt);              # Log file
my $localTest = ((caller(1))[0]//'Tree::Term') eq "Tree::Term";                 # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux|darwin)i)                                                # Supported systems
 {plan tests => 222
 }
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

sub T                                                                           #P Test a parse
 {my ($expression, $expected) = @_;                                             # Expression, expected result
  syntaxError @$expression;                                                     # Syntax check without creating parse tree
  my $g = parse(@$expression)->flat;
  my $r = $g eq $expected;
  owf($log, $g) if -e $log;                                                     # Save result if testing
  confess "Failed test" unless $r;
  $r
 }

sub E($)                                                                        #P Test a parse error
 {my ($text) = @_;
  my ($test, $parse, $syntax) = split /\n/,  $text;                             # Parse test description

  my @e = split /\s+/, $test;
  my $e = 0;
  eval {parse       @e}; ++$e unless index($@, $parse)  > -1; my $a = $@ // '';
  eval {syntaxError @e}; ++$e unless index($@, $syntax) > -1; my $b = $@ // '';
  if ($e)
   {owf($log, "$a$b") if -e $log;                                               # Save result if testing
    confess;
   }
  !$e
 }

my $startTime = time;

eval {goto latest};

ok T [qw(v1)], <<END;
 v1
END

ok T [qw(s)], <<END;
 empty2
END

ok T [qw(s s)], <<END;
        s
 empty2   empty1
END

ok T [qw(v1 d2 v3)], <<END;
    d2
 v1    v3
END

ok T [qw(v1 a2 v3)], <<END;
    a2
 v1    v3
END

ok T [qw(v1 a2 v3 d4 v5)], <<END;
    a2
 v1       d4
       v3    v5
END

if (1) {                                                                        #Tflat

 my @e = qw(v1 a2 v3 d4 v5 s6 v8 a9 v10);

 is_deeply parse(@e)->flat, <<END;
                s6
    a2                a9
 v1       d4       v8    v10
       v3    v5
END
}

ok T [qw(v1 a2 v3 s s s  v4 a5 v6 s s)], <<END;
                                       s
                            s            empty1
                   s             a5
          s          empty1   v4    v6
    a2      empty1
 v1    v3
END

ok T [qw(b B)], <<END;
 bB
END

ok T [qw(b b B B)], <<END;
    bB
 bB
END

ok T [qw(b b v1 B B)], <<END;
    bB
 bB
 v1
END

ok T [qw(b b v1 a2 v3 B B)], <<END;
          bB
       bB
    a2
 v1    v3
END

ok T [qw(b b v1 a2 v3 d4 v5 B B)], <<END;
                bB
             bB
    a2
 v1       d4
       v3    v5
END

ok T [qw(p1 v1)], <<END;
 p1
 v1
END

ok T [qw(p2 p1 v1)], <<END;
 p2
 p1
 v1
END

ok T [qw(v1 q1)], <<END;
 q1
 v1
END

ok T [qw(v1 q1 q2)], <<END;
 q2
 q1
 v1
END

ok T [qw(p2 p1 v1 q1 q2)], <<END;
 q2
 q1
 p2
 p1
 v1
END

ok T [qw(p2 p1 v1 q1 q2 d3 p4 p3 v2 q3 q4)], <<END;
    d3
 q2    q4
 q1    q3
 p2    p4
 p1    p3
 v1    v2
END

ok T [qw(p2 p1 v1 q1 q2 d3 p4 p3 v2 q3 q4  d4 p6 p5 v3 q5 q6 s)], <<END;
    d3
 q2       d4
 q1    q4    q6
 p2    q3    q5
 p1    p4    p6
 v1    p3    p5
       v2    v3
END

ok T [qw(b s B)], <<END;
        bB
 empty1
END

ok T [qw(b s s B)], <<END;
                 bB
        s
 empty1   empty1
END


if (1) {

 my @e = qw(b b p2 p1 v1 q1 q2 B d3 b p4 p3 v2 q3 q4 d4 p6 p5 v3 q5 q6 B s B s);

 ok T [@e], <<END;
                bB
    d3
 bB          bB
 q2       d4
 q1    q4    q6
 p2    q3    q5
 p1    p4    p6
 v1    p3    p5
       v2    v3
END

}

ok T [qw(b b v1 B s B s)], <<END;
    bB
 bB
 v1
END

ok T [qw(v1 q1 s)], <<END;
 q1
 v1
END

ok T [qw(b b v1 q1 q2 B q3 q4 s B q5 q6  s)], <<END;
       q6
       q5
    bB
    q4
    q3
 bB
 q2
 q1
 v1
END

ok T [qw(p1 p2 b v1 B)], <<END;
    p1
    p2
 bB
 v1
END

ok T [qw(v1 d1 p1 p2 v2)], <<END;
    d1
 v1    p1
       p2
       v2
END

ok T [qw(p1 p2 b p3 p4 b p5 p6 v1 d1 v2 q1 q2 B q3 q4 s B q5 q6  s)], <<END;
             q6
             q5
             p1
             p2
          bB
          q4
          q3
          p3
          p4
       bB
    d1
 p5    q2
 p6    q1
 v1    v2
END

ok T [qw(p1 p2 b p3 p4 b p5 p6 v1 a1 v2 q1 q2 B q3 q4 s B q5 q6  s)], <<END;
             q6
             q5
             p1
             p2
          bB
          q4
          q3
          p3
          p4
       bB
    a1
 p5    q2
 p6    q1
 v1    v2
END

ok T [qw(b v1 B d1 b v2 B)], <<END;
    d1
 bB    bB
 v1    v2
END

ok T [qw(b v1 B q1 q2 d1 b v2 B)], <<END;
       d1
    q2    bB
    q1    v2
 bB
 v1
END

ok T [qw(v1 s)], <<END;
 v1
END

ok T [qw(v1 s s)], <<END;
    s
 v1   empty1
END

ok T [qw(v1 s b s B)], <<END;
    s
 v1          bB
      empty1
END

ok T [qw(v1 s b b s s B B)], <<END;
    s
 v1                      bB
                      bB
             s
      empty1   empty1
END

ok T [qw(b v1 s B s s)], <<END;
    s
 bB   empty1
 v1
END

ok T [qw(v1 a b1 b2 v2 B2 B1 s)], <<END;
    a
 v1        b1B1
      b2B2
      v2
END

ok T [qw(v1 a1 b1 v2 a2 b2 v3 B2 B1 s)], <<END;
    a1
 v1               b1B1
          a2
       v2    b2B2
             v3
END

ok T [qw(v1 a1 p1 v2)], <<END;
    a1
 v1    p1
       v2
END

ok T [qw(b1 v1 q1 q2 B1)], <<END;
 b1B1
 q2
 q1
 v1
END

ok T [qw(b1 v1 q1 q2 s B1)], <<END;
 b1B1
 q2
 q1
 v1
END

ok T [qw(p1 b1 v1 B1 q1)], <<END;
      q1
      p1
 b1B1
 v1
END

ok T [qw(b1 v1 B1 a1 v2)], <<END;
      a1
 b1B1    v2
 v1
END

ok T [qw(v1 q1 a1 v2)], <<END;
    a1
 q1    v2
 v1
END

ok T [qw(s1 p1 v1)], <<END;
        s1
 empty2    p1
           v1
END

ok E <<END;
a
Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'assignment operator': a.
Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'assignment operator': a.
END

ok E <<END;
B
Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'closing parenthesis': B.
Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'closing parenthesis': B.
END

ok E <<END;
d1
Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'dyadic operator': d1.
Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'dyadic operator': d1.
END

ok E <<END;
p1
Expected: 'opening parenthesis', 'prefix operator' or 'variable' after final 'prefix operator': p1.
Expected: 'opening parenthesis', 'prefix operator' or 'variable' after final 'prefix operator': p1.
END

ok E <<END;
q1
Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'suffix operator': q1.
Expression must start with 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable', not 'suffix operator': q1.
END

ok E <<END;
s


END

ok E <<END;
v1


END

ok E <<END;
b v1
Incomplete expression. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
No closing parenthesis matching b at position 1.
END

ok E <<END;
b v1 B B
Unexpected 'closing parenthesis': B following 'closing parenthesis': B at position 4. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
Unexpected closing parenthesis B at position 4. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
END

ok E <<END;
v1 d1 d2 v2
Unexpected 'dyadic operator': d2 following 'dyadic operator': d1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'dyadic operator': d2 following 'dyadic operator': d1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
v1 p1
Unexpected 'prefix operator': p1 following term ending at position 2. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
Unexpected 'prefix operator': p1 following 'variable': v1 at position 2. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
END

ok E <<END;
b1 B1 v1
Unexpected 'variable': v1 following term ending at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
Unexpected 'variable': v1 following 'closing parenthesis': B1 at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
END

ok E <<END;
b1 B1 p1 v1
Unexpected 'prefix operator': p1 following term ending at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
Unexpected 'prefix operator': p1 following 'closing parenthesis': B1 at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
END

if (1)                                                                          #TsyntaxError
 {eval {syntaxError(qw(v1 p1))};
  ok -1 < index $@, <<END =~ s(\x{a}) ( )gsr;
Unexpected 'prefix operator': p1 following 'variable': v1 at position 2.
Expected: 'assignment operator', 'closing parenthesis',
'dyadic operator', 'semi-colon' or 'suffix operator'.
END
 }

ok E <<END;
v1 q1 v2
Unexpected 'variable': v2 following term ending at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
Unexpected 'variable': v2 following 'suffix operator': q1 at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
END

ok E <<END;
b1 v2 a2 B1
Unexpected 'closing parenthesis': B1 following 'assignment operator': a2 at position 4. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'closing parenthesis': B1 following 'assignment operator': a2 at position 4. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
b1 v2 d2 B1
Unexpected 'closing parenthesis': B1 following 'dyadic operator': d2 at position 4. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'closing parenthesis': B1 following 'dyadic operator': d2 at position 4. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
b1 p1  B1
Unexpected 'closing parenthesis': B1 following 'prefix operator': p1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'closing parenthesis': B1 following 'prefix operator': p1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
v1 v2
Unexpected 'variable': v2 following term ending at position 2. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
Unexpected 'variable': v2 following 'variable': v1 at position 2. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
END

ok E <<END;
b1 B1 b2
Unexpected 'opening parenthesis': b2 following term ending at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
No closing parenthesis matching b2 at position 3.
END

ok E <<END;
v1 a1 a2
Unexpected 'assignment operator': a2 following 'assignment operator': a1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'assignment operator': a2 following 'assignment operator': a1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
v1 a1 d2
Unexpected 'dyadic operator': d2 following 'assignment operator': a1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'dyadic operator': d2 following 'assignment operator': a1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
v1 a1 q1
Unexpected 'suffix operator': q1 following 'assignment operator': a1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'suffix operator': q1 following 'assignment operator': a1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
v1 a1 s1
Unexpected 'semi-colon': s1 following 'assignment operator': a1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'semi-colon': s1 following 'assignment operator': a1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
b1 a1
Unexpected 'assignment operator': a1 following 'opening parenthesis': b1 at position 2. Expected: 'closing parenthesis', 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable'.
No closing parenthesis matching b1 at position 1.
END

ok E <<END;
b1 d1
Unexpected 'dyadic operator': d1 following 'opening parenthesis': b1 at position 2. Expected: 'closing parenthesis', 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable'.
No closing parenthesis matching b1 at position 1.
END

ok E <<END;
b1 q1
Unexpected 'suffix operator': q1 following 'opening parenthesis': b1 at position 2. Expected: 'closing parenthesis', 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable'.
No closing parenthesis matching b1 at position 1.
END

ok E <<END;
v1 d1 a1
Unexpected 'assignment operator': a1 following 'dyadic operator': d1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'assignment operator': a1 following 'dyadic operator': d1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
v1 d1 q1
Unexpected 'suffix operator': q1 following 'dyadic operator': d1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'suffix operator': q1 following 'dyadic operator': d1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
v1 d1 s1
Unexpected 'semi-colon': s1 following 'dyadic operator': d1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'semi-colon': s1 following 'dyadic operator': d1 at position 3. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
p1 a1
Unexpected 'assignment operator': a1 following 'prefix operator': p1 at position 2. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'assignment operator': a1 following 'prefix operator': p1 at position 2. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
p1 d1
Unexpected 'dyadic operator': d1 following 'prefix operator': p1 at position 2. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'dyadic operator': d1 following 'prefix operator': p1 at position 2. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
p1 q1
Unexpected 'suffix operator': q1 following 'prefix operator': p1 at position 2. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'suffix operator': q1 following 'prefix operator': p1 at position 2. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
p1 s1
Unexpected 'semi-colon': s1 following 'prefix operator': p1 at position 2. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
Unexpected 'semi-colon': s1 following 'prefix operator': p1 at position 2. Expected: 'opening parenthesis', 'prefix operator' or 'variable'.
END

ok E <<END;
v1 q1 b1
Unexpected 'opening parenthesis': b1 following term ending at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
No closing parenthesis matching b1 at position 3.
END

ok E <<END;
v1 q1 p1
Unexpected 'prefix operator': p1 following term ending at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
Unexpected 'prefix operator': p1 following 'suffix operator': q1 at position 3. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
END

ok E <<END;
s1 a1
Unexpected 'assignment operator': a1 following 'semi-colon': s1 at position 2. Expected: 'closing parenthesis', 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable'.
Unexpected 'assignment operator': a1 following 'semi-colon': s1 at position 2. Expected: 'closing parenthesis', 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable'.
END

ok E <<END;
s1 d1
Unexpected 'dyadic operator': d1 following 'semi-colon': s1 at position 2. Expected: 'closing parenthesis', 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable'.
Unexpected 'dyadic operator': d1 following 'semi-colon': s1 at position 2. Expected: 'closing parenthesis', 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable'.
END

ok E <<END;
s1 q1
Unexpected 'suffix operator': q1 following 'semi-colon': s1 at position 2. Expected: 'closing parenthesis', 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable'.
Unexpected 'suffix operator': q1 following 'semi-colon': s1 at position 2. Expected: 'closing parenthesis', 'opening parenthesis', 'prefix operator', 'semi-colon' or 'variable'.
END

ok E <<END;
v1 b1
Unexpected 'opening parenthesis': b1 following term ending at position 2. Expected: 'assignment operator', 'closing parenthesis', 'dyadic operator', 'semi-colon' or 'suffix operator'.
No closing parenthesis matching b1 at position 2.
END

if (1) {                                                                        #Tparse
ok T [qw(v_sub a_is v_array as v1 d_== v2 a_then v3 d_plus v4 a_else v5 d_== v6 a_then v7 d_minus v8 a_else v9 d_times b v10 a_+ v11 B)], <<END;
     is
 sub          as
        array             then
                    ==                    else
                 v1    v2         plus                  then
                               v3      v4         ==                     else
                                               v5    v6         minus            times
                                                             v7       v8      v9             bB
                                                                                           +
                                                                                       v10   v11
END
}

if (1) {                                                                        #TvalidPair
  ok  validPair('B', 'd');
  ok  validPair('b', 'B');
  ok  validPair('v', 'a');
  ok !validPair('v', 'v');
 }

is_deeply LexicalStructure,                                                     #TLexicalStructure
bless({
  codes => bless({
             a => bless({ letter => "a", name => "assignment operator", short=> qq(assign),       next => "bpv" },   "Tree::Term::LexicalCode"),
             b => bless({ letter => "b", name => "opening parenthesis", short=> qq(OpenBracket),  next => "bBpsv" }, "Tree::Term::LexicalCode"),
             B => bless({ letter => "B", name => "closing parenthesis", short=> qq(CloseBracket), next => "aBdqs" }, "Tree::Term::LexicalCode"),
             d => bless({ letter => "d", name => "dyadic operator",     short=> qq(dyad),         next => "bpv" },   "Tree::Term::LexicalCode"),
             p => bless({ letter => "p", name => "prefix operator",     short=> qq(prefix),       next => "bpv" },   "Tree::Term::LexicalCode"),
             q => bless({ letter => "q", name => "suffix operator",     short=> qq(suffix),       next => "aBdqs" }, "Tree::Term::LexicalCode"),
             s => bless({ letter => "s", name => "semi-colon",          short=> qq(semiColon),    next => "bBpsv" }, "Tree::Term::LexicalCode"),
             t => bless({ letter => "t", name => "term",                short=> qq(term),         next => "aBdqs" }, "Tree::Term::LexicalCode"),
             v => bless({ letter => "v", name => "variable",            short=> qq(variable),     next => "aBdqs" }, "Tree::Term::LexicalCode"),
           }, "Tree::Term::Codes"),
  first => "bpsv",
  last  => "Bqsv",
}, "Tree::Term::LexicalStructure");

is_deeply LexicalStructure->first, join '', sort keys %first;                   # Prove first and last
is_deeply LexicalStructure->last,  join '', sort keys %last;

if (1) {                                                                        # Prove $LexicalCodes
  my %C = LexicalStructure->codes->%*;
  my %N = map {$_ => $C{$_}->next} keys %C;
  for my $b(sort keys %N) {
  for my $a(sort keys %N) {
    next if $a eq 't'         or  $b eq 't' ;
    ok !$follows{$b}{$a} || index($N{$a}, $b)  > -1;
    ok  $follows{$b}{$a} || index($N{$a}, $b) == -1;
    next if $a =~ m([adp])    and $b eq 'B' ;                                   # The first cannot be followed by the second
    next if $a =~ m([abdps])  and $b eq 'a' ;
    next if $a =~ m([Bqv])    and $b eq 'b' ;
    next if $a =~ m([abpsd])  and $b eq 'd' ;
    next if $a =~ m([aBqv])   and $b eq 'p' ;
    next if $a =~ m([abdps])  and $b eq 'q' ;
    next if $a =~ m([adp])    and $b eq 's' ;
    next if $a =~ m([aBdpqv]) and $b eq 'v' ;
    next if $follows{$b}{$a};
    confess sprintf("Failed to observe %20s before: %20s\n", $a, $b);           # An unobserved combination
  }}

  if (0) {                                                                      # Print table of allowed and disallowed combinations
    my @l = grep {!m/t/} sort keys %N;
    my @t = [' ', @l];
    for my $b(@l)
     {my @r;
      for my $a(@l)
       {push @r, $follows{$a}{$b} ? 'X' : $tested{$a}{$b} ? '-' : ' ';
       }
      push @t, [$b, @r];
     }
    say STDERR "Column can follow row";
    say STDERR formatTableBasic(\@t);
   }
 }

lll "Finished in", sprintf("%7.4f", time - $startTime), "seconds";
