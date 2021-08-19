#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/NasmX86/lib/ -I/home/phil/perl/cpan/AsmC/lib/
#-------------------------------------------------------------------------------
# Parse a Unisyn expression.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
# Finished in 13.14s, bytes: 2,655,008, execs: 465,858
package Unisyn::Parse;
our $VERSION = "20210818";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all !parse);
use Nasm::X86 qw(:all);
use feature qw(say current_sub);

makeDieConfess;

my $develop = -e q(/home/phil/);                                                # Developing

#D1 Parse                                                                       # Parse Unisyn expressions

our $Lex = &lexicalData;                                                        # Lexical table definitions
our $tree;                                                                      # Parse tree

our $debug            = 0;                                                      # Include debug code if true

our $ses              = RegisterSize rax;                                       # Size of an element on the stack
our ($w1, $w2, $w3)   = (r8, r9, r10);                                          # Work registers
our $prevChar         = r11;                                                    # The previous character parsed
our $index            = r12;                                                    # Index of current element
our $element          = r13;                                                    # Contains the item being parsed
our $start            = r14;                                                    # Start of the parse string
our $size             = r15;                                                    # Length of the input string
our $parseStackBase   = rsi;                                                    # The base of the parsing stack in the stack
our $indexScale       = 4;                                                      # The size of a utf32 character
our $lexCodeOffset    = 3;                                                      # The offset in a classified character to the lexical code.
our $bitsPerByte      = 8;                                                      # The number of bits in a byte

our $Ascii            = $$Lex{lexicals}{Ascii}           {number};              # Ascii
our $assign           = $$Lex{lexicals}{assign}          {number};              # Assign
our $CloseBracket     = $$Lex{lexicals}{CloseBracket}    {number};              # Close bracket
our $empty            = $$Lex{lexicals}{empty}           {number};              # Empty element
our $NewLineSemiColon = $$Lex{lexicals}{NewLineSemiColon}{number};              # New line semicolon
our $OpenBracket      = $$Lex{lexicals}{OpenBracket}     {number};              # Open  bracket
our $prefix           = $$Lex{lexicals}{prefix}          {number};              # Prefix operator
our $semiColon        = $$Lex{lexicals}{semiColon}       {number};              # Semicolon
our $suffix           = $$Lex{lexicals}{suffix}          {number};              # Suffix
our $term             = $$Lex{lexicals}{term}            {number};              # Term
our $variable         = $$Lex{lexicals}{variable}        {number};              # Variable
our $WhiteSpace       = $$Lex{lexicals}{WhiteSpace}      {number};              # Variable
our $firstSet         = $$Lex{structure}{first};                                # First symbols allowed
our $lastSet          = $$Lex{structure}{last};                                 # Last symbols allowed
our $asciiNewLine     = ord("\n");                                              # New line in ascii
our $asciiSpace       = ord(' ');                                               # Space in ascii

sub getAlpha($$$)                                                               #P Load the position of a lexical item in its alphabet from the current character.
 {my ($register, $address, $index) = @_;                                        # Register to load, address of start of string, index into string
  Mov $register, "[$address+$indexScale*$index]";                               # Load lexical code
 }

sub getLexicalCode($$$)                                                         #P Load the lexical code of the current character in memory into the specified register.
 {my ($register, $address, $index) = @_;                                        # Register to load, address of start of string, index into string
  Mov $register, "[$address+$indexScale*$index+$lexCodeOffset]";                # Load lexical code
 }

sub putLexicalCode($$$$)                                                        #P Put the specified lexical code into the current character in memory.
 {my ($register, $address, $index, $code) = @_;                                 # Register used to load code, address of string, index into string, code to put
  defined($code) or confess;
  Mov $register, $code;
  Mov "[$address+$indexScale*$index+$lexCodeOffset]", $register;                # Save lexical code
 }

sub loadCurrentChar()                                                           #P Load the details of the character currently being processed so that we have the index of the character in the upper half of the current character and the lexical type of the character in the lowest byte.
 {my $r = $element."b";                                                         # Classification byte

  Mov $element, $index;                                                         # Load index of character as upper dword
  Shl $element, $indexScale * $bitsPerByte;                                     # Save the index of the character in the upper half of the register so that we know where the character came from.
  getLexicalCode $r, $start, $index;                                            # Load lexical classification as lowest byte

  Cmp $r, $$Lex{bracketsBase};                                                  # Brackets , due to their frequency, start after 0x10 with open even and close odd
  IfGe                                                                          # Brackets
  Then
   {And $r, 1                                                                   # Bracket: 0 - open, 1 - close
   },
  Else
   {Cmp     $r, $Ascii;                                                         # Ascii is a type of variable
    IfEq
    Then
     {Mov   $r, $variable;
     },
    Else
     {Cmp   $r, $NewLineSemiColon;                                              # New line semicolon is a type of semi colon
      IfEq
      Then
       {Mov $r, $semiColon;
       };
     };
   };
 }

sub checkStackHas($)                                                            #P Check that we have at least the specified number of elements on the stack.
 {my ($depth) = @_;                                                             # Number of elements required on the stack
  Mov $w1, $parseStackBase;
  Sub $w1, rsp;
  Cmp $w1, $ses * $depth;
 }

sub pushElement()                                                               #P Push the current element on to the stack.
 {Push $element;
  if ($debug)
   {PrintOutStringNL "Push Element:";
    PrintOutRegisterInHex $element;
   }
 }

sub pushEmpty()                                                                 #P Push the empty element on to the stack.
 {Mov  $w1, $index;
  Shl  $w1, $indexScale * $bitsPerByte;
  Or   $w1, $empty;
  Push $w1;
  if ($debug)
   {PrintOutStringNL "Push Empty";
   }
 }

sub lexicalNameFromLetter($)                                                    #P Lexical name for a lexical item described by its letter.
 {my ($l) = @_;                                                                 # Letter of the lexical item
  my %l = $Lex->{treeTermLexicals}->%*;
  my $n = $l{$l};
  confess "No such lexical: $l" unless $n;
  $n->{short}
 }

sub lexicalNumberFromLetter($)                                                  #P Lexical number for a lexical item described by its letter.
 {my ($l) = @_;                                                                 # Letter of the lexical item
  my $n = lexicalNameFromLetter $l;
  my $N = $Lex->{lexicals}{$n}{number};
  confess "No such lexical named: $n" unless defined $N;
  $N
 }

sub new2($$)                                                                    #P Create a new term in the parse tree rooted on the stack.
 {my ($depth, $description) = @_;                                               # Stack depth to be converted, text reason why we are creating a new term
  PrintOutStringNL "New: $description" if $debug;

  my $t = $tree->bs->CreateTree;
  my $d = V(data);
  $t->insert(V(key, 0), V(data, $term));                                        # Create a term
  $t->insert(V(key, 1), V(data, $depth));                                       # The number of elements in the term

  for my $i(1..$depth)
   {my $j = $depth + 1 - $i;
    Pop $w1;
    PrintOutRegisterInHex $w1 if $debug;
    $d->getReg($w1);
    $t->insert(      V(key, 2 * $j    ), $d);                                   # The lexical type - which actually only takes 4 bits so this could be improved on.

    Mov $w2, $w1;
    Shr $w2, 32;                                                                # Offset in source
    $d->getReg($w2);                                                            # Offset in source in lower dword
    Cmp $w1."b", $term;                                                         # Check whether the lexical item on the stack is a term


    IfEq
    Then
     {$t->insertTree(V(key, 2 * $j + 1), $d);                                   # A reference to another term
     },
    Else
     {$t->insert    (V(key, 2 * $j + 1), $d);                                   # Offset in source
     }
   }
  $t->first->setReg($w1);                                                       # Term
  Shl $w1, 32;                                                                  # Push offset to tree into the upper dword
  Or  $w1."b", $term;                                                           # Mark as a term tree
  Push $w1;                                                                     # Place simulated term on stack
 }

sub new($$)                                                                     #P Create a new term.
 {my ($depth, $description) = @_;                                               # Stack depth to be converted, text reason why we are creating a new term.
  PrintOutStringNL "New: $description" if $debug;

  if ($tree and $tree->bs)                                                      # Parse tree available
   {new2($depth, $description);
   }
  else                                                                          # Testing without building full parse tree
   {for my $i(1..$depth)
     {Pop $w1;
      PrintOutRegisterInHex $w1 if $debug;
     }
    Mov $w1, $term;                                                             # Term
    Push $w1;                                                                   # Place simulated term on stack
   }
 }

sub error($)                                                                    #P Die.
 {my ($message) = @_;                                                           # Error message
  PrintOutStringNL "Error: $message";
  PrintOutString "Element: ";
  PrintOutRegisterInHex $element;
  PrintOutString "Index  : ";
  PrintOutRegisterInHex $index;
  Exit(0);
 }

sub testSet($$)                                                                 #P Test a set of items, setting the Zero Flag is one matches else clear the Zero flag.
 {my ($set, $register) = @_;                                                    # Set of lexical letters, Register to test
  my @n = map {sprintf("0x%x", lexicalNumberFromLetter $_)} split //, $set;     # Each lexical item by number from letter
  my $end = Label;
  for my $n(@n)
   {Cmp $register."b", $n;
    Je $end
   }
  ClearZF;
  SetLabel $end;
 }

sub checkSet($)                                                                 #P Check that one of a set of items is on the top of the stack or complain if it is not.
 {my ($set) = @_;                                                               # Set of lexical letters
  my @n =  map {lexicalNumberFromLetter $_} split //, $set;
  my $end = Label;

  for my $n(@n)
   {Cmp "byte[rsp]", $n;
    Je $end
   }
  error("Expected one of: '$set' on the stack");
  ClearZF;
  SetLabel $end;
 }

sub reduce($)                                                                   #P Convert the longest possible expression on top of the stack into a term  at the specified priority.
 {my ($priority) = @_;                                                          # Priority of the operators to reduce
  $priority =~ m(\A(1|3)\Z);                                                    # Level: 1 - all operators, 2 - priority 2 operators
  my ($success, $end) = map {Label} 1..2;                                       # Exit points

  checkStackHas 3;                                                              # At least three elements on the stack
  IfGe
  Then
   {my ($l, $d, $r) = ($w1, $w2, $w3);
    Mov $l, "[rsp+".(2*$ses)."]";                                               # Top 3 elements on the stack
    Mov $d, "[rsp+".(1*$ses)."]";
    Mov $r, "[rsp+".(0*$ses)."]";

    if ($debug)
     {PrintOutStringNL "Reduce 3:";
      PrintOutRegisterInHex $l, $d, $r;
     }

    testSet("t",  $l);                                                          # Parse out infix operator expression
    IfEq
    Then
     {testSet("t",  $r);
      IfEq
      Then
       {testSet($priority == 1 ? "ads" : 'd', $d);                              # Reduce all operators or just reduce infix priority 3 operators
        IfEq
        Then
         {Add rsp, 3 * $ses;                                                    # Reorder into polish notation
          Push $_ for $d, $l, $r;
          new(3, "Term infix term");
          Jmp $success;
         };
       };
     };

    testSet("b",  $l);                                                          # Parse parenthesized term
    IfEq
    Then
     {testSet("B",  $r);
      IfEq
      Then
       {testSet("t",  $d);
        IfEq
        Then
         {Add rsp, $ses;
          new(1, "Bracketed term");
          new(2, "Brackets for term");
          PrintOutStringNL "Reduce by ( term )" if $debug;
          Jmp $success;
         };
       };
     };
#   KeepFree $l, $d, $r;
   };

  checkStackHas 2;                                                              # At least two elements on the stack
  IfGe                                                                          # Convert an empty pair of parentheses to an empty term
  Then
   {my ($l, $r) = ($w1, $w2);

    if ($debug)
     {PrintOutStringNL "Reduce 2:";
      PrintOutRegisterInHex $l, $r;
     }

#   KeepFree $l, $r;                                                            # Why ?
    Mov $l, "[rsp+".(1*$ses)."]";                                               # Top 3 elements on the stack
    Mov $r, "[rsp+".(0*$ses)."]";
    testSet("b",  $l);                                                          # Empty pair of parentheses
    IfEq
    Then
     {testSet("B",  $r);
      IfEq
      Then
       {Add rsp, 2 * $ses;                                                      # Pop expression
        Push $l;                                                                # Bracket as operator
        new(1, "Empty brackets");
        Jmp $success;
       };
     };
    testSet("s",  $l);                                                          # Semi-colon, close implies remove unneeded semi
    IfEq
    Then
     {testSet("B",  $r);
      IfEq
      Then
       {Add rsp, 2 * $ses;                                                      # Pop expression
        Push $r;
        PrintOutStringNL "Reduce by ;)" if $debug;
        Jmp $success;
       };
     };
    testSet("p", $l);                                                           # Prefix, term
    IfEq
    Then
     {testSet("t",  $r);
      IfEq
      Then
       {new(2, "Prefix term");
        Jmp $success;
       };
     };
#   KeepFree $l, $r;
   };

  ClearZF;                                                                      # Failed to match anything
  Jmp $end;

  SetLabel $success;                                                            # Successfully matched
  SetZF;

  SetLabel $end;                                                                # End
 } # reduce

sub reduceMultiple($)                                                           #P Reduce existing operators on the stack.
 {my ($priority) = @_;                                                          # Priority of the operators to reduce
  K('count',99)->for(sub                                                        # An improbably high but finite number of reductions
   {my ($index, $start, $next, $end) = @_;                                      # Execute body
    reduce($priority);
    Jne $end;                                                                   # Keep going as long as reductions are possible
   });
 }

sub accept_a()                                                                  #P Assign.
 {checkSet("t");
  reduceMultiple 2;
  PrintOutStringNL "accept a" if $debug;
  pushElement;
 }

sub accept_b                                                                    #P Open.
 {checkSet("abdps");
  PrintOutStringNL "accept b" if $debug;
  pushElement;
 }

sub accept_B                                                                    #P Closing parenthesis.
 {checkSet("bst");
  PrintOutStringNL "accept B" if $debug;
  reduceMultiple 1;
  pushElement;
  reduceMultiple 1;
  checkSet("bst");
 }

sub accept_d                                                                    #P Infix but not assign or semi-colon.
 {checkSet("t");
  PrintOutStringNL "accept d" if $debug;
  pushElement;
 }

sub accept_p                                                                    #P Prefix.
 {checkSet("abdps");
  PrintOutStringNL "accept p" if $debug;
  pushElement;
 }

sub accept_q                                                                    #P Post fix.
 {checkSet("t");
  PrintOutStringNL "accept q" if $debug;
  IfEq                                                                          # Post fix operator applied to a term
  Then
   {Pop $w1;
    pushElement;
    Push $w1;
    new(2, "Postfix");
   }
 }

sub accept_s                                                                    #P Semi colon.
 {checkSet("bst");
  PrintOutStringNL "accept s" if $debug;
  Mov $w1, "[rsp]";
  testSet("s",  $w1);
  IfEq                                                                          # Insert an empty element between two consecutive semicolons
  Then
   {pushEmpty;
   };
  reduceMultiple 1;
  pushElement;
 }

sub accept_v                                                                    #P Variable.
  {checkSet("abdps");
   PrintOutStringNL "accept v" if $debug;
   pushElement;
   new(1, "Variable");
   V(count,99)->for(sub                                                         # Reduce prefix operators
    {my ($index, $start, $next, $end) = @_;
     checkStackHas 2;
     Jl $end;
     my ($l, $r) = ($w1, $w2);
     Mov $l, "[rsp+".(1*$ses)."]";
     Mov $r, "[rsp+".(0*$ses)."]";
     testSet("p", $l);
     Jne $end;
     new(2, "Prefixed variable");
    });
  }

