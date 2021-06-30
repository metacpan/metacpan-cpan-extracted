#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Create a parse tree from an array of terms representing an expression.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
package Tree::Term;
use v5.26;
our $VERSION = 20210631;                                                        # Version
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump ddx pp);
use Data::Table::Text qw(:all);
use feature qw(say state current_sub);

#D1 Parse                                                                       # Create a parse tree from an array of terms representing an expression.

sub new($@)                                                                     #P New term.
 {my ($operator, @operands) = @_;                                               # Operator, operands.
  my $t = genHash(__PACKAGE__,                                                  # Description of a term in the expression.
     operands => @operands ? [@operands] : undef,                               # Operands to which the operator will be applied.
     operator => $operator,                                                     # Operator to be applied to one or more operands.
     up       => undef,                                                         # Parent term if this is a sub term.
   );
  $_->up = $t for grep {ref $_} @operands;                                      # Link to parent if possible

  $t
 }

sub parse(@)                                                                    # Parse an expression.
 {my (@expression) = @_;                                                        # Expression to parse

  my @s;                                                                        # Stack

  my $codes = genHash(q(Tree::Term::Codes),                                     # Lexical item codes.
    a => 'assign',                                                              # Infix operator with priority 2 binding right to left typically used in an assignment.
    b => 'open',                                                                # Open parenthesis.
    B => 'close',                                                               # Close parenthesis.
    d => 'dyad',                                                                # Infix operator with priority 3 binding left to right typically used in arithmetic.
    p => 'prefix',                                                              # Monadic prefix operator.
    q => 'suffix',                                                              # Monadic suffix operator.
    s => 'semi-colon',                                                          # Infix operator with priority 1 binding left to right typically used to separate statements.
    t => 'term',                                                                # A term in the expression.
    v => 'variable',                                                            # A variable in the expression.
   );

  my sub term()                                                                 # Convert the longest possible expression on top of the stack into a term
   {my $n = scalar(@s);
#   lll "TTTT $n \n", dump([@s]);

    my sub test($$)                                                             # Check the type of an item in the stack
     {my ($item, $type) = @_;                                                   # Item to test, expected type of item
      return index($type, 't') > -1 if ref $item;                               # Term
      index($type, substr($item, 0, 1)) > -1                                    # Something other than a term defines its type by its first letter
     };

    if (@s >= 3)                                                                # Go for term infix-operator term
     {my ($r, $d, $l) = reverse @s;
      if (test($l, 't') and test($r, 't') and test($d, 'ads'))                  # Parse out infix operator expression
       {pop  @s for 1..3;
        push @s, new $d, $l, $r;
        return 1;
       }
      if (test($l, 'b') and test($r, 'B') and test($d, 't'))                    # Parse bracketed term
       {pop  @s for 1..3;
        push @s, $d;
        return 1;
       }
     }

    if (@s >= 2)                                                                # Convert ( ) to an empty term
     {my ($r, $l) = reverse @s;
      if (test($l, 'b')  and test($r, 'B'))                                     # Empty pair of brackets
       {pop  @s for 1..2;
        push @s, new 'empty1';
        return 1;
       }
      if (test($l, 'p')   and test($r, 't'))                                    # Prefix operator applied to a term
       {pop  @s for 1..2;
        push @s, new $l, $r;
        return 1;
       }
      if (test($r,'q') and test($l, 't'))                                       # Post fix operator applied to a term
       {pop  @s for 1..2;
        push @s, new $r, $l;
        return 1;
       }
      if (test($l,'s') and test($r, 'B'))                                       # Semi-colon, close implies remove unneeded semi
       {pop  @s for 1..2;
        push @s, $r;
        return 1;
       }
     }

    if (@s >= 1)                                                                # Convert variable to term
     {my ($t) = reverse @s;
      if (test($t, 'v'))                                                        # Single variable
       {pop  @s for 1;
        push @s, new $t;
        return 1;
       }
     }

    if (@s == 1)                                                                # Convert leading semi to empty, semi
     {my ($t) = @s;
      if (test($t,'s'))                                                         # Semi
       {@s = (new('empty4'), $t);
        return 1;
       }
     }

    undef                                                                       # No move made
   };

  for my $i(keys @expression)                                                   # Each input element
   {my $e = $expression[$i];
#   lll "AAAA $i $e\n", dump([@s]);

    if (!@s)                                                                    # Empty stack
     {confess "Expression must start with a variable or open or a prefix operator or a semi"
        if !ref($e) and $e !~ m(\A(b|p|s|v));
      push @s, $e;
      term;
      next;
     }

    my $s = $s[-1];                                                             # Stack has data

    my sub type()                                                               # Type of the current stack top
     {return 't' if ref $s;                                                     # Term on top of stack
      substr($s, 0, 1);                                                         # Something other than a term defines its type by its first letter
     };

    my sub check($)                                                             # Check that the top of the stack has one of the specified elements
     {my ($types) = @_;                                                         # Possible types to match
      return 1 if index($types, type) > -1;                                     # Check type allowed
      my @c;
      for my $c(split //, $types)                                               # Translate lexical codes into types
       {push @c, $$codes{$c};
       }
      my $c = join ', ', sort @c;
      confess qq(Expected $e to follow one of $c at $i but not: $s\n);
     };

    my sub test($)                                                              # Check that the second item on the stack contains one of the expected items
     {my ($types) = @_;                                                         # Possible types to match
      return undef unless @s >= 2;                                              # Stack not deep enough so cannot contain any of the specified types
      return 1 if index($types, ref($s[-2]) ? 't' : substr($s[-2], 0, 1)) > -1;
      undef
     };

    my %action =                                                                # Action on each lexical item
     (a => sub                                                                  # Assign
       {check("Bqtv");
        push @s, $e;
       },

      b => sub                                                                  # Open
       {check("abds");
        push @s, $e;
       },

      B => sub                                                                  # Closing parenthesis
       {check("abqstv");
        1 while term;
        push @s, $e;
        1 while term;
        check("bst");
       },

      d => sub                                                                  # Infix but not assign or semi-colon
       {check("Bqtv");
        push @s, $e;
       },

      p => sub                                                                  # Prefix
       {check("abdps");
        push @s, $e;
       },

      q => sub                                                                  # Suffix
       {check("Bqtv");
        push @s, $e;
        term;
       },

      s => sub                                                                  # Semi colon
       {check("bBqstv");
        push @s, new 'empty5' if $s =~ m(\A(s|b));                              # Insert an empty element between two consecutive semicolons
        1 while term;
        push @s, $e;
       },

      v => sub                                                                  # Variable
       {check("abdps");
        push @s, $e;
        term;
        1 while test("p") and term;
       },
     );

    $action{substr($e, 0, 1)}->();                                              # Dispatch the action associated with the lexical item
   }

  pop @s while @s > 1 and $s[-1] =~ m(s);                                       # Remove any trailing semi colons
  1 while term;                                                                 # Final reductions

# lll "EEEE\n", dump([@s]);
  @s == 1 or confess "Incomplete expression";

  $s[0]                                                                         # The resulting parse tree
 } # parse

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

    align if $p =~ m(\A(a|d|s));                                                # Shift over for some components

    $s[$d] .= " $p";                                                            # Describe operator or operand
    align unless $p =~ m(\A(p|q|v));                                            # Vertical for some components
   }

  shift @s while @s and $s[ 0] =~ m(\A\s*\Z)s;                                  # Remove leading blank lines

  for my $i(keys @s)                                                            # Clean up trailing blanks so that tests are not affected by spurious white space mismatches
   {$s[$i] =~ s/\s+\n/\n/gs;
    $s[$i] =~ s/\s+\Z//gs;
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

  my @e = qw(b b p2 p1 v1 q1 q2 B  d3 b p4 p3 v2 q3 q4  d4 p6 p5 v3 q5 q6 B s B s);

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

      d3
   q2       d4
   q1    q4    q6
   p2    q3    q5
   p1    p4    p6
   v1    p3    p5
         v2    v3
END

=head1 Description

Create a parse tree from an array of terms representing an expression.


Version 20210631.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Parse

Create a parse tree from an array of terms representing an expression.

=head2 parse(@expression)

Parse an expression.

     Parameter    Description
  1  @expression  Expression to parse

B<Example:>


  ok T [qw(b b p2 p1 v1 q1 q2 B  d3 b p4 p3 v2 q3 q4  d4 p6 p5 v3 q5 q6 B s B s)], <<END; 
      d3
   q2       d4
   q1    q4    q6
   p2    q3    q5
   p1    p4    p6
   v1    p3    p5
         v2    v3
  END
  

=head1 Print

Print a parse tree to make it easy to visualize its structure.

=head2 flat($expression, @title)

Print the terms in the expression as a tree from left right to make it easier to visualize the structure of the tree.

     Parameter    Description
  1  $expression  Root term
  2  @title       Optional title

B<Example:>


  ok T [qw(p2 p1 v1 q1 q2 d3 p4 p3 v2 q3 q4  d4 p6 p5 v3 q5 q6 s)], <<END;        
      d3
   q2       d4
   q1    q4    q6
   p2    q3    q5
   p1    p4    p6
   v1    p3    p5
         v2    v3
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

Close parenthesis.

=head4 a

Infix operator with priority 2 binding right to left typically used in an assignment.

=head4 b

Open parenthesis.

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



=head1 Private Methods

=head2 new($operator, @operands)

New term.

     Parameter  Description
  1  $operator  Operator
  2  @operands  Operands.

=head2 depth($term)

Depth of a term in an expression.

     Parameter  Description
  1  $term      Term

=head2 listTerms($expression)

List the terms in an expression in post order

     Parameter    Description
  1  $expression  Root term


=head1 Index


1 L<depth|/depth> - Depth of a term in an expression.

2 L<flat|/flat> - Print the terms in the expression as a tree from left right to make it easier to visualize the structure of the tree.

3 L<listTerms|/listTerms> - List the terms in an expression in post order

4 L<new|/new> - New term.

5 L<parse|/parse> - Parse an expression.

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
__DATA__
use Time::HiRes qw(time);
use Test::More;

my $develop   = -e q(/home/phil/);                                              # Developing
my $log       = q(/home/phil/perl/cpan/TreeTerm/lib/Tree/zzz.txt);              # Log file
my $localTest = ((caller(1))[0]//'Tree::Term') eq "Tree::Term";                 # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i)                                                       # Supported systems
 {plan tests => 23;
 }
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

sub T                                                                           #P Test a parse
 {my ($expression, $expected) = @_;                                             # Expression, expected result

  my $g = parse(@$expression)->flat;
  my $r = $g eq $expected;
  owf($log, $g) if -e $log;                                                     # Save result if testing
  confess "Failed test" unless $r;
  $r
 }

eval {goto latest};

ok T [qw(v1)], <<END;
 v1
END

ok T [qw(s)], <<END;
 empty4
END

ok T [qw(s s)], <<END;
        s
 empty4   empty5
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

ok T [qw(v1 a2 v3 d4 v5 s6 v8 a9 v10)], <<END;
                s6
    a2                a9
 v1       d4       v8    v10
       v3    v5
END

ok T [qw(v1 a2 v3 s s s  v4 a5 v6 s s)], <<END;
                                       s
                            s            empty5
                   s             a5
          s          empty5   v4    v6
    a2      empty5
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

ok T [qw(p2 p1 v1 q1 q2 d3 p4 p3 v2 q3 q4  d4 p6 p5 v3 q5 q6 s)], <<END;        #Tflat
    d3
 q2       d4
 q1    q4    q6
 p2    q3    q5
 p1    p4    p6
 v1    p3    p5
       v2    v3
END

ok T [qw(b s B)], <<END;
 empty5
END

ok T [qw(b s s B)], <<END;
        s
 empty5   empty5
END


ok T [qw(b b p2 p1 v1 q1 q2 B  d3 b p4 p3 v2 q3 q4  d4 p6 p5 v3 q5 q6 B s B s)], <<END; #Tparse
    d3
 q2       d4
 q1    q4    q6
 p2    q3    q5
 p1    p4    p6
 v1    p3    p5
       v2    v3
END