sub parseExpressionCode()                                                       #P Parse the string of classified lexical items addressed by register $start of length $length.  The resulting parse tree (if any) is returned in r15.
 {my $end = Label;
  my $eb  = $element."b";                                                       # Contains a byte from the item being parsed

  my $b = CreateArena;                                                          # Arena to hold parse tree
  $tree = $b->CreateTree;                                                       # Root of parse tree

  Cmp $size, 0;                                                                 # Check for empty expression
  Je $end;

  loadCurrentChar;                                                              # Load current character
### Need test for ignorable white space as first character
  testSet($firstSet, $element);
  IfNe
  Then
   {error(<<END =~ s(\n) ( )gsr);
Expression must start with 'opening parenthesis', 'prefix
operator', 'semi-colon' or 'variable'.
END
   };

  testSet("v", $element);                                                       # Single variable
  IfEq
  Then
   {pushElement;
    new(1, "accept initial variable");
   },
  Else
   {testSet("s", $element);                                                     # Semi
    IfEq
    Then
     {pushEmpty;
      new(1, "accept initial semicolon");
     };
    pushElement;
   };

  Inc $index;                                                                   # We have processed the first character above
  Mov $prevChar, $element;                                                      # Initialize the previous lexical item

  For                                                                           # Parse each utf32 character after it has been classified
   {my ($start, $end, $next) = @_;                                              # Start and end of the classification loop
    loadCurrentChar;                                                            # Load current character

    PrintOutRegisterInHex $element if $debug;

    Cmp $eb, $WhiteSpace;
    Je $next;                                                                   # Ignore white space

    Cmp $eb, 1;                                                                 # Brackets are singular but everything else can potential be a plurality
    IfGt
    Then
     {Cmp $prevChar."b", $eb;                                                   # Compare with previous element known not to be white space or a bracket
      Je $next
     };
    Mov $prevChar, $element;                                                    # Save element to previous element now we know we are on a different element

    for my $l(sort keys $Lex->{lexicals}->%*)                                   # Each possible lexical item after classification
     {my $x = $Lex->{lexicals}{$l}{letter};
      next unless $x;                                                           # Skip characters that do not have a letter defined for Tree::Term because the lexical items needed to layout a file of lexical items are folded down to the actual lexical items required to represent the language independent of the textual layout with white space.

      my $n = $Lex->{lexicals}{$l}{number};
      Comment "Compare to $n for $l";
      Cmp $eb, $n;

      IfEq
      Then
       {eval "accept_$x";
        Jmp $next
       };
     }
    error("Unexpected lexical item");                                           # Not selected
   } $index, $size;

  testSet($lastSet, $prevChar);                                                 # Last lexical  element
  IfNe                                                                          # Incomplete expression
  Then
   {error("Incomplete expression");
   };

  K('count', 99)->for(sub                                                       # Remove trailing semicolons if present
   {my ($index, $start, $next, $end) = @_;                                      # Execute body
    checkStackHas 2;
    Jl $end;                                                                    # Does not have two or more elements
    Pop $w1;
    testSet("s", $w1);                                                          # Check that the top most element is a semi colon
    IfNe                                                                        # Not a semi colon so put it back and finish the loop
    Then
     {Push $w1;
      Jmp $end;
     };
   });

  reduceMultiple 1;                                                             # Final reductions

  checkStackHas 1;
  IfNe                                                                          # Incomplete expression
  Then
   {error("Multiple expressions on stack");
   };

  Pop r15;                                                                      # The resulting parse tree
  SetLabel $end;
 } # parseExpressionCode

sub parseExpression(@)                                                          #P Create a parser for an expression described by variables.
 {my (@parameters) = @_;                                                        # Parameters describing expression

  my $s = Subroutine
   {my ($p) = @_;                                                               # Parameters
    PushR $parseStackBase, map {"r$_"} 8..15;
    $$p{source}->setReg($start);                                                # Start of expression string after it has been classified
    $$p{size}  ->setReg($size);                                                 # Number of characters in the expression

    Mov $parseStackBase, rsp;                                                   # Set base of parse stack

    parseExpressionCode;
    $$p{parse}->getReg(r15);                                                    # Number of characters in the expression

    Mov rsp, $parseStackBase;                                                   # Remove parse stack
                                                                                # Remove new frame
    PopR;
   } [qw(source size parse)], name => q(Unisyn::Parse::parse);


  $s->call(@parameters);
 } # parse

sub MatchBrackets(@)                                                            #P Replace the low three bytes of a utf32 bracket character with 24 bits of offset to the matching opening or closing bracket. Opening brackets have even codes from 0x10 to 0x4e while the corresponding closing bracket has a code one higher.
 {my (@parameters) = @_;                                                        # Parameters
  @_ >= 1 or confess;

  my $s = Subroutine
   {my ($p) = @_;                                                               # Parameters
    Comment "Match brackets in utf32 text";

    my $finish = Label;
    PushR xmm0, k7, r10, r11, r12, r13, r14, r15, rsi;                          # R15 current character address. r14 is the current classification. r13 the last classification code. r12 the stack depth. r11 the number of opening brackets found. r10  address of first utf32 character.

    Mov rsi, rsp;                                                               # Save stack location so we can use the stack to record the brackets we have found
    ClearRegisters r11, r12, r15;                                               # Count the number of brackets and track the stack depth, index of each character
    K(three, 3)->setMaskFirst(k7);                                              # These are the number of bytes that we are going to use for the offsets of brackets which limits the size of a program to 24 million utf32 characters
    $$p{fail}   ->getReg(r11);                                                  # Clear failure indicator
    $$p{opens}  ->getReg(r11);                                                  # Clear count of opens
    $$p{address}->setReg(r10);                                                  # Address of first utf32 character
    my $w = RegisterSize eax;                                                   # Size of a utf32 character

    $$p{size}->for(sub                                                          # Process each utf32 character in the block of memory
     {my ($index, $start, $next, $end) = @_;
      my $continue = Label;

      Mov r14b, "[r10+$w*r15+3]";                                               # Classification character

      Cmp r14, 0x10;                                                            # First bracket
      Jl $continue;                                                             # Less than first bracket
      Cmp r14, 0x4f;                                                            # Last bracket
      Jg $continue;                                                             # Greater than last bracket

      Test r14, 1;                                                              # Zero means that the bracket is an opener
      IfZ sub                                                                   # Save an opener then continue
       {Push r15;                                                               # Save position in input
        Push r14;                                                               # Save opening code
        Inc r11;                                                                # Count number of opening brackets
        Inc r12;                                                                # Number of brackets currently open
        Jmp $continue;
       };
      Cmp r12, 1;                                                               # Check that there is a bracket to match on the stack
      IfLt sub                                                                  # Nothing on stack
       {Not r15;                                                                # Minus the offset at which the error occurred so that we can fail at zero
        $$p{fail}->getReg(r15);                                                 # Position in input that caused the failure
        Jmp $finish;                                                            # Return
       };
      Mov r13, "[rsp]";                                                         # Peek at the opening bracket code which is on top of the stack
      Inc r13;                                                                  # Expected closing bracket
      Cmp r13, r14;                                                             # Check for match
      IfNe sub                                                                  # Mismatch
       {Not r15;                                                                # Minus the offset at which the error occurred so that we can fail at zero
        $$p{fail}->getReg(r15);                                                 # Position in input that caused the failure
        Jmp $finish;                                                            # Return
       };
      Pop r13;                                                                  # The closing bracket matches the opening bracket
      Pop r13;                                                                  # Offset of opener
      Dec r12;                                                                  # Close off bracket sequence
      Vpbroadcastq xmm0, r15;                                                   # Load offset of opener
      Vmovdqu8 "[r10+$w*r13]\{k7}", xmm0;                                       # Save offset of opener in the code for the closer - the classification is left intact so we still know what kind of bracket we have
      Vpbroadcastq xmm0, r13;                                                   # Load offset of opener
      Vmovdqu8 "[r10+$w*r15]\{k7}", xmm0;                                       # Save offset of closer in the code for the openercloser - the classification is left intact so we still know what kind of bracket we have
      SetLabel $continue;                                                       # Continue with next character
      Inc r15;                                                                  # Next character
     });

    SetLabel $finish;
    Mov rsp, rsi;                                                               # Restore stack
    $$p{opens}->getReg(r11);                                                    # Number of brackets opened
    PopR;
   } [qw(address size fail opens)],  name => q(Unisyn::Parse::MatchBrackets);

  $s->call(@parameters);
 } # MatchBrackets

sub ClassifyNewLines(@)                                                         #P Scan input string looking for opportunities to convert new lines into semi colons.
 {my (@parameters) = @_;                                                        # Parameters
  @_ >= 1 or confess;

  my $s = Subroutine
   {my ($p) = @_;                                                               # Parameters
    my $current       = r15;                                                    # Index of the current character
    my $middle        = r14;                                                    # Index of the middle character
    my $first         = r13;                                                    # Index of the first character
    my $address       = r12;                                                    # Address of input string
    my $size          = r11;                                                    # Length of input utf32 string
    my($c1, $c2)      = (r8."b", r9."b");                                       # Lexical codes being tested

    PushR r8, r9, r10, r11, r12, r13, r14, r15;

    $$p{address}->setReg($address);                                             # Address of string
    $$p{size}   ->setReg($size);                                                # Size of string
    Mov $current, 2; Mov $middle, 1; Mov $first, 0;

    For                                                                         # Each character in input string
     {my ($start, $end, $next) = @_;                                            # Start, end and next labels


      getLexicalCode $c1, $address, $middle;                                    # Lexical code of the middle character
      Cmp $c1, $WhiteSpace;
      IfEq
      Then
       {getAlpha $c1, $address, $middle;

        Cmp $c1, $asciiNewLine;
        IfEq                                                                    # Middle character is a insignificant new line and thus could be a semicolon
        Then
         {getLexicalCode $c1, $address, $first;

          my sub makeSemiColon                                                  # Make a new line into a new line semicolon
           {putLexicalCode $c2, $address, $middle, $NewLineSemiColon;
           }

          my sub check_bpv                                                      # Make new line if followed by 'b', 'p' or 'v'
           {getLexicalCode $c1, $address, $current;
            Cmp $c1, $OpenBracket;

            IfEq
            Then
             {makeSemiColon;
             },
            Else
             {Cmp $c1, $prefix;
              IfEq
              Then
               {makeSemiColon;
               },
              Else
               {Cmp $c1, $variable;
                IfEq
                Then
                 {makeSemiColon;
                 };
               };
             };
           }

          Cmp $c1, $CloseBracket;                                               # Check first character of sequence
          IfEq
          Then
           {check_bpv;
           },
          Else
           {Cmp $c1, $suffix;
            IfEq
            Then
             {check_bpv;
             },
            Else
             {Cmp $c1, $variable;
              IfEq
              Then
               {check_bpv;
               };
             };
           };
         };
       };

      Mov $first, $middle; Mov $middle, $current;                               # Find next lexical item
      getLexicalCode $c1, $address, $current;                                   # Current lexical code
      Mov $middle, $current;
      Inc $current;                                                             # Next possible character
      For
       {my ($start, $end, $next) = @_;
        getLexicalCode $c2, $address, $current;                                 # Lexical code of  next character
        Cmp $c1, $c2;
        Jne $end;                                                               # Terminate when we are in a different lexical item
       } $current, $size;
     } $current, $size;

    PopR;
   } [qw(address size)], name => q(Unisyn::Parse::ClassifyNewLines);

  $s->call(@parameters);
 } # ClassifyNewLines

sub ClassifyWhiteSpace(@)                                                       #P Classify white space per: "lib/Unisyn/whiteSpace/whiteSpaceClassification.pl".
 {my (@parameters) = @_;                                                        # Parameters
  @_ >= 1 or confess;

  my $s = Subroutine
   {my ($p) = @_;                                                               # Parameters
    my $eb            = r15."b";                                                # Lexical type of current char
    my $s             = r14;                                                    # State of white space between 'a'
    my $S             = r13;                                                    # State of white space before  'a'
    my $cb            = r12."b";                                                # Actual character within alphabet
    my $address       = r11;                                                    # Address of input string
    my $index         = r10;                                                    # Index of current char
    my ($w1, $w2)     = (r8."b", r9."b");                                       # Temporary work registers

    my sub getAlpha($;$)                                                        # Load the position of a lexical item in its alphabet from the current character
     {my ($register, $indexReg) = @_;                                           # Register to load, optional index register
      getAlpha $register, $address,  $index // $indexReg                        # Supplied index or default
     };

    my sub getLexicalCode()                                                     # Load the lexical code of the current character in memory into the current character
     {getLexicalCode $eb, $address,  $index;                                    # Supplied index or default
     };

    my sub putLexicalCode($;$)                                                  # Put the specified lexical code into the current character in memory.
     {my ($code, $indexReg) = @_;                                               # Code, optional index register
      putLexicalCode $w1, $address, ($indexReg//$index), $code;
     };

    PushR r8, r9, r10, r11, r12, r13, r14, r15;

    $$p{address}->setReg($address);                                             # Address of string
    Mov $s, -1; Mov $S, -1; Mov $index, 0;                                      # Initial states, position

    $$p{size}->for(sub                                                          # Each character in expression
     {my ($indexVariable, $start, $next, $end) = @_;

      $indexVariable->setReg($index);
      getLexicalCode;                                                           # Current lexical code

      Block                                                                     # Trap space before new line and detect new line after ascii
       {my ($start, $end) = @_;
        Cmp $index, 0;    Je  $end;                                             # Start beyond the first character so we can look back one character.
        Cmp $eb, $Ascii;  Jne $end;                                             # Current is ascii

        Mov $w1, "[$address+$indexScale*$index-$indexScale+$lexCodeOffset]";    # Previous lexical code
        Cmp $w1, $Ascii;  Jne $end;                                             # Previous is ascii

        if (1)                                                                  # Check for 's' followed by 'n' and 'a' followed by 'n'
         {Mov $w1, "[$address+$indexScale*$index-$indexScale]";                 # Previous character
          getAlpha $w2;                                                         # Current character

          Cmp $w1, $asciiSpace;                                                 # Check for space followed by new line
          IfEq
          Then
           {Cmp $w2, $asciiNewLine;
            IfEq                                                                # Disallow 's' followed by 'n'
            Then
             {PrintErrStringNL "Space detected before new line at index:";
              PrintErrRegisterInHex $index;
              PrintErrTraceBack;
              Exit(1);
             };
           };

          Cmp $w1, $asciiSpace;    Je  $end;                                    # Check for  'a' followed by 'n'
          Cmp $w1, $asciiNewLine;  Je  $end;                                    # Current is 'a' but not 'n' or 's'
          Cmp $w2, $asciiNewLine;  Jne $end;                                    # Current is 'n'

          putLexicalCode $WhiteSpace;                                           # Mark new line as significant
         }
       };

      Block                                                                     # Spaces and new lines between other ascii
       {my ($start, $end) = @_;
        Cmp $s, -1;
        IfEq                                                                    # Looking for opening ascii
        Then
         {Cmp $eb, $Ascii;         Jne $end;                                    # Not ascii
          getAlpha $cb;                                                         # Current character
          Cmp $cb, $asciiNewLine;  Je $end;                                     # Skip over new lines
          Cmp $cb, $asciiSpace;    Je $end;                                     # Skip over spaces
          IfEq
          Then
           {Mov $s, $index; Inc $s;                                             # Ascii not space nor new line
           };
          Jmp $end;
         },
        Else                                                                    # Looking for closing ascii
         {Cmp $eb, $Ascii;
          IfNe                                                                  # Not ascii
          Then
           {Mov $s, -1;
            Jmp $end
           };
          getAlpha $cb;                                                         # Current character
          Cmp $cb, $asciiNewLine; Je $end;                                      # Skip over new lines
          Cmp $cb, $asciiSpace;   Je $end;                                      # Skip over spaces

          For                                                                   # Move over spaces and new lines between two ascii characters that are neither of new line or space
           {my ($start, $end, $next) = @_;
            getAlpha $cb, $s;                                                   # Check for 's' or 'n'
            Cmp $cb, $asciiSpace;
            IfEq
            Then
             {putLexicalCode $WhiteSpace, $s;                                   # Mark as significant white space.
             Jmp $next;
             };
            Cmp $cb, $asciiNewLine;
            IfEq
            Then
             {putLexicalCode $WhiteSpace;                                       # Mark as significant new line
              Jmp $next;
             };
           } $s, $index;

          Mov $s, $index; Inc $s;
         };
       };

      Block                                                                     # Note: 's' preceding 'a' are significant
       {my ($start, $end) = @_;
        Cmp $S, -1;
        IfEq                                                                    # Looking for 's'
        Then
         {Cmp $eb, $Ascii;                                                      # Not 'a'
          IfNe
          Then
           {Mov $S, -1;
            Jmp $end
           };
          getAlpha $cb;                                                         # Actual character in alphabet
          Cmp $cb, $asciiSpace;                                                 # Space
          IfEq
          Then
           {Mov $S, $index;
            Jmp $end;
           };
         },
        Else                                                                    # Looking for 'a'
         {Cmp $eb, $Ascii;                                                      # Not 'a'
          IfNe
          Then
           {Mov $S, -1;
            Jmp $end
           };
          getAlpha $cb;                                                         # Actual character in alphabet
          Cmp $cb, $asciiSpace; Je $end;                                        # Skip 's'

          Cmp $cb, $asciiNewLine;
          IfEq                                                                  # New lines prevent 's' from preceding 'a'
          Then
           {Mov $s, -1;
            Jmp $end
           };

          For                                                                   # Move over spaces to non space ascii
           {my ($start, $end, $next) = @_;
            putLexicalCode $WhiteSpace, $S;                                     # Mark new line as significant
           } $S, $index;
          Mov $S, -1;                                                           # Look for next possible space
         }
       };
     });

    $$p{size}->for(sub                                                          # Invert white space so that significant white space becomes ascii and the remainder is ignored
     {my ($indexVariable, $start, $next, $end) = @_;

      $indexVariable->setReg($index);
      getLexicalCode;                                                           # Current lexical code

      Block                                                                     # Invert non significant white space
       {my ($start, $end) = @_;
        Cmp $eb, $Ascii;
        Jne $end;                                                               # Ascii

        getAlpha $cb;                                                           # Actual character in alphabet
        Cmp $cb, $asciiSpace;
        IfEq
        Then
         {putLexicalCode $WhiteSpace;
          Jmp $next;
         };
        Cmp $cb, $asciiNewLine;
        IfEq
        Then
         {putLexicalCode $WhiteSpace;                                           # Mark new line as not significant
          Jmp $next;
         };
       };

      Block                                                                     # Mark significant white space
       {my ($start, $end) = @_;
        Cmp $eb, $WhiteSpace; Jne $end;                                         # Not significant white space
        putLexicalCode $Ascii;                                                  # Mark as ascii
       };
     });

    PopR;
   } [qw(address size)],  name => q(Unisyn::Parse::ClassifyWhiteSpace);

  $s->call(@parameters);
 } # ClassifyWhiteSpace

sub parseUtf8(@)                                                                # Parse a unisyn expression encoded as utf8.
 {my (@parameters) = @_;                                                        # Parameters
  @_ >= 1 or confess;

  my $s = Subroutine
   {my ($p) = @_;                                                               # Parameters

    PrintOutStringNL "ParseUtf8" if $debug;

    PushR zmm0, zmm1;

    my $source32       = V(u32),
    my $sourceSize32   = V(size32);
    my $sourceLength32 = V(count);
    ConvertUtf8ToUtf32 u8 => $$p{address}, size8 => $$p{size},                  # Convert to utf32
      $source32, $sourceSize32, $sourceLength32;

    if ($debug)
     {PrintOutStringNL "After conversion from utf8 to utf32";
      $sourceSize32   ->outNL("Output Length: ");                               # Write output length
      PrintUtf32($sourceLength32, $source32);                                   # Print utf32
     }

    Vmovdqu8 zmm0, "[".Rd(join ', ', $Lex->{lexicalLow} ->@*)."]";              # Each double is [31::24] Classification, [21::0] Utf32 start character
    Vmovdqu8 zmm1, "[".Rd(join ', ', $Lex->{lexicalHigh}->@*)."]";              # Each double is [31::24] Range offset,   [21::0] Utf32 end character

    ClassifyWithInRangeAndSaveOffset address=>$source32, size=>$sourceLength32; # Alphabetic classification
    if ($debug)
     {PrintOutStringNL "After classification into alphabet ranges";
      PrintUtf32($sourceLength32, $source32);                                   # Print classified utf32
     }

    Vmovdqu8 zmm0, "[".Rd(join ', ', $Lex->{bracketsLow} ->@*)."]";             # Each double is [31::24] Classification, [21::0] Utf32 start character
    Vmovdqu8 zmm1, "[".Rd(join ', ', $Lex->{bracketsHigh}->@*)."]";             # Each double is [31::24] Range offset,   [21::0] Utf32 end character

    ClassifyWithInRange address=>$source32, size=>$sourceLength32;              # Bracket classification
    if ($debug)
     {PrintOutStringNL "After classification into brackets";
      PrintUtf32($sourceLength32, $source32);                                   # Print classified brackets
     }

    my $opens = V(opens, -1);
    MatchBrackets address=>$source32, size=>$sourceLength32, $opens, $$p{fail}; # Match brackets
    if ($debug)
     {PrintOutStringNL "After bracket matching";
      PrintUtf32($sourceLength32, $source32);                                   # Print matched brackets
     }

    ClassifyWhiteSpace address=>$source32, size=>$sourceLength32;               # Classify white space
    if ($debug)
     {PrintOutStringNL "After white space classification";
      PrintUtf32($sourceLength32, $source32);
     }

    ClassifyNewLines address=>$source32, size=>$sourceLength32;                 # Classify new lines
    if ($debug)
     {PrintOutStringNL "After classifying new lines";
      PrintUtf32($sourceLength32, $source32);
     }

    parseExpression source=>$source32, size=>$sourceLength32, $$p{parse};

    $$p{parse}->outNL if $debug;

    PopR;
   } [qw(address size parse fail)], name => q(Unisyn::Parse::parseUtf8);

  $s->call(@parameters);
 } # parseUtf8

#d
sub lexicalData {do {
  my $a = bless({
    alphabetRanges   => 13,
    alphabets        => {
                          "circledLatinLetter"               => "\x{24B6}\x{24B7}\x{24B8}\x{24B9}\x{24BA}\x{24BB}\x{24BC}\x{24BD}\x{24BE}\x{24BF}\x{24C0}\x{24C1}\x{24C2}\x{24C3}\x{24C4}\x{24C5}\x{24C6}\x{24C7}\x{24C8}\x{24C9}\x{24CA}\x{24CB}\x{24CC}\x{24CD}\x{24CE}\x{24CF}\x{24D0}\x{24D1}\x{24D2}\x{24D3}\x{24D4}\x{24D5}\x{24D6}\x{24D7}\x{24D8}\x{24D9}\x{24DA}\x{24DB}\x{24DC}\x{24DD}\x{24DE}\x{24DF}\x{24E0}\x{24E1}\x{24E2}\x{24E3}\x{24E4}\x{24E5}\x{24E6}\x{24E7}\x{24E8}\x{24E9}",
                          "mathematicalBold"                 => "\x{1D400}\x{1D401}\x{1D402}\x{1D403}\x{1D404}\x{1D405}\x{1D406}\x{1D407}\x{1D408}\x{1D409}\x{1D40A}\x{1D40B}\x{1D40C}\x{1D40D}\x{1D40E}\x{1D40F}\x{1D410}\x{1D411}\x{1D412}\x{1D413}\x{1D414}\x{1D415}\x{1D416}\x{1D417}\x{1D418}\x{1D419}\x{1D41A}\x{1D41B}\x{1D41C}\x{1D41D}\x{1D41E}\x{1D41F}\x{1D420}\x{1D421}\x{1D422}\x{1D423}\x{1D424}\x{1D425}\x{1D426}\x{1D427}\x{1D428}\x{1D429}\x{1D42A}\x{1D42B}\x{1D42C}\x{1D42D}\x{1D42E}\x{1D42F}\x{1D430}\x{1D431}\x{1D432}\x{1D433}\x{1D6A8}\x{1D6A9}\x{1D6AA}\x{1D6AB}\x{1D6AC}\x{1D6AD}\x{1D6AE}\x{1D6AF}\x{1D6B0}\x{1D6B1}\x{1D6B2}\x{1D6B3}\x{1D6B4}\x{1D6B5}\x{1D6B6}\x{1D6B7}\x{1D6B8}\x{1D6B9}\x{1D6BA}\x{1D6BB}\x{1D6BC}\x{1D6BD}\x{1D6BE}\x{1D6BF}\x{1D6C0}\x{1D6C1}\x{1D6C2}\x{1D6C3}\x{1D6C4}\x{1D6C5}\x{1D6C6}\x{1D6C7}\x{1D6C8}\x{1D6C9}\x{1D6CA}\x{1D6CB}\x{1D6CC}\x{1D6CD}\x{1D6CE}\x{1D6CF}\x{1D6D0}\x{1D6D1}\x{1D6D2}\x{1D6D3}\x{1D6D4}\x{1D6D5}\x{1D6D6}\x{1D6D7}\x{1D6D8}\x{1D6D9}\x{1D6DA}\x{1D6DB}\x{1D6DC}\x{1D6DD}\x{1D6DE}\x{1D6DF}\x{1D6E0}\x{1D6E1}",
                          "mathematicalBoldFraktur"          => "\x{1D56C}\x{1D56D}\x{1D56E}\x{1D56F}\x{1D570}\x{1D571}\x{1D572}\x{1D573}\x{1D574}\x{1D575}\x{1D576}\x{1D577}\x{1D578}\x{1D579}\x{1D57A}\x{1D57B}\x{1D57C}\x{1D57D}\x{1D57E}\x{1D57F}\x{1D580}\x{1D581}\x{1D582}\x{1D583}\x{1D584}\x{1D585}\x{1D586}\x{1D587}\x{1D588}\x{1D589}\x{1D58A}\x{1D58B}\x{1D58C}\x{1D58D}\x{1D58E}\x{1D58F}\x{1D590}\x{1D591}\x{1D592}\x{1D593}\x{1D594}\x{1D595}\x{1D596}\x{1D597}\x{1D598}\x{1D599}\x{1D59A}\x{1D59B}\x{1D59C}\x{1D59D}\x{1D59E}\x{1D59F}",
                          "mathematicalBoldItalic"           => "\x{1D468}\x{1D469}\x{1D46A}\x{1D46B}\x{1D46C}\x{1D46D}\x{1D46E}\x{1D46F}\x{1D470}\x{1D471}\x{1D472}\x{1D473}\x{1D474}\x{1D475}\x{1D476}\x{1D477}\x{1D478}\x{1D479}\x{1D47A}\x{1D47B}\x{1D47C}\x{1D47D}\x{1D47E}\x{1D47F}\x{1D480}\x{1D481}\x{1D482}\x{1D483}\x{1D484}\x{1D485}\x{1D486}\x{1D487}\x{1D488}\x{1D489}\x{1D48A}\x{1D48B}\x{1D48C}\x{1D48D}\x{1D48E}\x{1D48F}\x{1D490}\x{1D491}\x{1D492}\x{1D493}\x{1D494}\x{1D495}\x{1D496}\x{1D497}\x{1D498}\x{1D499}\x{1D49A}\x{1D49B}\x{1D71C}\x{1D71D}\x{1D71E}\x{1D71F}\x{1D720}\x{1D721}\x{1D722}\x{1D723}\x{1D724}\x{1D725}\x{1D726}\x{1D727}\x{1D728}\x{1D729}\x{1D72A}\x{1D72B}\x{1D72C}\x{1D72D}\x{1D72E}\x{1D72F}\x{1D730}\x{1D731}\x{1D732}\x{1D733}\x{1D734}\x{1D735}\x{1D736}\x{1D737}\x{1D738}\x{1D739}\x{1D73A}\x{1D73B}\x{1D73C}\x{1D73D}\x{1D73E}\x{1D73F}\x{1D740}\x{1D741}\x{1D742}\x{1D743}\x{1D744}\x{1D745}\x{1D746}\x{1D747}\x{1D748}\x{1D749}\x{1D74A}\x{1D74B}\x{1D74C}\x{1D74D}\x{1D74E}\x{1D74F}\x{1D750}\x{1D751}\x{1D752}\x{1D753}\x{1D754}\x{1D755}",
                          "mathematicalBoldScript"           => "\x{1D4D0}\x{1D4D1}\x{1D4D2}\x{1D4D3}\x{1D4D4}\x{1D4D5}\x{1D4D6}\x{1D4D7}\x{1D4D8}\x{1D4D9}\x{1D4DA}\x{1D4DB}\x{1D4DC}\x{1D4DD}\x{1D4DE}\x{1D4DF}\x{1D4E0}\x{1D4E1}\x{1D4E2}\x{1D4E3}\x{1D4E4}\x{1D4E5}\x{1D4E6}\x{1D4E7}\x{1D4E8}\x{1D4E9}\x{1D4EA}\x{1D4EB}\x{1D4EC}\x{1D4ED}\x{1D4EE}\x{1D4EF}\x{1D4F0}\x{1D4F1}\x{1D4F2}\x{1D4F3}\x{1D4F4}\x{1D4F5}\x{1D4F6}\x{1D4F7}\x{1D4F8}\x{1D4F9}\x{1D4FA}\x{1D4FB}\x{1D4FC}\x{1D4FD}\x{1D4FE}\x{1D4FF}\x{1D500}\x{1D501}\x{1D502}\x{1D503}",
                          "mathematicalDouble-struck"        => "\x{1D538}\x{1D539}\x{1D53B}\x{1D53C}\x{1D53D}\x{1D53E}\x{1D540}\x{1D541}\x{1D542}\x{1D543}\x{1D544}\x{1D546}\x{1D54A}\x{1D54B}\x{1D54C}\x{1D54D}\x{1D54E}\x{1D54F}\x{1D550}\x{1D552}\x{1D553}\x{1D554}\x{1D555}\x{1D556}\x{1D557}\x{1D558}\x{1D559}\x{1D55A}\x{1D55B}\x{1D55C}\x{1D55D}\x{1D55E}\x{1D55F}\x{1D560}\x{1D561}\x{1D562}\x{1D563}\x{1D564}\x{1D565}\x{1D566}\x{1D567}\x{1D568}\x{1D569}\x{1D56A}\x{1D56B}",
                          "mathematicalFraktur"              => "\x{1D504}\x{1D505}\x{1D507}\x{1D508}\x{1D509}\x{1D50A}\x{1D50D}\x{1D50E}\x{1D50F}\x{1D510}\x{1D511}\x{1D512}\x{1D513}\x{1D514}\x{1D516}\x{1D517}\x{1D518}\x{1D519}\x{1D51A}\x{1D51B}\x{1D51C}\x{1D51E}\x{1D51F}\x{1D520}\x{1D521}\x{1D522}\x{1D523}\x{1D524}\x{1D525}\x{1D526}\x{1D527}\x{1D528}\x{1D529}\x{1D52A}\x{1D52B}\x{1D52C}\x{1D52D}\x{1D52E}\x{1D52F}\x{1D530}\x{1D531}\x{1D532}\x{1D533}\x{1D534}\x{1D535}\x{1D536}\x{1D537}",
                          "mathematicalItalic"               => "\x{1D434}\x{1D435}\x{1D436}\x{1D437}\x{1D438}\x{1D439}\x{1D43A}\x{1D43B}\x{1D43C}\x{1D43D}\x{1D43E}\x{1D43F}\x{1D440}\x{1D441}\x{1D442}\x{1D443}\x{1D444}\x{1D445}\x{1D446}\x{1D447}\x{1D448}\x{1D449}\x{1D44A}\x{1D44B}\x{1D44C}\x{1D44D}\x{1D44E}\x{1D44F}\x{1D450}\x{1D451}\x{1D452}\x{1D453}\x{1D454}\x{1D456}\x{1D457}\x{1D458}\x{1D459}\x{1D45A}\x{1D45B}\x{1D45C}\x{1D45D}\x{1D45E}\x{1D45F}\x{1D460}\x{1D461}\x{1D462}\x{1D463}\x{1D464}\x{1D465}\x{1D466}\x{1D467}\x{1D6E2}\x{1D6E3}\x{1D6E4}\x{1D6E5}\x{1D6E6}\x{1D6E7}\x{1D6E8}\x{1D6E9}\x{1D6EA}\x{1D6EB}\x{1D6EC}\x{1D6ED}\x{1D6EE}\x{1D6EF}\x{1D6F0}\x{1D6F1}\x{1D6F2}\x{1D6F3}\x{1D6F4}\x{1D6F5}\x{1D6F6}\x{1D6F7}\x{1D6F8}\x{1D6F9}\x{1D6FA}\x{1D6FB}\x{1D6FC}\x{1D6FD}\x{1D6FE}\x{1D6FF}\x{1D700}\x{1D701}\x{1D702}\x{1D703}\x{1D704}\x{1D705}\x{1D706}\x{1D707}\x{1D708}\x{1D709}\x{1D70A}\x{1D70B}\x{1D70C}\x{1D70D}\x{1D70E}\x{1D70F}\x{1D710}\x{1D711}\x{1D712}\x{1D713}\x{1D714}\x{1D715}\x{1D716}\x{1D717}\x{1D718}\x{1D719}\x{1D71A}\x{1D71B}",
                          "mathematicalMonospace"            => "\x{1D670}\x{1D671}\x{1D672}\x{1D673}\x{1D674}\x{1D675}\x{1D676}\x{1D677}\x{1D678}\x{1D679}\x{1D67A}\x{1D67B}\x{1D67C}\x{1D67D}\x{1D67E}\x{1D67F}\x{1D680}\x{1D681}\x{1D682}\x{1D683}\x{1D684}\x{1D685}\x{1D686}\x{1D687}\x{1D688}\x{1D689}\x{1D68A}\x{1D68B}\x{1D68C}\x{1D68D}\x{1D68E}\x{1D68F}\x{1D690}\x{1D691}\x{1D692}\x{1D693}\x{1D694}\x{1D695}\x{1D696}\x{1D697}\x{1D698}\x{1D699}\x{1D69A}\x{1D69B}\x{1D69C}\x{1D69D}\x{1D69E}\x{1D69F}\x{1D6A0}\x{1D6A1}\x{1D6A2}\x{1D6A3}",
                          "mathematicalSans-serif"           => "\x{1D5A0}\x{1D5A1}\x{1D5A2}\x{1D5A3}\x{1D5A4}\x{1D5A5}\x{1D5A6}\x{1D5A7}\x{1D5A8}\x{1D5A9}\x{1D5AA}\x{1D5AB}\x{1D5AC}\x{1D5AD}\x{1D5AE}\x{1D5AF}\x{1D5B0}\x{1D5B1}\x{1D5B2}\x{1D5B3}\x{1D5B4}\x{1D5B5}\x{1D5B6}\x{1D5B7}\x{1D5B8}\x{1D5B9}\x{1D5BA}\x{1D5BB}\x{1D5BC}\x{1D5BD}\x{1D5BE}\x{1D5BF}\x{1D5C0}\x{1D5C1}\x{1D5C2}\x{1D5C3}\x{1D5C4}\x{1D5C5}\x{1D5C6}\x{1D5C7}\x{1D5C8}\x{1D5C9}\x{1D5CA}\x{1D5CB}\x{1D5CC}\x{1D5CD}\x{1D5CE}\x{1D5CF}\x{1D5D0}\x{1D5D1}\x{1D5D2}\x{1D5D3}",
                          "mathematicalSans-serifBold"       => "\x{1D5D4}\x{1D5D5}\x{1D5D6}\x{1D5D7}\x{1D5D8}\x{1D5D9}\x{1D5DA}\x{1D5DB}\x{1D5DC}\x{1D5DD}\x{1D5DE}\x{1D5DF}\x{1D5E0}\x{1D5E1}\x{1D5E2}\x{1D5E3}\x{1D5E4}\x{1D5E5}\x{1D5E6}\x{1D5E7}\x{1D5E8}\x{1D5E9}\x{1D5EA}\x{1D5EB}\x{1D5EC}\x{1D5ED}\x{1D5EE}\x{1D5EF}\x{1D5F0}\x{1D5F1}\x{1D5F2}\x{1D5F3}\x{1D5F4}\x{1D5F5}\x{1D5F6}\x{1D5F7}\x{1D5F8}\x{1D5F9}\x{1D5FA}\x{1D5FB}\x{1D5FC}\x{1D5FD}\x{1D5FE}\x{1D5FF}\x{1D600}\x{1D601}\x{1D602}\x{1D603}\x{1D604}\x{1D605}\x{1D606}\x{1D607}\x{1D756}\x{1D757}\x{1D758}\x{1D759}\x{1D75A}\x{1D75B}\x{1D75C}\x{1D75D}\x{1D75E}\x{1D75F}\x{1D760}\x{1D761}\x{1D762}\x{1D763}\x{1D764}\x{1D765}\x{1D766}\x{1D767}\x{1D768}\x{1D769}\x{1D76A}\x{1D76B}\x{1D76C}\x{1D76D}\x{1D76E}\x{1D76F}\x{1D770}\x{1D771}\x{1D772}\x{1D773}\x{1D774}\x{1D775}\x{1D776}\x{1D777}\x{1D778}\x{1D779}\x{1D77A}\x{1D77B}\x{1D77C}\x{1D77D}\x{1D77E}\x{1D77F}\x{1D780}\x{1D781}\x{1D782}\x{1D783}\x{1D784}\x{1D785}\x{1D786}\x{1D787}\x{1D788}\x{1D789}\x{1D78A}\x{1D78B}\x{1D78C}\x{1D78D}\x{1D78E}\x{1D78F}",
                          "mathematicalSans-serifBoldItalic" => "\x{1D63C}\x{1D63D}\x{1D63E}\x{1D63F}\x{1D640}\x{1D641}\x{1D642}\x{1D643}\x{1D644}\x{1D645}\x{1D646}\x{1D647}\x{1D648}\x{1D649}\x{1D64A}\x{1D64B}\x{1D64C}\x{1D64D}\x{1D64E}\x{1D64F}\x{1D650}\x{1D651}\x{1D652}\x{1D653}\x{1D654}\x{1D655}\x{1D656}\x{1D657}\x{1D658}\x{1D659}\x{1D65A}\x{1D65B}\x{1D65C}\x{1D65D}\x{1D65E}\x{1D65F}\x{1D660}\x{1D661}\x{1D662}\x{1D663}\x{1D664}\x{1D665}\x{1D666}\x{1D667}\x{1D668}\x{1D669}\x{1D66A}\x{1D66B}\x{1D66C}\x{1D66D}\x{1D66E}\x{1D66F}\x{1D790}\x{1D791}\x{1D792}\x{1D793}\x{1D794}\x{1D795}\x{1D796}\x{1D797}\x{1D798}\x{1D799}\x{1D79A}\x{1D79B}\x{1D79C}\x{1D79D}\x{1D79E}\x{1D79F}\x{1D7A0}\x{1D7A1}\x{1D7A2}\x{1D7A3}\x{1D7A4}\x{1D7A5}\x{1D7A6}\x{1D7A7}\x{1D7A8}\x{1D7A9}\x{1D7AA}\x{1D7AB}\x{1D7AC}\x{1D7AD}\x{1D7AE}\x{1D7AF}\x{1D7B0}\x{1D7B1}\x{1D7B2}\x{1D7B3}\x{1D7B4}\x{1D7B5}\x{1D7B6}\x{1D7B7}\x{1D7B8}\x{1D7B9}\x{1D7BA}\x{1D7BB}\x{1D7BC}\x{1D7BD}\x{1D7BE}\x{1D7BF}\x{1D7C0}\x{1D7C1}\x{1D7C2}\x{1D7C3}\x{1D7C4}\x{1D7C5}\x{1D7C6}\x{1D7C7}\x{1D7C8}\x{1D7C9}",
                          "mathematicalSans-serifItalic"     => "\x{1D608}\x{1D609}\x{1D60A}\x{1D60B}\x{1D60C}\x{1D60D}\x{1D60E}\x{1D60F}\x{1D610}\x{1D611}\x{1D612}\x{1D613}\x{1D614}\x{1D615}\x{1D616}\x{1D617}\x{1D618}\x{1D619}\x{1D61A}\x{1D61B}\x{1D61C}\x{1D61D}\x{1D61E}\x{1D61F}\x{1D620}\x{1D621}\x{1D622}\x{1D623}\x{1D624}\x{1D625}\x{1D626}\x{1D627}\x{1D628}\x{1D629}\x{1D62A}\x{1D62B}\x{1D62C}\x{1D62D}\x{1D62E}\x{1D62F}\x{1D630}\x{1D631}\x{1D632}\x{1D633}\x{1D634}\x{1D635}\x{1D636}\x{1D637}\x{1D638}\x{1D639}\x{1D63A}\x{1D63B}",
                          "mathematicalScript"               => "\x{1D49C}\x{1D49E}\x{1D49F}\x{1D4A2}\x{1D4A5}\x{1D4A6}\x{1D4A9}\x{1D4AA}\x{1D4AB}\x{1D4AC}\x{1D4AE}\x{1D4AF}\x{1D4B0}\x{1D4B1}\x{1D4B2}\x{1D4B3}\x{1D4B4}\x{1D4B5}\x{1D4B6}\x{1D4B7}\x{1D4B8}\x{1D4B9}\x{1D4BB}\x{1D4BD}\x{1D4BE}\x{1D4BF}\x{1D4C0}\x{1D4C1}\x{1D4C2}\x{1D4C3}\x{1D4C5}\x{1D4C6}\x{1D4C7}\x{1D4C8}\x{1D4C9}\x{1D4CA}\x{1D4CB}\x{1D4CC}\x{1D4CD}\x{1D4CE}\x{1D4CF}",
                          "negativeCircledLatinLetter"       => "\x{1F150}\x{1F151}\x{1F152}\x{1F153}\x{1F154}\x{1F155}\x{1F156}\x{1F157}\x{1F158}\x{1F159}\x{1F15A}\x{1F15B}\x{1F15C}\x{1F15D}\x{1F15E}\x{1F15F}\x{1F160}\x{1F161}\x{1F162}\x{1F163}\x{1F164}\x{1F165}\x{1F166}\x{1F167}\x{1F168}\x{1F169}",
                          "negativeSquaredLatinLetter"       => "\x{1F170}\x{1F171}\x{1F172}\x{1F173}\x{1F174}\x{1F175}\x{1F176}\x{1F177}\x{1F178}\x{1F179}\x{1F17A}\x{1F17B}\x{1F17C}\x{1F17D}\x{1F17E}\x{1F17F}\x{1F180}\x{1F181}\x{1F182}\x{1F183}\x{1F184}\x{1F185}\x{1F186}\x{1F187}\x{1F188}\x{1F189}",
                          "semiColon"                        => "\x{27E2}",
                          "squaredLatinLetter"               => "\x{1F130}\x{1F131}\x{1F132}\x{1F133}\x{1F134}\x{1F135}\x{1F136}\x{1F137}\x{1F138}\x{1F139}\x{1F13A}\x{1F13B}\x{1F13C}\x{1F13D}\x{1F13E}\x{1F13F}\x{1F140}\x{1F141}\x{1F142}\x{1F143}\x{1F144}\x{1F145}\x{1F146}\x{1F147}\x{1F148}\x{1F149}\x{1F1A5}",
                        },
    brackets         => 16,
    bracketsBase     => 16,
    bracketsClose    => [
                          "\x{2309}",
                          "\x{230B}",
                          "\x{232A}",
                          "\x{2769}",
                          "\x{276B}",
                          "\x{276D}",
                          "\x{276F}",
                          "\x{2771}",
                          "\x{2773}",
                          "\x{2775}",
                          "\x{27E7}",
                          "\x{27E9}",
                          "\x{27EB}",
                          "\x{27ED}",
                          "\x{27EF}",
                          "\x{2984}",
                          "\x{2986}",
                          "\x{2988}",
                          "\x{298A}",
                          "\x{298C}",
                          "\x{298E}",
                          "\x{2990}",
                          "\x{2992}",
                          "\x{2994}",
                          "\x{2996}",
                          "\x{2998}",
                          "\x{29FD}",
                          "\x{2E29}",
                          "\x{3009}",
                          "\x{300B}",
                          "\x{3011}",
                          "\x{3015}",
                          "\x{3017}",
                          "\x{3019}",
                          "\x{301B}",
                          "\x{FD3F}",
                          "\x{FF09}",
                          "\x{FF60}",
                        ],
    bracketsHigh     => [
                          "0x1300230b",
                          "0x1500232a",
                          "0x23002775",
                          "0x2d0027ef",
                          "0x43002998",
                          "0x450029fd",
                          "0x47002e29",
                          "0x4b00300b",
                          "0x4d003011",
                          "0x5500301b",
                          "0x5700fd3f",
                          "0x5900ff09",
                          "0x5b00ff60",
                          0,
                          0,
                          0,
                        ],
    bracketsLow      => [
                          "0x10002308",
                          "0x14002329",
                          "0x16002768",
                          "0x240027e6",
                          "0x2e002983",
                          "0x440029fc",
                          "0x46002e28",
                          "0x48003008",
                          "0x4c003010",
                          "0x4e003014",
                          "0x5600fd3e",
                          "0x5800ff08",
                          "0x5a00ff5f",
                          0,
                          0,
                          0,
                        ],
    bracketsOpen     => [
                          "\x{2308}",
                          "\x{230A}",
                          "\x{2329}",
                          "\x{2768}",
                          "\x{276A}",
                          "\x{276C}",
                          "\x{276E}",
                          "\x{2770}",
                          "\x{2772}",
                          "\x{2774}",
                          "\x{27E6}",
                          "\x{27E8}",
                          "\x{27EA}",
                          "\x{27EC}",
                          "\x{27EE}",
                          "\x{2983}",
                          "\x{2985}",
                          "\x{2987}",
                          "\x{2989}",
                          "\x{298B}",
                          "\x{298D}",
                          "\x{298F}",
                          "\x{2991}",
                          "\x{2993}",
                          "\x{2995}",
                          "\x{2997}",
                          "\x{29FC}",
                          "\x{2E28}",
                          "\x{3008}",
                          "\x{300A}",
                          "\x{3010}",
                          "\x{3014}",
                          "\x{3016}",
                          "\x{3018}",
                          "\x{301A}",
                          "\x{FD3E}",
                          "\x{FF08}",
                          "\x{FF5F}",
                        ],
    lexicalAlpha     => {
                          ""             => [
                                              "circledLatinLetter",
                                              "mathematicalBoldFraktur",
                                              "mathematicalBoldScript",
                                              "mathematicalDouble-struck",
                                              "mathematicalFraktur",
                                              "mathematicalMonospace",
                                              "mathematicalSans-serif",
                                              "mathematicalSans-serifItalic",
                                              "mathematicalScript",
                                              "negativeSquaredLatinLetter",
                                              "semiColon",
                                              "squaredLatinLetter",
                                            ],
                          "Ascii"        => ["negativeCircledLatinLetter"],
                          "assign"       => ["mathematicalItalic"],
                          "CloseBracket" => [],
                          "dyad"         => ["mathematicalBold"],
                          "OpenBracket"  => [],
                          "prefix"       => ["mathematicalBoldItalic"],
                          "semiColon"    => [],
                          "suffix"       => ["mathematicalSans-serifBoldItalic"],
                          "term"         => [],
                          "variable"     => ["mathematicalSans-serifBold"],
                        },
    lexicalHigh      => [
                          127,
                          10210,
                          119859,
                          119911,
                          119963,
                          120327,
                          120431,
                          872535777,
                          872535835,
                          872535893,
                          872535951,
                          872536009,
                          2147610985,
                          0,
                          0,
                          0,
                        ],
    lexicalLow       => [
                          33554432,
                          134227938,
                          50451456,
                          84005940,
                          67228776,
                          100783572,
                          117560892,
                          50452136,
                          84006626,
                          67229468,
                          100783958,
                          117561232,
                          33681744,
                          0,
                          0,
                          0,
                        ],
    lexicals         => bless({
                          Ascii            => bless({ letter => "a", like => "v", name => "Ascii", number => 2 }, "Unisyn::Parse::Lexical::Constant"),
                          assign           => bless({ letter => "a", like => "a", name => "assign", number => 5 }, "Unisyn::Parse::Lexical::Constant"),
                          CloseBracket     => bless({ letter => "B", like => "B", name => "CloseBracket", number => 1 }, "Unisyn::Parse::Lexical::Constant"),
                          dyad             => bless({ letter => "d", like => "d", name => "dyad", number => 3 }, "Unisyn::Parse::Lexical::Constant"),
                          empty            => bless({ letter => "e", like => "e", name => "empty", number => 10 }, "Unisyn::Parse::Lexical::Constant"),
                          NewLineSemiColon => bless({ letter => "N", like => undef, name => "NewLineSemiColon", number => 12 }, "Unisyn::Parse::Lexical::Constant"),
                          OpenBracket      => bless({ letter => "b", like => "b", name => "OpenBracket", number => 0 }, "Unisyn::Parse::Lexical::Constant"),
                          prefix           => bless({ letter => "p", like => "p", name => "prefix", number => 4 }, "Unisyn::Parse::Lexical::Constant"),
                          semiColon        => bless({ letter => "s", like => "s", name => "semiColon", number => 8 }, "Unisyn::Parse::Lexical::Constant"),
                          suffix           => bless({ letter => "q", like => "q", name => "suffix", number => 7 }, "Unisyn::Parse::Lexical::Constant"),
                          term             => bless({ letter => "t", like => "t", name => "term", number => 9 }, "Unisyn::Parse::Lexical::Constant"),
                          variable         => bless({ letter => "v", like => "v", name => "variable", number => 6 }, "Unisyn::Parse::Lexical::Constant"),
                          WhiteSpace       => bless({ letter => "W", like => undef, name => "WhiteSpace", number => 11 }, "Unisyn::Parse::Lexical::Constant"),
                        }, "Unisyn::Parse::Lexicals"),
    sampleLexicals   => {
                          brackets => [
                            100663296,
                            83886080,
                            0,
                            0,
                            0,
                            100663296,
                            16777216,
                            16777216,
                            50331648,
                            0,
                            100663296,
                            16777216,
                            16777216,
                            134217728,
                          ],
                          nosemi => [
                            100663296,
                            83886080,
                            0,
                            0,
                            0,
                            100663296,
                            16777216,
                            16777216,
                            50331648,
                            0,
                            100663296,
                            16777216,
                            16777216,
                          ],
                          s1 => [
                            100663296,
                            83886080,
                            33554442,
                            33554464,
                            33554464,
                            33554497,
                            33554442,
                            33554464,
                            33554464,
                            33554464,
                          ],
                          v => [100663296],
                          vav => [100663296, 83886080, 100663296],
                          vnsvs => [
                            100663296,
                            33554442,
                            33554464,
                            33554464,
                            33554464,
                            100663296,
                            33554464,
                            33554464,
                            33554464,
                          ],
                          vnv => [100663296, 33554442, 100663296],
                          vnvs => [
                            100663296,
                            33554442,
                            100663296,
                            33554464,
                            33554464,
                            33554464,
                            33554464,
                          ],
                          ws => [
                            100663296,
                            83886080,
                            0,
                            0,
                            0,
                            100663296,
                            16777216,
                            16777216,
                            50331648,
                            0,
                            100663296,
                            16777216,
                            16777216,
                            134217728,
                            100663296,
                            83886080,
                            33554497,
                            50331648,
                            100663296,
                            134217728,
                          ],
                        },
    sampleText       => {
                          brackets => "\x{1D5EE}\x{1D44E}\x{1D460}\x{1D460}\x{1D456}\x{1D454}\x{1D45B}\x{230A}\x{2329}\x{2768}\x{1D5EF}\x{1D5FD}\x{2769}\x{232A}\x{1D429}\x{1D425}\x{1D42E}\x{1D42C}\x{276A}\x{1D600}\x{1D5F0}\x{276B}\x{230B}\x{27E2}",
                          nosemi => "\x{1D5EE}\x{1D44E}\x{1D460}\x{1D460}\x{1D456}\x{1D454}\x{1D45B}\x{230A}\x{2329}\x{2768}\x{1D5EF}\x{1D5FD}\x{2769}\x{232A}\x{1D429}\x{1D425}\x{1D42E}\x{1D42C}\x{276A}\x{1D600}\x{1D5F0}\x{276B}\x{230B}",
                          s1 => "\x{1D5EE}\x{1D44E}\n  A\n   ",
                          v => "\x{1D5EE}",
                          vav => "\x{1D78F}\x{1D44E}\x{1D78F}",
                          vnsvs => "\x{1D5EE}\x{1D5EE}\n   \x{1D5EF}\x{1D5EF}   ",
                          vnv => "\x{1D5EE}\n\x{1D5EF}",
                          vnvs => "\x{1D5EE}\n\x{1D5EF}    ",
                          ws => "\x{1D5EE}\x{1D44E}\x{1D460}\x{1D460}\x{1D456}\x{1D454}\x{1D45B}\x{230A}\x{2329}\x{2768}\x{1D5EF}\x{1D5FD}\x{2769}\x{232A}\x{1D429}\x{1D425}\x{1D42E}\x{1D42C}\x{276A}\x{1D600}\x{1D5F0}\x{276B}\x{230B}\x{27E2}\x{1D5EE}\x{1D5EE}\x{1D44E}\x{1D460}\x{1D460}\x{1D456}\x{1D454}\x{1D45B}A\x{1D429}\x{1D425}\x{1D42E}\x{1D42C}\x{1D5F0}\x{1D5F0}\x{27E2}",
                        },
    semiColon        => "\x{27E2}",
    separator        => "\x{205F}",
    structure        => bless({
                          codes => bless({
                                     a => bless({
                                            letter => "a",
                                            name   => "assignment operator",
                                            next   => "bpv",
                                            short  => "assign",
                                          }, "Tree::Term::LexicalCode"),
                                     B => bless({
                                            letter => "B",
                                            name   => "closing parenthesis",
                                            next   => "aBdqs",
                                            short  => "CloseBracket",
                                          }, "Tree::Term::LexicalCode"),
                                     b => bless({
                                            letter => "b",
                                            name   => "opening parenthesis",
                                            next   => "bBpsv",
                                            short  => "OpenBracket",
                                          }, "Tree::Term::LexicalCode"),
                                     d => bless({ letter => "d", name => "dyadic operator", next => "bpv", short => "dyad" }, "Tree::Term::LexicalCode"),
                                     p => bless({ letter => "p", name => "prefix operator", next => "bpv", short => "prefix" }, "Tree::Term::LexicalCode"),
                                     q => bless({
                                            letter => "q",
                                            name   => "suffix operator",
                                            next   => "aBdqs",
                                            short  => "suffix",
                                          }, "Tree::Term::LexicalCode"),
                                     s => bless({ letter => "s", name => "semi-colon", next => "bBpsv", short => "semiColon" }, "Tree::Term::LexicalCode"),
                                     t => bless({ letter => "t", name => "term", next => "aBdqs", short => "term" }, "Tree::Term::LexicalCode"),
                                     v => bless({ letter => "v", name => "variable", next => "aBdqs", short => "variable" }, "Tree::Term::LexicalCode"),
                                   }, "Tree::Term::Codes"),
                          first => "bpsv",
                          last  => "Bqsv",
                        }, "Tree::Term::LexicalStructure"),
    treeTermLexicals => 'fix',
  }, "Unisyn::Parse::Lexical::Tables");
  $a->{treeTermLexicals} = $a->{structure}{codes};
  $a;
}}

#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all => [@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Unisyn::Parse - Parse a Unisyn expression.

=head1 Synopsis

Parse a Unisyn expression.

=head1 Description

Parse a Unisyn expression.


Version "20210810".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Parse

Parse Unisyn expressions

=head2 parseUtf8(@parameters)

Parse a unisyn expression encoded as utf8

     Parameter    Description
  1  @parameters  Parameters

B<Example:>



    parseUtf8  V(address, $address),  $size, $fail, $parse;                         # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 printParseTree()

Print the parse tree addressed  by r15


B<Example:>


    my $l = $Lex->{sampleLexicals}{vav};
    Mov $start,  Rd(@$l);
    Mov $size,   scalar(@$l);

    parseExpressionCode;
    PrintOutStringNL "Result:";
    PrintOutRegisterInHex r15;


    printParseTree;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok Assemble(debug => 0, eq => <<END);
  Push Element:
     r13: 0000 0000 0000 0006
  New: accept initial variable
  New: accept initial variable
      r8: 0000 0000 0000 0006
     r13: 0000 0001 0000 0005
  accept a
  Push Element:
     r13: 0000 0001 0000 0005
     r13: 0000 0002 0000 0006
  accept v
  Push Element:
     r13: 0000 0002 0000 0006
  New: Variable
  New: Variable
      r8: 0000 0002 0000 0006
  Reduce 3:
      r8: 0000 0098 0000 0009
      r9: 0000 0001 0000 0005
     r10: 0000 0118 0000 0009
  New: Term infix term
  New: Term infix term
      r8: 0000 0118 0000 0009
      r8: 0000 0098 0000 0009
      r8: 0000 0001 0000 0005
  Result:
     r15: 0000 0198 0000 0009
  Tree at:    r15: 0000 0000 0000 0198
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0003 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0118 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0004 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0005 data: 0000 0000 0000 0098 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0006 data: 0000 0000 0000 0005 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0007 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0098
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0006 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0000 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0118
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0006 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0002 depth: 0000 0000 0000 0001
  END



=head1 Private Methods

=head2 getAlpha($register, $address, $index)

Load the position of a lexical item in its alphabet from the current character

     Parameter  Description
  1  $register  Register to load
  2  $address   Address of start of string
  3  $index     Index into string

=head2 getLexicalCode($register, $address, $index)

Load the lexical code of the current character in memory into the specified register.

     Parameter  Description
  1  $register  Register to load
  2  $address   Address of start of string
  3  $index     Index into string

=head2 putLexicalCode($register, $address, $index, $code)

Put the specified lexical code into the current character in memory.

     Parameter  Description
  1  $register  Register used to load code
  2  $address   Address of string
  3  $index     Index into string
  4  $code      Code to put

=head2 loadCurrentChar()

Load the details of the character currently being processed so that we have the index of the character in the upper half of the current character and the lexical type of the character in the lowest byte


=head2 checkStackHas($depth)

Check that we have at least the specified number of elements on the stack

     Parameter  Description
  1  $depth     Number of elements required on the stack

B<Example:>


    my @o = (Rb(reverse 0x10,              0, 0, 1),                              # Open bracket
             Rb(reverse 0x11,              0, 0, 2),                              # Close bracket
             Rb(reverse $Ascii,            0, 0, 27),                             # Ascii 'a'
             Rb(reverse $variable,         0, 0, 27),                             # Variable 'a'
             Rb(reverse $NewLineSemiColon, 0, 0, 0),                              # New line semicolon
             Rb(reverse $semiColon,        0, 0, 0));                             # Semi colon

    for my $o(@o)                                                                 # Try converting each input element
     {Mov $start, $o;
      Mov $index, 0;
      loadCurrentChar;
      PrintOutRegisterInHex $element;
     }

    ok Assemble(debug => 0, eq => <<END);
     r13: 0000 0000 0000 0000
     r13: 0000 0000 0000 0001
     r13: 0000 0000 0000 0006
     r13: 0000 0000 0000 0006
     r13: 0000 0000 0000 0008
     r13: 0000 0000 0000 0008
  END

    PushR $parseStackBase;
    Mov   $parseStackBase, rsp;
    Push rax;
    Push rax;

    checkStackHas 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    IfEq Then {PrintOutStringNL "ok"},   Else {PrintOutStringNL "fail"}; checkStackHas 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    IfGe Then {PrintOutStringNL "ok"},   Else {PrintOutStringNL "fail"}; checkStackHas 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    IfGt Then {PrintOutStringNL "fail"}, Else {PrintOutStringNL "ok"};

    Push rax;                                                            checkStackHas 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    IfEq Then {PrintOutStringNL "ok"},   Else {PrintOutStringNL "fail"}; checkStackHas 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    IfGe Then {PrintOutStringNL "ok"},   Else {PrintOutStringNL "fail"}; checkStackHas 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    IfGt Then {PrintOutStringNL "fail"}, Else {PrintOutStringNL "ok"};
    ok Assemble(debug => 0, eq => <<END);
  ok
  ok
  ok
  ok
  ok
  ok
  END


=head2 pushElement()

Push the current element on to the stack


=head2 pushEmpty()

Push the empty element on to the stack


B<Example:>


    Mov $index, 1;

    pushEmpty;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Mov rax, "[rsp]";
    PrintOutRegisterInHex rax;
    ok Assemble(debug => 0, eq => <<END);
  Push Empty
     rax: 0000 0001 0000 000A
  END


=head2 lexicalNameFromLetter($l)

Lexical name for a lexical item described by its letter

     Parameter  Description
  1  $l         Letter of the lexical item

B<Example:>



    is_deeply lexicalNameFromLetter('a'), q(assign);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply lexicalNumberFromLetter('a'), $assign;


=head2 lexicalNumberFromLetter($l)

Lexical number for a lexical item described by its letter

     Parameter  Description
  1  $l         Letter of the lexical item

B<Example:>


    is_deeply lexicalNameFromLetter('a'), q(assign);

    is_deeply lexicalNumberFromLetter('a'), $assign;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head2 new2($depth, $description)

Create a new term in the parse tree rooted on the stack.

     Parameter     Description
  1  $depth        Stack depth to be converted
  2  $description  Text reason why we are creating a new term

=head2 new($depth, $description)

Create a new term

     Parameter     Description
  1  $depth        Stack depth to be converted
  2  $description  Text reason why we are creating a new term

B<Example:>


    Mov $index,  1;
    Mov rax,-1; Push rax;
    Mov rax, 3; Push rax;
    Mov rax, 2; Push rax;
    Mov rax, 1; Push rax;

    new 3, 'test';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Pop rax;  PrintOutRegisterInHex rax;
    Pop rax;  PrintOutRegisterInHex rax;
    ok Assemble(debug => 0, eq => <<END);
  New: test
      r8: 0000 0000 0000 0001
      r8: 0000 0000 0000 0002
      r8: 0000 0000 0000 0003
     rax: 0000 0000 0000 0009
     rax: FFFF FFFF FFFF FFFF
  END


=head2 error($message)

Die

     Parameter  Description
  1  $message   Error message

B<Example:>



    error "aaa bbbb";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok Assemble(debug => 0, eq => <<END);
  Error: aaa bbbb
  Element:    r13: 0000 0000 0000 0000
  Index  :    r12: 0000 0000 0000 0000
  END


=head2 testSet($set, $register)

Test a set of items, setting the Zero Flag is one matches else clear the Zero flag

     Parameter  Description
  1  $set       Set of lexical letters
  2  $register  Register to test

B<Example:>


    Mov r15,  -1;
    Mov r15b, $term;

    testSet("ast", r15);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutZF;

    testSet("as",  r15);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutZF;
    ok Assemble(debug => 0, eq => <<END);
  ZF=1
  ZF=0
  END


=head2 checkSet($set)

Check that one of a set of items is on the top of the stack or complain if it is not

     Parameter  Description
  1  $set       Set of lexical letters

B<Example:>


    Mov r15,  -1;
    Mov r15b, $term;
    Push r15;

    checkSet("ast");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutZF;

    checkSet("as");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    PrintOutZF;
    ok Assemble(debug => 0, eq => <<END);
  ZF=1
  Error: Expected one of: 'as' on the stack
  Element:    r13: 0000 0000 0000 0000
  Index  :    r12: 0000 0000 0000 0000
  END


=head2 reduce($priority)

Convert the longest possible expression on top of the stack into a term  at the specified priority

     Parameter  Description
  1  $priority  Priority of the operators to reduce

B<Example:>


    Mov rsi, rsp;                                                                 # Create parse stack base
    Mov r15,    -1;   Push r15;
    Mov r15, $term;   Push r15;
    Mov r15, $assign; Push r15;
    Mov r15, $term;   Push r15;

    reduce 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Pop r15; PrintOutRegisterInHex r15;
    Pop r14; PrintOutRegisterInHex r14;
    ok Assemble(debug => 0, eq => <<END);
  Reduce 3:
      r8: 0000 0000 0000 0009
      r9: 0000 0000 0000 0005
     r10: 0000 0000 0000 0009
  New: Term infix term
      r8: 0000 0000 0000 0009
      r8: 0000 0000 0000 0009
      r8: 0000 0000 0000 0005
     r15: 0000 0000 0000 0009
     r14: FFFF FFFF FFFF FFFF
  END


=head2 reduceMultiple($priority)

Reduce existing operators on the stack

     Parameter  Description
  1  $priority  Priority of the operators to reduce

B<Example:>


    Mov rsi, rsp;                                                                 # Create parse stack base
    Mov r15,           -1;  Push r15;
    Mov r15, $OpenBracket;  Push r15;

    reduceMultiple 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    Pop r15; PrintOutRegisterInHex r15;
    Pop r14; PrintOutRegisterInHex r14;
    ok Assemble(debug => 0, eq => <<END);
  Reduce 2:
      r8: 0000 0000 0000 0010
      r9: 0000 0000 0000 0000
     r15: 0000 0000 0000 0000
     r14: FFFF FFFF FFFF FFFF
  END


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


=head2 parseExpressionCode()

Parse the string of classified lexical items addressed by register $start of length $length.  The resulting parse tree (if any) is returned in r15.


=head2 parseExpression(@parameters)

Create a parser for an expression described by variables

     Parameter    Description
  1  @parameters  Parameters describing expression

=head2 MatchBrackets(@parameters)

Replace the low three bytes of a utf32 bracket character with 24 bits of offset to the matching opening or closing bracket. Opening brackets have even codes from 0x10 to 0x4e while the corresponding closing bracket has a code one higher.

     Parameter    Description
  1  @parameters  Parameters

B<Example:>


    my $l = $Lex->{sampleLexicals}{brackets};

    Mov $start,  Rd(@$l);
    Mov $size,   scalar(@$l);

    parseExpressionCode;
    PrintOutStringNL "Result:";
    PrintOutRegisterInHex r15;

    printParseTree;

    ok Assemble(debug => 0, eq => <<END);
  Push Element:
     r13: 0000 0000 0000 0006
  New: accept initial variable
  New: accept initial variable
      r8: 0000 0000 0000 0006
     r13: 0000 0001 0000 0005
  accept a
  Push Element:
     r13: 0000 0001 0000 0005
     r13: 0000 0002 0000 0000
  accept b
  Push Element:
     r13: 0000 0002 0000 0000
     r13: 0000 0003 0000 0000
  accept b
  Push Element:
     r13: 0000 0003 0000 0000
     r13: 0000 0004 0000 0000
  accept b
  Push Element:
     r13: 0000 0004 0000 0000
     r13: 0000 0005 0000 0006
  accept v
  Push Element:
     r13: 0000 0005 0000 0006
  New: Variable
  New: Variable
      r8: 0000 0005 0000 0006
     r13: 0000 0006 0000 0001
  accept B
  Reduce 3:
      r8: 0000 0003 0000 0000
      r9: 0000 0004 0000 0000
     r10: 0000 0118 0000 0009
  Reduce 2:
      r8: 0000 0000 0000 0030
      r9: 0000 0004 0000 0000
  Push Element:
     r13: 0000 0006 0000 0001
  Reduce 3:
      r8: 0000 0004 0000 0000
      r9: 0000 0118 0000 0009
     r10: 0000 0006 0000 0001
  New: Bracketed term
  New: Bracketed term
      r8: 0000 0118 0000 0009
  New: Brackets for term
  New: Brackets for term
      r8: 0000 0198 0000 0009
      r8: 0000 0004 0000 0000
  Reduce by ( term )
  Reduce 3:
      r8: 0000 0002 0000 0000
      r9: 0000 0003 0000 0000
     r10: 0000 0218 0000 0009
  Reduce 2:
      r8: 0000 0000 0000 0028
      r9: 0000 0003 0000 0000
     r13: 0000 0007 0000 0001
  accept B
  Reduce 3:
      r8: 0000 0002 0000 0000
      r9: 0000 0003 0000 0000
     r10: 0000 0218 0000 0009
  Reduce 2:
      r8: 0000 0000 0000 0028
      r9: 0000 0003 0000 0000
  Push Element:
     r13: 0000 0007 0000 0001
  Reduce 3:
      r8: 0000 0003 0000 0000
      r9: 0000 0218 0000 0009
     r10: 0000 0007 0000 0001
  New: Bracketed term
  New: Bracketed term
      r8: 0000 0218 0000 0009
  New: Brackets for term
  New: Brackets for term
      r8: 0000 0298 0000 0009
      r8: 0000 0003 0000 0000
  Reduce by ( term )
  Reduce 3:
      r8: 0000 0001 0000 0005
      r9: 0000 0002 0000 0000
     r10: 0000 0318 0000 0009
  Reduce 2:
      r8: 0000 0000 0000 0020
      r9: 0000 0002 0000 0000
     r13: 0000 0008 0000 0003
  accept d
  Push Element:
     r13: 0000 0008 0000 0003
     r13: 0000 0009 0000 0000
  accept b
  Push Element:
     r13: 0000 0009 0000 0000
     r13: 0000 000A 0000 0006
  accept v
  Push Element:
     r13: 0000 000A 0000 0006
  New: Variable
  New: Variable
      r8: 0000 000A 0000 0006
     r13: 0000 000B 0000 0001
  accept B
  Reduce 3:
      r8: 0000 0008 0000 0003
      r9: 0000 0009 0000 0000
     r10: 0000 0398 0000 0009
  Reduce 2:
      r8: 0000 0000 0000 0038
      r9: 0000 0009 0000 0000
  Push Element:
     r13: 0000 000B 0000 0001
  Reduce 3:
      r8: 0000 0009 0000 0000
      r9: 0000 0398 0000 0009
     r10: 0000 000B 0000 0001
  New: Bracketed term
  New: Bracketed term
      r8: 0000 0398 0000 0009
  New: Brackets for term
  New: Brackets for term
      r8: 0000 0418 0000 0009
      r8: 0000 0009 0000 0000
  Reduce by ( term )
  Reduce 3:
      r8: 0000 0318 0000 0009
      r9: 0000 0008 0000 0003
     r10: 0000 0498 0000 0009
  New: Term infix term
  New: Term infix term
      r8: 0000 0498 0000 0009
      r8: 0000 0318 0000 0009
      r8: 0000 0008 0000 0003
  Reduce 3:
      r8: 0000 0001 0000 0005
      r9: 0000 0002 0000 0000
     r10: 0000 0518 0000 0009
  Reduce 2:
      r8: 0000 0000 0000 0020
      r9: 0000 0002 0000 0000
     r13: 0000 000C 0000 0001
  accept B
  Reduce 3:
      r8: 0000 0001 0000 0005
      r9: 0000 0002 0000 0000
     r10: 0000 0518 0000 0009
  Reduce 2:
      r8: 0000 0000 0000 0020
      r9: 0000 0002 0000 0000
  Push Element:
     r13: 0000 000C 0000 0001
  Reduce 3:
      r8: 0000 0002 0000 0000
      r9: 0000 0518 0000 0009
     r10: 0000 000C 0000 0001
  New: Bracketed term
  New: Bracketed term
      r8: 0000 0518 0000 0009
  New: Brackets for term
  New: Brackets for term
      r8: 0000 0598 0000 0009
      r8: 0000 0002 0000 0000
  Reduce by ( term )
  Reduce 3:
      r8: 0000 0098 0000 0009
      r9: 0000 0001 0000 0005
     r10: 0000 0618 0000 0009
  New: Term infix term
  New: Term infix term
      r8: 0000 0618 0000 0009
      r8: 0000 0098 0000 0009
      r8: 0000 0001 0000 0005
     r13: 0000 000D 0000 0008
  accept s
  Push Element:
     r13: 0000 000D 0000 0008
  Result:
     r15: 0000 0698 0000 0009
  Tree at:    r15: 0000 0000 0000 0698
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0003 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0618 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0004 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0005 data: 0000 0000 0000 0098 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0006 data: 0000 0000 0000 0005 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0007 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0098
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0006 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0000 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0618
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0002 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0598 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0004 data: 0000 0000 0000 0000 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0005 data: 0000 0000 0000 0002 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0598
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0518 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0518
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0003 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0498 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0004 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0005 data: 0000 0000 0000 0318 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0006 data: 0000 0000 0000 0003 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0007 data: 0000 0000 0000 0008 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0318
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0002 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0298 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0004 data: 0000 0000 0000 0000 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0005 data: 0000 0000 0000 0003 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0298
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0218 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0218
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0002 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0198 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0004 data: 0000 0000 0000 0000 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0005 data: 0000 0000 0000 0004 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0198
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0118 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0118
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0006 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0005 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0498
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0002 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0418 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0004 data: 0000 0000 0000 0000 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0005 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0418
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 0398 depth: 0000 0000 0000 0001
  Tree at:    r15: 0000 0000 0000 0398
  key: 0000 0000 0000 0000 data: 0000 0000 0000 0009 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0001 data: 0000 0000 0000 0001 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0002 data: 0000 0000 0000 0006 depth: 0000 0000 0000 0001
  key: 0000 0000 0000 0003 data: 0000 0000 0000 000A depth: 0000 0000 0000 0001
  END


=head2 ClassifyNewLines(@parameters)

Scan input string looking for opportunities to convert new lines into semi colons

     Parameter    Description
  1  @parameters  Parameters

=head2 ClassifyWhiteSpace(@parameters)

Classify white space per: "lib/Unisyn/whiteSpace/whiteSpaceClassification.pl"

     Parameter    Description
  1  @parameters  Parameters

=head2 T($key, $expected, $countComments)

Test a parse

     Parameter       Description
  1  $key            Key of text to be parsed
  2  $expected       Expected result
  3  $countComments  Optionally print most frequent comments to locate most generated code


=head1 Index


1 L<accept_a|/accept_a> - Assign

2 L<accept_B|/accept_B> - Closing parenthesis

3 L<accept_b|/accept_b> - Open

4 L<accept_d|/accept_d> - Infix but not assign or semi-colon

5 L<accept_p|/accept_p> - Prefix

6 L<accept_q|/accept_q> - Post fix

7 L<accept_s|/accept_s> - Semi colon

8 L<accept_v|/accept_v> - Variable

9 L<checkSet|/checkSet> - Check that one of a set of items is on the top of the stack or complain if it is not

10 L<checkStackHas|/checkStackHas> - Check that we have at least the specified number of elements on the stack

11 L<ClassifyNewLines|/ClassifyNewLines> - Scan input string looking for opportunities to convert new lines into semi colons

12 L<ClassifyWhiteSpace|/ClassifyWhiteSpace> - Classify white space per: "lib/Unisyn/whiteSpace/whiteSpaceClassification.

13 L<error|/error> - Die

14 L<getAlpha|/getAlpha> - Load the position of a lexical item in its alphabet from the current character

15 L<getLexicalCode|/getLexicalCode> - Load the lexical code of the current character in memory into the specified register.

16 L<lexicalNameFromLetter|/lexicalNameFromLetter> - Lexical name for a lexical item described by its letter

17 L<lexicalNumberFromLetter|/lexicalNumberFromLetter> - Lexical number for a lexical item described by its letter

18 L<loadCurrentChar|/loadCurrentChar> - Load the details of the character currently being processed so that we have the index of the character in the upper half of the current character and the lexical type of the character in the lowest byte

19 L<MatchBrackets|/MatchBrackets> - Replace the low three bytes of a utf32 bracket character with 24 bits of offset to the matching opening or closing bracket.

20 L<new|/new> - Create a new term

21 L<new2|/new2> - Create a new term in the parse tree rooted on the stack.

22 L<parseExpression|/parseExpression> - Create a parser for an expression described by variables

23 L<parseExpressionCode|/parseExpressionCode> - Parse the string of classified lexical items addressed by register $start of length $length.

24 L<parseUtf8|/parseUtf8> - Parse a unisyn expression encoded as utf8

25 L<printParseTree|/printParseTree> - Print the parse tree addressed  by r15

26 L<pushElement|/pushElement> - Push the current element on to the stack

27 L<pushEmpty|/pushEmpty> - Push the empty element on to the stack

28 L<putLexicalCode|/putLexicalCode> - Put the specified lexical code into the current character in memory.

29 L<reduce|/reduce> - Convert the longest possible expression on top of the stack into a term  at the specified priority

30 L<reduceMultiple|/reduceMultiple> - Reduce existing operators on the stack

31 L<T|/T> - Test a parse

32 L<testSet|/testSet> - Test a set of items, setting the Zero Flag is one matches else clear the Zero flag

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Unisyn::Parse

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

my $localTest = ((caller(1))[0]//'Unisyn::Parse') eq "Unisyn::Parse";           # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux|cygwin)i)                                                # Supported systems
 {if (confirmHasCommandLineCommand(q(nasm)) and LocateIntelEmulator)            # Network assembler and Intel Software Development emulator
   {plan tests => 99;
   }
  else
   {plan skip_all => qq(Nasm or Intel 64 emulator not available);
   }
 }
else
 {plan skip_all => qq(Not supported on: $^O);
 }

my $startTime = time;                                                           # Tests

   $debug     = 1;                                                              # Debug during testing so we can follow actions on the stack

eval {goto latest} if !caller(0) and -e "/home/phil";                           # Go to latest test if specified

makeDieConfess;

sub T($$;$)                                                                     #P Test a parse.
 {my ($key, $expected, $countComments) = @_;                                    # Key of text to be parsed, expected result, optionally print most frequent comments to locate most generated code
  my $source  = $$Lex{sampleText}{$key};                                        # String to be parsed in utf8
  defined $source or confess;
  my $address = Rutf8 $source;
  my $size    = StringLength V(string, $address);
  my $fail    = V('fail');
  my $parse   = V('parse');

  parseUtf8  V(address, $address),  $size, $fail, $parse;                       #TparseUtf8

  Assemble(debug => 0, eq => $expected);
 }

if (1) {                                                                        # Double words get expanded to quads
  my $q = Rb(1..8);
  Mov rax, "[$q];";
  Mov r8, rax;
  Shl r8d, 16;
  PrintOutRegisterInHex rax, r8;

  ok Assemble(debug => 0, eq => <<END);
   rax: 0807 0605 0403 0201
    r8: 0000 0000 0201 0000
END
 }

if (1) {                                                                        #TcheckStackHas
  my @o = (Rb(reverse 0x10,              0, 0, 1),                              # Open bracket
           Rb(reverse 0x11,              0, 0, 2),                              # Close bracket
           Rb(reverse $Ascii,            0, 0, 27),                             # Ascii 'a'
           Rb(reverse $variable,         0, 0, 27),                             # Variable 'a'
           Rb(reverse $NewLineSemiColon, 0, 0, 0),                              # New line semicolon
           Rb(reverse $semiColon,        0, 0, 0));                             # Semi colon

  for my $o(@o)                                                                 # Try converting each input element
   {Mov $start, $o;
    Mov $index, 0;
    loadCurrentChar;
    PrintOutRegisterInHex $element;
   }

  ok Assemble(debug => 0, eq => <<END);
   r13: 0000 0000 0000 0000
   r13: 0000 0000 0000 0001
   r13: 0000 0000 0000 0006
   r13: 0000 0000 0000 0006
   r13: 0000 0000 0000 0008
   r13: 0000 0000 0000 0008
END
 }

#latest:;
if (1) {                                                                        #TcheckStackHas
  PushR $parseStackBase;
  Mov   $parseStackBase, rsp;
  Push rax;
  Push rax;
  checkStackHas 2;
  IfEq Then {PrintOutStringNL "ok"},   Else {PrintOutStringNL "fail"}; checkStackHas 2;
  IfGe Then {PrintOutStringNL "ok"},   Else {PrintOutStringNL "fail"}; checkStackHas 2;
  IfGt Then {PrintOutStringNL "fail"}, Else {PrintOutStringNL "ok"};
  Push rax;                                                            checkStackHas 3;

  IfEq Then {PrintOutStringNL "ok"},   Else {PrintOutStringNL "fail"}; checkStackHas 3;
  IfGe Then {PrintOutStringNL "ok"},   Else {PrintOutStringNL "fail"}; checkStackHas 3;
  IfGt Then {PrintOutStringNL "fail"}, Else {PrintOutStringNL "ok"};
  ok Assemble(debug => 0, eq => <<END);
ok
ok
ok
ok
ok
ok
END
 }

#latest:;
if (1) {                                                                        #TpushEmpty
  Mov $index, 1;
  pushEmpty;
  Mov rax, "[rsp]";
  PrintOutRegisterInHex rax;
  ok Assemble(debug => 0, eq => <<END);
Push Empty
   rax: 0000 0001 0000 000A
END
 }

#latest:;
if (1) {                                                                        #TlexicalNameFromLetter #TlexicalNumberFromLetter
  is_deeply lexicalNameFromLetter('a'), q(assign);
  is_deeply lexicalNumberFromLetter('a'), $assign;
 }

#latest:;
if (1) {                                                                        #Tnew
  Mov $index,  1;
  Mov rax,-1; Push rax;
  Mov rax, 3; Push rax;
  Mov rax, 2; Push rax;
  Mov rax, 1; Push rax;
  new 3, 'test';
  Pop rax;  PrintOutRegisterInHex rax;
  Pop rax;  PrintOutRegisterInHex rax;
  ok Assemble(debug => 0, eq => <<END);
New: test
    r8: 0000 0000 0000 0001
    r8: 0000 0000 0000 0002
    r8: 0000 0000 0000 0003
   rax: 0000 0000 0000 0009
   rax: FFFF FFFF FFFF FFFF
END
 }

#latest:;
if (1) {                                                                        #Terror
  error "aaa bbbb";
  ok Assemble(debug => 0, eq => <<END);
Error: aaa bbbb
Element:    r13: 0000 0000 0000 0000
Index  :    r12: 0000 0000 0000 0000
END
 }

#latest:;
if (1) {                                                                        #TtestSet
  Mov r15,  -1;
  Mov r15b, $term;
  testSet("ast", r15);
  PrintOutZF;
  testSet("as",  r15);
  PrintOutZF;
  ok Assemble(debug => 0, eq => <<END);
ZF=1
ZF=0
END
 }

#latest:;
if (1) {                                                                        #TcheckSet
  Mov r15,  -1;
  Mov r15b, $term;
  Push r15;
  checkSet("ast");
  PrintOutZF;
  checkSet("as");
  PrintOutZF;
  ok Assemble(debug => 0, eq => <<END);
ZF=1
Error: Expected one of: 'as' on the stack
Element:    r13: 0000 0000 0000 0000
Index  :    r12: 0000 0000 0000 0000
END
 }

#latest:;
if (1) {                                                                        #Treduce
  Mov rsi, rsp;                                                                 # Create parse stack base
  Mov r15,    -1;   Push r15;
  Mov r15, $term;   Push r15;
  Mov r15, $assign; Push r15;
  Mov r15, $term;   Push r15;
  reduce 1;
  Pop r15; PrintOutRegisterInHex r15;
  Pop r14; PrintOutRegisterInHex r14;
  ok Assemble(debug => 0, eq => <<END);
Reduce 3:
    r8: 0000 0000 0000 0009
    r9: 0000 0000 0000 0005
   r10: 0000 0000 0000 0009
New: Term infix term
    r8: 0000 0000 0000 0009
    r8: 0000 0000 0000 0009
    r8: 0000 0000 0000 0005
   r15: 0000 0000 0000 0009
   r14: FFFF FFFF FFFF FFFF
END
 }

#latest:;
if (1) {                                                                        #TreduceMultiple
  Mov rsi, rsp;                                                                 # Create parse stack base
  Mov r15,           -1;  Push r15;
  Mov r15, $OpenBracket;  Push r15;
  reduceMultiple 1;
  Pop r15; PrintOutRegisterInHex r15;
  Pop r14; PrintOutRegisterInHex r14;
  ok Assemble(debug => 0, eq => <<END);
Reduce 2:
    r8: 0000 0000 0000 0010
    r9: 0000 0000 0000 0000
   r15: 0000 0000 0000 0000
   r14: FFFF FFFF FFFF FFFF
END
 }

#latest:;
if (1) {
  Mov rsi, rsp;                                                                 # Create parse stack base
  Mov r15,           -1;  Push r15;
  Mov r15, $OpenBracket;  Push r15;
  Mov r15, $term;         Push r15;
  Mov r15, $CloseBracket; Push r15;
  reduceMultiple 1;
  Pop r15; PrintOutRegisterInHex r15;
  Pop r14; PrintOutRegisterInHex r14;
  ok Assemble(debug => 0, eq => <<END);
Reduce 3:
    r8: 0000 0000 0000 0000
    r9: 0000 0000 0000 0009
   r10: 0000 0000 0000 0001
New: Bracketed term
    r8: 0000 0000 0000 0009
New: Brackets for term
    r8: 0000 0000 0000 0009
    r8: 0000 0000 0000 0000
Reduce by ( term )
Reduce 2:
    r8: 0000 0000 0000 0010
    r9: 0000 0000 0000 0009
   r15: 0000 0000 0000 0009
   r14: FFFF FFFF FFFF FFFF
END
 }

#latest:;
if (1) {
  Mov rsi, rsp;                                                                 # Create parse stack base
  Mov r15,      -1;  Push r15;
  Mov r15, $prefix;  Push r15;
  Mov r15, $prefix;  Push r15;
  Mov r15, $prefix;  Push r15;
  Mov $element, $variable;
  accept_v;
  Pop r15; PrintOutRegisterInHex r15;
  Pop r14; PrintOutRegisterInHex r14;
  ok Assemble(debug => 0, eq => <<END);
accept v
Push Element:
   r13: 0000 0000 0000 0006
New: Variable
    r8: 0000 0000 0000 0006
New: Prefixed variable
    r8: 0000 0000 0000 0009
    r8: 0000 0000 0000 0004
New: Prefixed variable
    r8: 0000 0000 0000 0009
    r8: 0000 0000 0000 0004
New: Prefixed variable
    r8: 0000 0000 0000 0009
    r8: 0000 0000 0000 0004
   r15: 0000 0000 0000 0009
   r14: FFFF FFFF FFFF FFFF
END
 }

sub printParseTree                                                              # Print the parse tree addressed  by r15.
 {my ($reg) = @_;                                                               # Parameters
  Mov r14, r15;
  Shr r14, 32;
  $tree->first->getReg(r14);
  $tree->dump;
# $tree->print;
 }

#latest:;
if (1) {
  Mov rsi, rsp;                                                                 # Create parse stack base
  my $l = $Lex->{sampleLexicals}{v};
  Mov $start,  Rd(@$l);
  Mov $size,   scalar(@$l);
  parseExpressionCode;
  PrintOutStringNL "Result:";
  PrintOutRegisterInHex r15;

  printParseTree;

  ok Assemble(debug => 0, eq => <<END);
Push Element:
   r13: 0000 0000 0000 0006
New: accept initial variable
New: accept initial variable
    r8: 0000 0000 0000 0006
Result:
   r15: 0000 0098 0000 0009
Tree at:  0000 0000 0000 0098  length: 0000 0000 0000 0004
 zmm31: 0000 00D8 0000 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0006   0000 0001 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0006
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0000

END
 }

#latest:;
if (1) {                                                                        #TprintParseTree
  Mov rsi, rsp;                                                                 # Create parse stack base
  my $l = $Lex->{sampleLexicals}{vav};
  Mov $start,  Rd(@$l);
  Mov $size,   scalar(@$l);

  parseExpressionCode;
  PrintOutStringNL "Result:";
  PrintOutRegisterInHex r15;

  Shr r15, 32;
  my $o = V(first, r15);
  $tree->dump($o);

  ok Assemble(debug => 0, eq => <<END);
Push Element:
   r13: 0000 0000 0000 0006
New: accept initial variable
New: accept initial variable
    r8: 0000 0000 0000 0006
   r13: 0000 0001 0000 0005
accept a
Push Element:
   r13: 0000 0001 0000 0005
   r13: 0000 0002 0000 0006
accept v
Push Element:
   r13: 0000 0002 0000 0006
New: Variable
New: Variable
    r8: 0000 0002 0000 0006
Reduce 3:
    r8: 0000 0098 0000 0009
    r9: 0000 0001 0000 0005
   r10: 0000 0118 0000 0009
New: Term infix term
New: Term infix term
    r8: 0000 0118 0000 0009
    r8: 0000 0098 0000 0009
    r8: 0000 0001 0000 0005
Result:
   r15: 0000 0198 0000 0009
Tree at:  0000 0000 0000 0198  length: 0000 0000 0000 0008
 zmm31: 0000 01D8 00A0 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0118 0000 0009   0000 0098 0000 0009   0000 0001 0000 0005   0000 0003 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0003
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0005
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0004   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0005   key: 0000 0000 0000 0005   data: 0000 0000 0000 0098 subTree
 index: 0000 0000 0000 0006   key: 0000 0000 0000 0006   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0007   key: 0000 0000 0000 0007   data: 0000 0000 0000 0118 subTree
Tree at:  0000 0000 0000 0098  length: 0000 0000 0000 0004
 zmm31: 0000 00D8 0000 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0006   0000 0001 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0006
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0000

Tree at:  0000 0000 0000 0118  length: 0000 0000 0000 0004
 zmm31: 0000 0158 0000 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0002 0000 0006   0000 0001 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0006
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0002


END
 }

#latest:;
if (1) {                                                                        #TMatchBrackets
  my $l = $Lex->{sampleLexicals}{brackets};

  Mov rsi, rsp;                                                                 # Create parse stack base
  Mov $start,  Rd(@$l);
  Mov $size,   scalar(@$l);

  parseExpressionCode;
  PrintOutStringNL "Result:";
  PrintOutRegisterInHex r15;

  printParseTree;

  ok Assemble(debug => 0, eq => <<END);
Push Element:
   r13: 0000 0000 0000 0006
New: accept initial variable
New: accept initial variable
    r8: 0000 0000 0000 0006
   r13: 0000 0001 0000 0005
accept a
Push Element:
   r13: 0000 0001 0000 0005
   r13: 0000 0002 0000 0000
accept b
Push Element:
   r13: 0000 0002 0000 0000
   r13: 0000 0003 0000 0000
accept b
Push Element:
   r13: 0000 0003 0000 0000
   r13: 0000 0004 0000 0000
accept b
Push Element:
   r13: 0000 0004 0000 0000
   r13: 0000 0005 0000 0006
accept v
Push Element:
   r13: 0000 0005 0000 0006
New: Variable
New: Variable
    r8: 0000 0005 0000 0006
   r13: 0000 0006 0000 0001
accept B
Reduce 3:
    r8: 0000 0003 0000 0000
    r9: 0000 0004 0000 0000
   r10: 0000 0118 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0030
    r9: 0000 0004 0000 0000
Push Element:
   r13: 0000 0006 0000 0001
Reduce 3:
    r8: 0000 0004 0000 0000
    r9: 0000 0118 0000 0009
   r10: 0000 0006 0000 0001
New: Bracketed term
New: Bracketed term
    r8: 0000 0118 0000 0009
New: Brackets for term
New: Brackets for term
    r8: 0000 0198 0000 0009
    r8: 0000 0004 0000 0000
Reduce by ( term )
Reduce 3:
    r8: 0000 0002 0000 0000
    r9: 0000 0003 0000 0000
   r10: 0000 0218 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0028
    r9: 0000 0003 0000 0000
   r13: 0000 0007 0000 0001
accept B
Reduce 3:
    r8: 0000 0002 0000 0000
    r9: 0000 0003 0000 0000
   r10: 0000 0218 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0028
    r9: 0000 0003 0000 0000
Push Element:
   r13: 0000 0007 0000 0001
Reduce 3:
    r8: 0000 0003 0000 0000
    r9: 0000 0218 0000 0009
   r10: 0000 0007 0000 0001
New: Bracketed term
New: Bracketed term
    r8: 0000 0218 0000 0009
New: Brackets for term
New: Brackets for term
    r8: 0000 0298 0000 0009
    r8: 0000 0003 0000 0000
Reduce by ( term )
Reduce 3:
    r8: 0000 0001 0000 0005
    r9: 0000 0002 0000 0000
   r10: 0000 0318 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0020
    r9: 0000 0002 0000 0000
   r13: 0000 0008 0000 0003
accept d
Push Element:
   r13: 0000 0008 0000 0003
   r13: 0000 0009 0000 0000
accept b
Push Element:
   r13: 0000 0009 0000 0000
   r13: 0000 000A 0000 0006
accept v
Push Element:
   r13: 0000 000A 0000 0006
New: Variable
New: Variable
    r8: 0000 000A 0000 0006
   r13: 0000 000B 0000 0001
accept B
Reduce 3:
    r8: 0000 0008 0000 0003
    r9: 0000 0009 0000 0000
   r10: 0000 0398 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0038
    r9: 0000 0009 0000 0000
Push Element:
   r13: 0000 000B 0000 0001
Reduce 3:
    r8: 0000 0009 0000 0000
    r9: 0000 0398 0000 0009
   r10: 0000 000B 0000 0001
New: Bracketed term
New: Bracketed term
    r8: 0000 0398 0000 0009
New: Brackets for term
New: Brackets for term
    r8: 0000 0418 0000 0009
    r8: 0000 0009 0000 0000
Reduce by ( term )
Reduce 3:
    r8: 0000 0318 0000 0009
    r9: 0000 0008 0000 0003
   r10: 0000 0498 0000 0009
New: Term infix term
New: Term infix term
    r8: 0000 0498 0000 0009
    r8: 0000 0318 0000 0009
    r8: 0000 0008 0000 0003
Reduce 3:
    r8: 0000 0001 0000 0005
    r9: 0000 0002 0000 0000
   r10: 0000 0518 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0020
    r9: 0000 0002 0000 0000
   r13: 0000 000C 0000 0001
accept B
Reduce 3:
    r8: 0000 0001 0000 0005
    r9: 0000 0002 0000 0000
   r10: 0000 0518 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0020
    r9: 0000 0002 0000 0000
Push Element:
   r13: 0000 000C 0000 0001
Reduce 3:
    r8: 0000 0002 0000 0000
    r9: 0000 0518 0000 0009
   r10: 0000 000C 0000 0001
New: Bracketed term
New: Bracketed term
    r8: 0000 0518 0000 0009
New: Brackets for term
New: Brackets for term
    r8: 0000 0598 0000 0009
    r8: 0000 0002 0000 0000
Reduce by ( term )
Reduce 3:
    r8: 0000 0098 0000 0009
    r9: 0000 0001 0000 0005
   r10: 0000 0618 0000 0009
New: Term infix term
New: Term infix term
    r8: 0000 0618 0000 0009
    r8: 0000 0098 0000 0009
    r8: 0000 0001 0000 0005
   r13: 0000 000D 0000 0008
accept s
Push Element:
   r13: 0000 000D 0000 0008
Result:
   r15: 0000 0698 0000 0009
Tree at:  0000 0000 0000 0698  length: 0000 0000 0000 0008
 zmm31: 0000 06D8 00A0 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0618 0000 0009   0000 0098 0000 0009   0000 0001 0000 0005   0000 0003 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0003
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0005
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0004   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0005   key: 0000 0000 0000 0005   data: 0000 0000 0000 0098 subTree
 index: 0000 0000 0000 0006   key: 0000 0000 0000 0006   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0007   key: 0000 0000 0000 0007   data: 0000 0000 0000 0618 subTree
Tree at:  0000 0000 0000 0098  length: 0000 0000 0000 0004
 zmm31: 0000 00D8 0000 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0006   0000 0001 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0006
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0000

Tree at:  0000 0000 0000 0618  length: 0000 0000 0000 0006
 zmm31: 0000 0658 0020 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0005 0000 0004   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0598 0000 0009   0000 0002 0000 0000   0000 0002 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0002
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0000
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0002
 index: 0000 0000 0000 0004   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0005   key: 0000 0000 0000 0005   data: 0000 0000 0000 0598 subTree
Tree at:  0000 0000 0000 0598  length: 0000 0000 0000 0004
 zmm31: 0000 05D8 0008 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0518 0000 0009   0000 0001 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0518 subTree
Tree at:  0000 0000 0000 0518  length: 0000 0000 0000 0008
 zmm31: 0000 0558 00A0 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0498 0000 0009   0000 0318 0000 0009   0000 0008 0000 0003   0000 0003 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0003
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0003
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0008
 index: 0000 0000 0000 0004   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0005   key: 0000 0000 0000 0005   data: 0000 0000 0000 0318 subTree
 index: 0000 0000 0000 0006   key: 0000 0000 0000 0006   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0007   key: 0000 0000 0000 0007   data: 0000 0000 0000 0498 subTree
Tree at:  0000 0000 0000 0318  length: 0000 0000 0000 0006
 zmm31: 0000 0358 0020 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0005 0000 0004   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0298 0000 0009   0000 0003 0000 0000   0000 0002 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0002
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0000
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0003
 index: 0000 0000 0000 0004   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0005   key: 0000 0000 0000 0005   data: 0000 0000 0000 0298 subTree
Tree at:  0000 0000 0000 0298  length: 0000 0000 0000 0004
 zmm31: 0000 02D8 0008 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0218 0000 0009   0000 0001 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0218 subTree
Tree at:  0000 0000 0000 0218  length: 0000 0000 0000 0006
 zmm31: 0000 0258 0020 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0005 0000 0004   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0198 0000 0009   0000 0004 0000 0000   0000 0002 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0002
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0000
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0004
 index: 0000 0000 0000 0004   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0005   key: 0000 0000 0000 0005   data: 0000 0000 0000 0198 subTree
Tree at:  0000 0000 0000 0198  length: 0000 0000 0000 0004
 zmm31: 0000 01D8 0008 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0118 0000 0009   0000 0001 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0118 subTree
Tree at:  0000 0000 0000 0118  length: 0000 0000 0000 0004
 zmm31: 0000 0158 0000 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0005 0000 0006   0000 0001 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0006
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0005





Tree at:  0000 0000 0000 0498  length: 0000 0000 0000 0006
 zmm31: 0000 04D8 0020 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0005 0000 0004   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0418 0000 0009   0000 0009 0000 0000   0000 0002 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0002
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0000
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0004   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0005   key: 0000 0000 0000 0005   data: 0000 0000 0000 0418 subTree
Tree at:  0000 0000 0000 0418  length: 0000 0000 0000 0004
 zmm31: 0000 0458 0008 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0398 0000 0009   0000 0001 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 0398 subTree
Tree at:  0000 0000 0000 0398  length: 0000 0000 0000 0004
 zmm31: 0000 03D8 0000 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0003 0000 0002   0000 0001 0000 0000
 zmm30: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 000A 0000 0006   0000 0001 0000 0009
 zmm29: 0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
 index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
 index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
 index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0000 0006
 index: 0000 0000 0000 0003   key: 0000 0000 0000 0003   data: 0000 0000 0000 000A







END
 }

#latest:
ok T(q(s1), <<END);
ParseUtf8
After conversion from utf8 to utf32
Output Length: 0000 0000 0000 0040
0001 D5EE 0001 D44E  0000 000A 0000 0020  0000 0020 0000 0041  0000 000A 0000 0020  0000 0020 0000 0020
After classification into alphabet ranges
0600 001A 0500 001A  0200 000A 0200 0020  0200 0020 0200 0041  0200 000A 0200 0020  0200 0020 0200 0020
After classification into brackets
0600 001A 0500 001A  0200 000A 0200 0020  0200 0020 0200 0041  0200 000A 0200 0020  0200 0020 0200 0020
After bracket matching
0600 001A 0500 001A  0200 000A 0200 0020  0200 0020 0200 0041  0200 000A 0200 0020  0200 0020 0200 0020
After white space classification
0600 001A 0500 001A  0B00 000A 0200 0020  0200 0020 0200 0041  0200 000A 0B00 0020  0B00 0020 0B00 0020
After classifying new lines
0600 001A 0500 001A  0B00 000A 0200 0020  0200 0020 0200 0041  0200 000A 0B00 0020  0B00 0020 0B00 0020
Push Element:
   r13: 0000 0000 0000 0006
New: accept initial variable
New: accept initial variable
    r8: 0000 0000 0000 0006
   r13: 0000 0001 0000 0005
accept a
Push Element:
   r13: 0000 0001 0000 0005
   r13: 0000 0002 0000 000B
   r13: 0000 0003 0000 0006
accept v
Push Element:
   r13: 0000 0003 0000 0006
New: Variable
New: Variable
    r8: 0000 0003 0000 0006
   r13: 0000 0004 0000 0006
   r13: 0000 0005 0000 0006
   r13: 0000 0006 0000 0006
   r13: 0000 0007 0000 000B
   r13: 0000 0008 0000 000B
   r13: 0000 0009 0000 000B
Reduce 3:
    r8: 0000 0098 0000 0009
    r9: 0000 0001 0000 0005
   r10: 0000 0118 0000 0009
New: Term infix term
New: Term infix term
    r8: 0000 0118 0000 0009
    r8: 0000 0098 0000 0009
    r8: 0000 0001 0000 0005
parse: 0000 0198 0000 0009
END

ok T(q(vnv), <<END);
ParseUtf8
After conversion from utf8 to utf32
Output Length: 0000 0000 0000 0024
0001 D5EE 0000 000A
After classification into alphabet ranges
0600 001A 0200 000A
After classification into brackets
0600 001A 0200 000A
After bracket matching
0600 001A 0200 000A
After white space classification
0600 001A 0B00 000A
After classifying new lines
0600 001A 0C00 000A
Push Element:
   r13: 0000 0000 0000 0006
New: accept initial variable
New: accept initial variable
    r8: 0000 0000 0000 0006
   r13: 0000 0001 0000 0008
accept s
Push Element:
   r13: 0000 0001 0000 0008
   r13: 0000 0002 0000 0006
accept v
Push Element:
   r13: 0000 0002 0000 0006
New: Variable
New: Variable
    r8: 0000 0002 0000 0006
Reduce 3:
    r8: 0000 0098 0000 0009
    r9: 0000 0001 0000 0008
   r10: 0000 0118 0000 0009
New: Term infix term
New: Term infix term
    r8: 0000 0118 0000 0009
    r8: 0000 0098 0000 0009
    r8: 0000 0001 0000 0008
parse: 0000 0198 0000 0009
END

#latest:
ok T(q(vnvs), <<END);
ParseUtf8
After conversion from utf8 to utf32
Output Length: 0000 0000 0000 0034
0001 D5EE 0000 000A  0001 D5EF 0000 0020  0000 0020 0000 0020
After classification into alphabet ranges
0600 001A 0200 000A  0600 001B 0200 0020  0200 0020 0200 0020
After classification into brackets
0600 001A 0200 000A  0600 001B 0200 0020  0200 0020 0200 0020
After bracket matching
0600 001A 0200 000A  0600 001B 0200 0020  0200 0020 0200 0020
After white space classification
0600 001A 0B00 000A  0600 001B 0B00 0020  0B00 0020 0B00 0020
After classifying new lines
0600 001A 0C00 000A  0600 001B 0B00 0020  0B00 0020 0B00 0020
Push Element:
   r13: 0000 0000 0000 0006
New: accept initial variable
New: accept initial variable
    r8: 0000 0000 0000 0006
   r13: 0000 0001 0000 0008
accept s
Push Element:
   r13: 0000 0001 0000 0008
   r13: 0000 0002 0000 0006
accept v
Push Element:
   r13: 0000 0002 0000 0006
New: Variable
New: Variable
    r8: 0000 0002 0000 0006
   r13: 0000 0003 0000 000B
   r13: 0000 0004 0000 000B
   r13: 0000 0005 0000 000B
   r13: 0000 0006 0000 000B
Reduce 3:
    r8: 0000 0098 0000 0009
    r9: 0000 0001 0000 0008
   r10: 0000 0118 0000 0009
New: Term infix term
New: Term infix term
    r8: 0000 0118 0000 0009
    r8: 0000 0098 0000 0009
    r8: 0000 0001 0000 0008
parse: 0000 0198 0000 0009
END

#latest:
ok T(q(vnsvs), <<END);
ParseUtf8
After conversion from utf8 to utf32
Output Length: 0000 0000 0000 005C
0001 D5EE 0001 D5EE  0000 000A 0000 0020  0000 0020 0000 0020  0001 D5EF 0001 D5EF  0000 0020 0000 0020
After classification into alphabet ranges
0600 001A 0600 001A  0200 000A 0200 0020  0200 0020 0200 0020  0600 001B 0600 001B  0200 0020 0200 0020
After classification into brackets
0600 001A 0600 001A  0200 000A 0200 0020  0200 0020 0200 0020  0600 001B 0600 001B  0200 0020 0200 0020
After bracket matching
0600 001A 0600 001A  0200 000A 0200 0020  0200 0020 0200 0020  0600 001B 0600 001B  0200 0020 0200 0020
After white space classification
0600 001A 0600 001A  0B00 000A 0B00 0020  0B00 0020 0B00 0020  0600 001B 0600 001B  0B00 0020 0B00 0020
After classifying new lines
0600 001A 0600 001A  0C00 000A 0B00 0020  0B00 0020 0B00 0020  0600 001B 0600 001B  0B00 0020 0B00 0020
Push Element:
   r13: 0000 0000 0000 0006
New: accept initial variable
New: accept initial variable
    r8: 0000 0000 0000 0006
   r13: 0000 0001 0000 0006
   r13: 0000 0002 0000 0008
accept s
Push Element:
   r13: 0000 0002 0000 0008
   r13: 0000 0003 0000 000B
   r13: 0000 0004 0000 000B
   r13: 0000 0005 0000 000B
   r13: 0000 0006 0000 0006
accept v
Push Element:
   r13: 0000 0006 0000 0006
New: Variable
New: Variable
    r8: 0000 0006 0000 0006
   r13: 0000 0007 0000 0006
   r13: 0000 0008 0000 000B
   r13: 0000 0009 0000 000B
   r13: 0000 000A 0000 000B
Reduce 3:
    r8: 0000 0098 0000 0009
    r9: 0000 0002 0000 0008
   r10: 0000 0118 0000 0009
New: Term infix term
New: Term infix term
    r8: 0000 0118 0000 0009
    r8: 0000 0098 0000 0009
    r8: 0000 0002 0000 0008
parse: 0000 0198 0000 0009
END

#latest:
ok T(q(brackets), <<END, 10);
ParseUtf8
After conversion from utf8 to utf32
Output Length: 0000 0000 0000 015C
0001 D5EE 0001 D44E  0001 D460 0001 D460  0001 D456 0001 D454  0001 D45B 0000 230A  0000 2329 0000 2768  0001 D5EF 0001 D5FD  0000 2769 0000 232A  0001 D429 0001 D425
0001 D42E 0001 D42C  0000 276A 0001 D600  0001 D5F0 0000 276B  0000 230B 0000 27E2
After classification into alphabet ranges
0600 001A 0500 001A  0500 002C 0500 002C  0500 0022 0500 0020  0500 0027 0000 230A  0000 2329 0000 2768  0600 001B 0600 0029  0000 2769 0000 232A  0300 0029 0300 0025
0300 002E 0300 002C  0000 276A 0600 002C  0600 001C 0000 276B  0000 230B 0800 0000
After classification into brackets
0600 001A 0500 001A  0500 002C 0500 002C  0500 0022 0500 0020  0500 0027 1200 230A  1400 2329 1600 2768  0600 001B 0600 0029  1700 2769 1500 232A  0300 0029 0300 0025
0300 002E 0300 002C  1800 276A 0600 002C  0600 001C 1900 276B  1300 230B 0800 0000
After bracket matching
0600 001A 0500 001A  0500 002C 0500 002C  0500 0022 0500 0020  0500 0027 1200 0016  1400 000D 1600 000C  0600 001B 0600 0029  1700 0009 1500 0008  0300 0029 0300 0025
0300 002E 0300 002C  1800 0015 0600 002C  0600 001C 1900 0012  1300 0007 0800 0000
After white space classification
0600 001A 0500 001A  0500 002C 0500 002C  0500 0022 0500 0020  0500 0027 1200 0016  1400 000D 1600 000C  0600 001B 0600 0029  1700 0009 1500 0008  0300 0029 0300 0025
0300 002E 0300 002C  1800 0015 0600 002C  0600 001C 1900 0012  1300 0007 0800 0000
After classifying new lines
0600 001A 0500 001A  0500 002C 0500 002C  0500 0022 0500 0020  0500 0027 1200 0016  1400 000D 1600 000C  0600 001B 0600 0029  1700 0009 1500 0008  0300 0029 0300 0025
0300 002E 0300 002C  1800 0015 0600 002C  0600 001C 1900 0012  1300 0007 0800 0000
Push Element:
   r13: 0000 0000 0000 0006
New: accept initial variable
New: accept initial variable
    r8: 0000 0000 0000 0006
   r13: 0000 0001 0000 0005
accept a
Push Element:
   r13: 0000 0001 0000 0005
   r13: 0000 0002 0000 0005
   r13: 0000 0003 0000 0005
   r13: 0000 0004 0000 0005
   r13: 0000 0005 0000 0005
   r13: 0000 0006 0000 0005
   r13: 0000 0007 0000 0000
accept b
Push Element:
   r13: 0000 0007 0000 0000
   r13: 0000 0008 0000 0000
accept b
Push Element:
   r13: 0000 0008 0000 0000
   r13: 0000 0009 0000 0000
accept b
Push Element:
   r13: 0000 0009 0000 0000
   r13: 0000 000A 0000 0006
accept v
Push Element:
   r13: 0000 000A 0000 0006
New: Variable
New: Variable
    r8: 0000 000A 0000 0006
   r13: 0000 000B 0000 0006
   r13: 0000 000C 0000 0001
accept B
Reduce 3:
    r8: 0000 0008 0000 0000
    r9: 0000 0009 0000 0000
   r10: 0000 0118 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0030
    r9: 0000 0009 0000 0000
Push Element:
   r13: 0000 000C 0000 0001
Reduce 3:
    r8: 0000 0009 0000 0000
    r9: 0000 0118 0000 0009
   r10: 0000 000C 0000 0001
New: Bracketed term
New: Bracketed term
    r8: 0000 0118 0000 0009
New: Brackets for term
New: Brackets for term
    r8: 0000 0198 0000 0009
    r8: 0000 0009 0000 0000
Reduce by ( term )
Reduce 3:
    r8: 0000 0007 0000 0000
    r9: 0000 0008 0000 0000
   r10: 0000 0218 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0028
    r9: 0000 0008 0000 0000
   r13: 0000 000D 0000 0001
accept B
Reduce 3:
    r8: 0000 0007 0000 0000
    r9: 0000 0008 0000 0000
   r10: 0000 0218 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0028
    r9: 0000 0008 0000 0000
Push Element:
   r13: 0000 000D 0000 0001
Reduce 3:
    r8: 0000 0008 0000 0000
    r9: 0000 0218 0000 0009
   r10: 0000 000D 0000 0001
New: Bracketed term
New: Bracketed term
    r8: 0000 0218 0000 0009
New: Brackets for term
New: Brackets for term
    r8: 0000 0298 0000 0009
    r8: 0000 0008 0000 0000
Reduce by ( term )
Reduce 3:
    r8: 0000 0001 0000 0005
    r9: 0000 0007 0000 0000
   r10: 0000 0318 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0020
    r9: 0000 0007 0000 0000
   r13: 0000 000E 0000 0003
accept d
Push Element:
   r13: 0000 000E 0000 0003
   r13: 0000 000F 0000 0003
   r13: 0000 0010 0000 0003
   r13: 0000 0011 0000 0003
   r13: 0000 0012 0000 0000
accept b
Push Element:
   r13: 0000 0012 0000 0000
   r13: 0000 0013 0000 0006
accept v
Push Element:
   r13: 0000 0013 0000 0006
New: Variable
New: Variable
    r8: 0000 0013 0000 0006
   r13: 0000 0014 0000 0006
   r13: 0000 0015 0000 0001
accept B
Reduce 3:
    r8: 0000 000E 0000 0003
    r9: 0000 0012 0000 0000
   r10: 0000 0398 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0038
    r9: 0000 0012 0000 0000
Push Element:
   r13: 0000 0015 0000 0001
Reduce 3:
    r8: 0000 0012 0000 0000
    r9: 0000 0398 0000 0009
   r10: 0000 0015 0000 0001
New: Bracketed term
New: Bracketed term
    r8: 0000 0398 0000 0009
New: Brackets for term
New: Brackets for term
    r8: 0000 0418 0000 0009
    r8: 0000 0012 0000 0000
Reduce by ( term )
Reduce 3:
    r8: 0000 0318 0000 0009
    r9: 0000 000E 0000 0003
   r10: 0000 0498 0000 0009
New: Term infix term
New: Term infix term
    r8: 0000 0498 0000 0009
    r8: 0000 0318 0000 0009
    r8: 0000 000E 0000 0003
Reduce 3:
    r8: 0000 0001 0000 0005
    r9: 0000 0007 0000 0000
   r10: 0000 0518 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0020
    r9: 0000 0007 0000 0000
   r13: 0000 0016 0000 0001
accept B
Reduce 3:
    r8: 0000 0001 0000 0005
    r9: 0000 0007 0000 0000
   r10: 0000 0518 0000 0009
Reduce 2:
    r8: 0000 0000 0000 0020
    r9: 0000 0007 0000 0000
Push Element:
   r13: 0000 0016 0000 0001
Reduce 3:
    r8: 0000 0007 0000 0000
    r9: 0000 0518 0000 0009
   r10: 0000 0016 0000 0001
New: Bracketed term
New: Bracketed term
    r8: 0000 0518 0000 0009
New: Brackets for term
New: Brackets for term
    r8: 0000 0598 0000 0009
    r8: 0000 0007 0000 0000
Reduce by ( term )
Reduce 3:
    r8: 0000 0098 0000 0009
    r9: 0000 0001 0000 0005
   r10: 0000 0618 0000 0009
New: Term infix term
New: Term infix term
    r8: 0000 0618 0000 0009
    r8: 0000 0098 0000 0009
    r8: 0000 0001 0000 0005
   r13: 0000 0017 0000 0008
accept s
Push Element:
   r13: 0000 0017 0000 0008
parse: 0000 0698 0000 0009
END

#latest:
ok T(q(brackets), <<END) if 0;
ParseUtf8
END

#latest:
ok T(q(brackets), <<END) if 0;
ParseUtf8
END

ok 1 for 23..99;

unlink $_ for qw(hash print2 sde-log.txt sde-ptr-check.out.txt z.txt);          # Remove incidental files

say STDERR sprintf("# Finished in %.2fs, bytes: %s, execs: %s ",  time - $startTime,
  map {numberWithCommas $_}
    $Nasm::X86::totalBytesAssembled, $Nasm::X86::instructionsExecuted);
