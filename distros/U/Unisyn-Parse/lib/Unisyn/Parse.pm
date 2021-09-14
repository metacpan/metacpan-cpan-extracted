#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/NasmX86/lib/ -I/home/phil/perl/cpan/AsmC/lib/
#-------------------------------------------------------------------------------
# Parse a Unisyn expression.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
# Finished in 13.14s, bytes: 2,655,008, execs: 465,858
# Can we remove more Pushr  by doing one big save in parseutf8 ?
# abcdefghijklmnopqrstuvwxyz
# 0123    456789ABCDEF
# Waiting on quarks
package Unisyn::Parse;
our $VERSION = "20210915";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all !parse);
use Nasm::X86 qw(:all);
use feature qw(say current_sub);
use utf8;

my  $develop    = -e q(/home/phil/);                                            # Developing
#our $arena;                                                                    # We always reload the actual arena address from rax and so this is permissible
our %parameters;                                                                # A copy of the parameter list parsed into the parser so that all the related subroutines can see it. The alternative would have been to code these subroutines as my subs but this makes it much harder to test them.  As parses are not interrupted by other parses reentrancy is not a problem.
our $Parse;                                                                     # The latest parse request
our $Quarks;                                                                    # The quarks associated with this parse
our $Operators;                                                                 # The subQuarks associated with this parse
our $debug      = 0;                                                            # Print evolution of stack if true.

#D1 Create                                                                      # Create a Unisyn parse of a utf8 string.

sub create($%)                                                                  # Create a new unisyn parse from a utf8 string.
 {my ($address, %options) = @_;                                                 # Address of a zero terminated utf8 source string to parse as a variable, parse options.
  @_ >= 1 or confess "One or more parameters";

  my $a    = CreateArena;                                                       # Arena to hold parse tree - every parse tree gets its own arena so that we can free parses separately
  my $size = StringLength string => $address;                                   # Length of input utf8

  my $p = $Parse   = genHash(__PACKAGE__,                                       # Description of parse
    arena          => $a,                                                       # Arena containing tree
    size8          => $size,                                                    # Size of source string as utf8
    address8       => $address,                                                 # Address of source string as utf8
    source32       => V(source32),                                              # Source text as utf32
    sourceSize32   => V(sourceSize32),                                          # Size of utf32 allocation
    sourceLength32 => V(sourceLength32),                                        # Length of utf32 string
    parse          => V('parse'),                                               # Offset to the head of the parse tree
    fails          => V('fail'),                                                # Number of failures encountered in this parse
    quarks         => $a->CreateQuarks,                                         # Quarks representing the strings used in this parse
    operators      => undef,                                                    # Methods implementing each lexical operator
   );

  if (my $o = $options{operators})                                              # Operator methods for lexical items
   {$p->operators = $a->CreateSubQuarks;                                        # Create quark set to translate operator names to offsets
    $o->($p);
   }

  $p->parseUtf8;                                                                # Parse utf8 source string

  $p
 }

#D1 Parse                                                                       # Parse Unisyn expressions

our $Lex = &lexicalData;                                                        # Lexical table definitions

our $ses              = RegisterSize rax;                                       # Size of an element on the stack
our ($w1, $w2, $w3)   = (r8, r9, r10);                                          # Work registers
our $prevChar         = r11;                                                    # The previous character parsed
our $index            = r12;                                                    # Index of current element
our $element          = r13;                                                    # Contains the item being parsed
our $start            = r14;                                                    # Start of the parse string
our $size             = r15;                                                    # Length of the input string
our $parseStackBase   = rsi;                                                    # The base of the parsing stack in the stack
#ur $arenaReg         = rax;                                                    # The arena in which we are building the parse tree
our $indexScale       = 4;                                                      # The size of a utf32 character
our $lexCodeOffset    = 3;                                                      # The offset in a classified character to the lexical code.
our $bitsPerByte      = 8;                                                      # The number of bits in a byte

our $Ascii            = $$Lex{lexicals}{Ascii}           {number};              # Ascii
our $assign           = $$Lex{lexicals}{assign}          {number};              # Assign
our $dyad             = $$Lex{lexicals}{dyad}            {number};              # Dyad
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
our $bracketsBase     = $$Lex{bracketsBase};                                    # Base lexical item for brackets

our $asciiNewLine     = ord("\n");                                              # New line in ascii
our $asciiSpace       = ord(' ');                                               # Space in ascii

our $lexItemType      = 0;                                                      # Field number of lexical item type in the description of a lexical item
our $lexItemOffset    = 1;                                                      # Field number of the offset in the utf32 source of the lexical item in the description of a lexical item or - if this a term - the offset of the invariant first block of the sub tree
our $lexItemLength    = 2;                                                      # Field number of the length of the lexical item in the utf32 source in the description of a lexical item
our $lexItemQuark     = 3;                                                      # Quark containing the text of this lexical item.
our $lexItemWidth     = 4;                                                      # The number of fields used to describe a lexical item  in the parse tree

our $opType           = 0;                                                      # Operator type field - currently always a term
our $opCount          = 1;                                                      # Number of operands for this operator
our $opSub            = 2;                                                      # Offset of sub associated with this lexical item

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
  Mov $register, $code;
  Mov "[$address+$indexScale*$index+$lexCodeOffset]", $register;                # Save lexical code
 }

sub loadCurrentChar()                                                           #P Load the details of the character currently being processed so that we have the index of the character in the upper half of the current character and the lexical type of the character in the lowest byte.
 {my $r = $element."b";                                                         # Classification byte

  Mov $element, $index;                                                         # Load index of character as upper dword
  Shl $element, $indexScale * $bitsPerByte;                                     # Save the index of the character in the upper half of the register so that we know where the character came from.
  getLexicalCode $r, $start, $index;                                            # Load lexical classification as lowest byte

  Cmp $r, $bracketsBase;                                                        # Brackets , due to their frequency, start after 0x10 with open even and close odd
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
   {PrintErrStringNL "Push Element:";
    PrintErrRegisterInHex $element;
   }
 }

sub pushEmpty()                                                                 #P Push the empty element on to the stack.
 {Mov  $w1, $index;
  Shl  $w1, $indexScale * $bitsPerByte;
  Or   $w1, $empty;
  Push $w1;
  if ($debug)
   {PrintErrStringNL "Push Empty";
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

sub lexicalItemLength($$)                                                       #P Put the length of a lexical item into variable B<size>.
 {my ($source32, $offset) = @_;                                                 # B<address> of utf32 source representation, B<offset> to lexical item in utf32

  my $s = Subroutine
   {my ($p, $s) = @_;                                                           # Parameters
#   PushR r14, r15;                                                             # We do not need to save the zmm and mask registers because they are only used as temporary work registers and they have been saved in L<parseUtf8>

    $$p{source32}->setReg(r14);
    $$p{offset}  ->setReg(r15);
    Vmovdqu8 zmm0, "[r14+4*r15]";                                               # Load source to examine
    Pextrw r15, xmm0, 1;                                                        # Extract lexical type of first element

    OrBlock                                                                     # The size of a bracket or a semi colon is always 1
     {my ($pass, $end, $start) = @_;
      Cmp r15, $OpenBracket;
      Je  $pass;
      Cmp r15, $CloseBracket;
      Je  $pass;
      Cmp r15, $semiColon;
      Je  $pass;

      Vpbroadcastw zmm1, r15w;                                                  # Broadcast lexical type
      Vpcmpeqw k0, zmm0, zmm1;                                                  # Check extent of first lexical item up to 16
      Mov r15, 0x55555555;                                                      # Set odd positions to one where we know the match will fail
      Kmovq k1, r15;
      Korq k2, k0, k1;                                                          # Fill in odd positions

      Kmovq r15, k2;
      Not r15;                                                                  # Swap zeroes and ones
      Tzcnt r15, r15;                                                           # Trailing zero count is a factor two too big
      Shr r15, 1;                                                               # Normalized count of number of characters in lexical item
      $$p{size}->getReg(r15);                                                   # Save size in supplied variable
     }
    Pass                                                                        # Show unitary length
     {my ($end, $pass, $start) = @_;
      $$p{size}->getConst(1);                                                   # Save size in supplied variable
     };

#   PopR;
   } [qw(offset source32 size)],
  name => q(Unisyn::Parse::lexicalItemLength);

  $s->call(offset => $offset, source32 => $source32, my $size = V(size));

  $size
 }

sub new($$)                                                                     #P Create a new term in the parse tree rooted on the stack.
 {my ($depth, $description) = @_;                                               # Stack depth to be converted, text reason why we are creating a new term
  Comment "New start";
  PrintErrStringNL "New: $description" if $debug;

  my $a = DescribeArena $parameters{bs};                                        # Create a tree in the arena to hold the details of the lexical elements on the stack
  my $t = $a->CreateTree;                                                       # Create a tree in the arena to hold the details of the lexical elements on the stack
  my $o = V(offset);                                                            # Offset into source for lexical item
  $t->insert(V(key, $opType),  V(data, $term));                                 # Create a term - we only have terms at the moment in the parse tree - but that might change in the future
  $t->insert(V(key, $opCount), V(data, $depth));                                # The number of elements in the term which is the number of operands for the operator

  my $liOnStack = $w1;                                                          # The lexical item as it appears on the stack
  my $liType    = $w2;                                                          # The lexical item type
  my $liOffset  = $w3;                                                          # The lexical item offset in the source

  for my $i(1..$depth)                                                          # Each term,
   {my $j = $depth + 1 - $i;
    Pop $liOnStack;                                                             # Unload stack
    PrintErrRegisterInHex $liOnStack if $debug;

    Mov $liOffset, $liOnStack;                                                  # Offset of either the text in the source or the offset of the first block of the tree describing a term
    Shr $liOffset, 32;                                                          # Offset in source: either the actual text of the offset of the first block of the tree containing a term shifted over to look as if it were an offset in the source
    $o->getReg($liOffset);                                                      # Offset of lexical item in source or offset of first block in tree describing a term

    ClearRegisters $liType;
    Mov $liType."b", $liOnStack."b";                                            # The lexical item type in the lowest byte, the rest clear.

    Cmp $liType, $term;                                                         # Check whether the lexical item on the stack is a term
    IfEq                                                                        # Insert a sub tree if we are inserting a term
    Then
     {$t->insertTree(V(key, $lexItemWidth * $j + $lexItemOffset), $o);          # Offset of first block in the tree representing the term
     },
    Else                                                                        # Insert the offset in the utf32 source if we are not on a term
     {$t->insert    (V(key, $lexItemWidth * $j + $lexItemOffset), $o);          # Offset in source of non term
     };

    Cmp $liType, $variable;                                                     # Check whether the lexical item is a variable which can also represent ascii
    IfEq                                                                        # Insert a sub tree if we are inserting a term
    Then
     {Mov $liType."b", "[$start+4*$liOffset+3]";                                # Load lexical type from source
     };

    Cmp $liType, $term;                                                         # Length of lexical item that is not a term
    IfNe
    Then                                                                        # Not a term
     {my $size = lexicalItemLength(V(address, $start), $o);                     # Get the size of the lexical item at the offset indicated on the stack
      $t->insert(V(key, $lexItemWidth * $j + $lexItemLength), $size);           # Save size of lexical item in parse tree

      my $s = CreateShortString(0);                                             # Short string to hold text of lexical item so we can load it into a quark
      PushR r15;
      r15 ne $start && r15 ne $liOffset or confess "r15 in use";
      Lea r15, "[$start+4*$liOffset]";                                          # Start address of lexical item
      my $start = V(address, r15);                                              # Save start address of lexical item
      PopR;
#     $s->loadDwordBytes(0, $start, $size);                                     # Load text of lexical item into short string
      $s->loadDwordBytes(0, $start, $size, 1);                                  # Load text of lexical item into short string
      Pinsrb "xmm0", $liType."b", 1;                                            # Set lexical type as the first byte of the short string

      my $q = $Quarks->quarkFromShortString($s);
      $t->insert(V(key, $lexItemWidth * $j + $lexItemQuark), $q);               # Save quark number of lexical item in parse tree

      if ($Operators)                                                           # The parse has operator definitions
       {if ($j == 1)                                                            # The operator quark is always first
         {my $N = $Operators->subFromQuark($Quarks, $q);                        # Look up the subroutine associated with this operator
          If $N >= 0,                                                           # Found a matching operator subroutine
          Then
           {$t->insert(V(key, $opSub), $N);                                     # Save offset to subroutine associated with this lexical item
           };
         }
       }
     };

    $t->insert  (V(key, $lexItemWidth * $j + $lexItemType),                     # Save lexical type in parse tree
                 V(data)->getReg($liType));
   }
                                                                                # Push new term onto the stack in place of the items popped off
  $t->first->setReg($liOffset);                                                 # Offset of new term tree
  Shl $liOffset, 32;                                                            # Push offset to term tree into the upper dword to make it look like a source offset
  Or  $liOffset."b", $term;                                                     # Mark as a term tree
  Push $liOffset;                                                               # Place new term on stack
  Comment "New end";
 }

sub error($)                                                                    #P Write an error message and stop.
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
     {PrintErrStringNL "Reduce 3:";
      PrintErrRegisterInHex $l, $d, $r;
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
          PrintErrStringNL "Reduce by ( term )" if $debug;
          Jmp $success;
         };
       };
     };
   };

  checkStackHas 2;                                                              # At least two elements on the stack
  IfGe                                                                          # Convert an empty pair of parentheses to an empty term
  Then
   {my ($l, $r) = ($w1, $w2);

    if ($debug)
     {PrintErrStringNL "Reduce 2:";
      PrintErrRegisterInHex $l, $r;
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
        PrintErrStringNL "Reduce by ;)" if $debug;
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
  PrintErrStringNL "accept a" if $debug;
  pushElement;
 }

sub accept_b                                                                    #P Open.
 {checkSet("abdps");
  PrintErrStringNL "accept b" if $debug;
  pushElement;
 }

sub accept_B                                                                    #P Closing parenthesis.
 {checkSet("bst");
  PrintErrStringNL "accept B" if $debug;
  reduceMultiple 1;
  pushElement;
  reduceMultiple 1;
  checkSet("bst");
 }

sub accept_d                                                                    #P Infix but not assign or semi-colon.
 {checkSet("t");
  PrintErrStringNL "accept d" if $debug;
  pushElement;
 }

sub accept_p                                                                    #P Prefix.
 {checkSet("abdps");
  PrintErrStringNL "accept p" if $debug;
  pushElement;
 }

sub accept_q                                                                    #P Post fix.
 {checkSet("t");
  PrintErrStringNL "accept q" if $debug;
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
  PrintErrStringNL "accept s" if $debug;
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
   PrintErrStringNL "accept v" if $debug;
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

sub parseExpression()                                                           #P Parse the string of classified lexical items addressed by register $start of length $length.  The resulting parse tree (if any) is returned in r15.
 {my $end = Label;
  my $eb  = $element."b";                                                       # Contains a byte from the item being parsed

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

    PrintErrRegisterInHex $element if $debug;

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
  Shr r15, 32;                                                                  # The offset of the resulting parse tree
  SetLabel $end;
 } # parseExpression

sub MatchBrackets(@)                                                            #P Replace the low three bytes of a utf32 bracket character with 24 bits of offset to the matching opening or closing bracket. Opening brackets have even codes from 0x10 to 0x4e while the corresponding closing bracket has a code one higher.
 {my (@parameters) = @_;                                                        # Parameters
  @_ >= 1 or confess "One or more parameters";

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
  @_ >= 1 or confess "One or more parameters";

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
  @_ >= 1 or confess "One or more parameters";

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

      AndBlock                                                                  # Trap space before new line and detect new line after ascii
       {my ($end, $start) = @_;
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

      AndBlock                                                                  # Spaces and new lines between other ascii
       {my ($end, $start) = @_;
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

      AndBlock                                                                  # Note: 's' preceding 'a' are significant
       {my ($end, $start) = @_;
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

      AndBlock                                                                  # Invert non significant white space
       {my ($end, $start) = @_;
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

      AndBlock                                                                  # Mark significant white space
       {my ($end, $start) = @_;
        Cmp $eb, $WhiteSpace; Jne $end;                                         # Not significant white space
        putLexicalCode $Ascii;                                                  # Mark as ascii
       };
     });

    PopR;
   } [qw(address size)],  name => q(Unisyn::Parse::ClassifyWhiteSpace);

  $s->call(@parameters);
 } # ClassifyWhiteSpace

sub parseUtf8($@)                                                               #P Parse a unisyn expression encoded as utf8 and return the parse tree.
 {my ($parse, @parameters) = @_;                                                # Parse, parameters
  @_ >= 1 or confess "One or more parameters";

  my $s = Subroutine
   {my ($p) = @_;                                                               # Parameters
    %parameters = %$p;                                                          # Make the parameters available in all the called parse subroutines.

    $Quarks =  $parse->quarks->reload(arena => $$p{bs},                         # Reload the quarks because the quarks used to create this subroutine might not be the same as the quarks that are reusing it now.
      array => $$p{numbersToStringsFirst},
      tree  => $$p{stringsToNumbersFirst});

    $Operators =  $parse->operators->reload(arena => $$p{bs},                   # Reload the subQuarks because the subQuarks used to create this subroutine might not be the same as the subQuarks that are reusing it now.
      array => $$p{opNumbersToStringsFirst},
      tree  => $$p{opStringsToNumbersFirst}) if $parse->operators;

    PrintErrStringNL "ParseUtf8" if $debug;

    PushR $parseStackBase, map {"r$_"} 8..15;
    PushZmm 0..1; PushMask 0..2;                                                # Used to hold arena and classifiers. Zmm0 is used to as a short string to quark the lexical item strings.

    my $source32       = $$p{source32};
    my $sourceSize32   = $$p{sourceSize32};
    my $sourceLength32 = $$p{sourceLength32};

    ConvertUtf8ToUtf32 u8 => $$p{address}, size8  => $$p{size},                 # Convert to utf32
                      u32 => $source32,    size32 => $sourceSize32,
                    count => $sourceLength32;

    my sub PrintUtf32($$)                                                       # Print a utf32 string in hexadecimal
     {my ($size, $address) = @_;                                                # Variable size, variable address
      $address->printErrMemoryInHexNL($size);
     }

    if ($debug)
     {PrintErrStringNL "After conversion from utf8 to utf32";
      $sourceSize32   ->errNL("Output Length: ");                               # Write output length
      PrintUtf32($sourceLength32, $source32);                                   # Print utf32
     }

    Vmovdqu8 zmm0, "[".Rd(join ', ', $Lex->{lexicalLow} ->@*)."]";              # Each double is [31::24] Classification, [21::0] Utf32 start character
    Vmovdqu8 zmm1, "[".Rd(join ', ', $Lex->{lexicalHigh}->@*)."]";              # Each double is [31::24] Range offset,   [21::0] Utf32 end character

    ClassifyWithInRangeAndSaveOffset address=>$source32, size=>$sourceLength32; # Alphabetic classification
    if ($debug)
     {PrintErrStringNL "After classification into alphabet ranges";
      PrintUtf32($sourceLength32, $source32);                                   # Print classified utf32
     }

    Vmovdqu8 zmm0, "[".Rd(join ', ', $Lex->{bracketsLow} ->@*)."]";             # Each double is [31::24] Classification, [21::0] Utf32 start character
    Vmovdqu8 zmm1, "[".Rd(join ', ', $Lex->{bracketsHigh}->@*)."]";             # Each double is [31::24] Range offset,   [21::0] Utf32 end character

    ClassifyWithInRange address=>$source32, size=>$sourceLength32;              # Bracket classification
    if ($debug)
     {PrintErrStringNL "After classification into brackets";
      PrintUtf32($sourceLength32, $source32);                                   # Print classified brackets
     }

    my $opens = V(opens, -1);
    MatchBrackets address=>$source32, size=>$sourceLength32, $opens, $$p{fail}; # Match brackets
    if ($debug)
     {PrintErrStringNL "After bracket matching";
      PrintUtf32($sourceLength32, $source32);                                   # Print matched brackets
     }

    ClassifyWhiteSpace address=>$source32, size=>$sourceLength32;               # Classify white space
    if ($debug)
     {PrintErrStringNL "After white space classification";
      PrintUtf32($sourceLength32, $source32);
     }

    ClassifyNewLines address=>$source32, size=>$sourceLength32;                 # Classify new lines
    if ($debug)
     {PrintErrStringNL "After classifying new lines";
      PrintUtf32($sourceLength32, $source32);
     }

    $$p{source32}      ->setReg($start);                                        # Start of expression string after it has been classified
    $$p{sourceLength32}->setReg($size);                                         # Number of characters in the expression
    Mov $parseStackBase, rsp;                                                   # Set base of parse stack

    parseExpression;                                                            # Parse the expression

    $$p{parse}->getReg(r15);                                                    # Number of characters in the expression
    Mov rsp, $parseStackBase;                                                   # Remove parse stack

    $$p{parse}->errNL if $debug;

    PopMask; PopZmm; PopR;

   }
  [qw(bs address size parse fail source32 sourceSize32 sourceLength32),
   qw(numbersToStringsFirst stringsToNumbersFirst),
   qw(opNumbersToStringsFirst opStringsToNumbersFirst)],
  name => q(Unisyn::Parse::parseUtf8);

  my $op = $parse->operators;                                                   # The operator methods if supplied
  my $zero = K(zero, 0);

  $s->call                                                                      # Parameterize the parse
   (bs                      => $parse->arena->bs,
    address                 => $parse->address8,
    fail                    => $parse->fails,
    parse                   => $parse->parse,
    size                    => $parse->size8,
    source32                => $parse->source32,
    sourceLength32          => $parse->sourceLength32,
    sourceSize32            => $parse->sourceSize32,
    numbersToStringsFirst   => $parse->quarks->numbersToStrings->first,
    stringsToNumbersFirst   => $parse->quarks->stringsToNumbers->first,
    opNumbersToStringsFirst => $op ? $op->subQuarks->numbersToStrings->first : $zero,
    opStringsToNumbersFirst => $op ? $op->subQuarks->stringsToNumbers->first : $zero,
   );
 } # parseUtf8

#D1 Traverse                                                                    # Traverse the parse tree

sub traverseTermsAndCall($)                                                     # Traverse the terms in parse tree in post order and call the operator subroutine associated with each term.
 {my ($parse) = @_;                                                             # Parse tree

  my $s = Subroutine                                                            # Print a tree
   {my ($p, $s) = @_;                                                           # Parameters, sub definition
    my $t = Nasm::X86::DescribeTree (arena=>$$p{bs}, first=>$$p{first});

    $t->find(K(key, $opType));                                                  # The lexical type of the element - normally a term

    If $t->found == 0,                                                          # Not found lexical type of element
    Then
     {PrintOutString "No type for node";
      Exit(1);
     };

    If $t->data != $term,                                                       # Expected a term
    Then
     {PrintOutString "Expected a term";
      Exit(1);
     };

    my $operands = V(operands);                                                 # Number of operands
    $t->find(K(key, 1));                                                        # Key 1 tells us the number of operands
    If $t->found > 0,                                                           # Found key 1
    Then
     {$operands->copy($t->data);                                                # Number of operands
     },
    Else
     {PrintOutString "Expected at least one operand";
      Exit(1);
     };

    $operands->for(sub                                                          # Each operand
     {my ($index, $start, $next, $end) = @_;                                    # Execute body
      my $i = (1 + $index) * $lexItemWidth;                                     # Operand detail
      $t->find($i+$lexItemType);   my $lex = V(key) ->copy($t->data);           # Lexical type
      $t->find($i+$lexItemOffset); my $off = V(key) ->copy($t->data);           # Offset of first block of sub tree

      If $lex == $term,                                                         # Term
      Then
       {$s->call($$p{bs}, first => $off);                                       # Traverse sub tree referenced by offset field
        $t->first  ->copy($$p{first});                                          # Re-establish addressability to the tree after the recursive call
       },
     });


    $t->find(K(key, $opSub));                                                   # The subroutine for the term
    If $t->found > 0,                                                           # Found subroutine for term
    Then                                                                        # Call subroutine for this term
     {PushR r15, zmm0;
      my $l = RegisterSize rax;
      $$p{bs}   ->putQIntoZmm(0, 0*$l, r15);
      $$p{first}->putQIntoZmm(0, 1*$l, r15);
      $t->data  ->setReg(r15);
      Cmp r15, 0;
      IfGt
      Then
       {Call r15;
       };
      PopR;
     },
    Else                                                                        # Missing subroutine for term
     {#PrintOutStringNL "No sub for term";
     };

   } [qw(bs first)], name => "Nasm::X86::Tree::traverseTermsAndCall";

  $s->call($parse->arena->bs, first => $parse->parse);

  $a
 } # traverseTermsAndCall

#D1 Print                                                                       # Print a parse tree

sub printLexicalItem($$$$)                                                      #P Print the utf8 string corresponding to a lexical item at a variable offset.
 {my ($parse, $source32, $offset, $size) = @_;                                  # Parse tree, B<address> of utf32 source representation, B<offset> to lexical item in utf32, B<size> in utf32 chars of item
  my $t = $parse->arena->DescribeTree;

  my $s = Subroutine
   {my ($p, $s) = @_;                                                           # Parameters
    PushR r12, r13, r14, r15;

    $$p{source32}->setReg(r14);
    $$p{offset}  ->setReg(r15);
    Lea r13, "[r14+4*r15]";                                                     # Address lexical item
    Mov eax, "[r13]";                                                           # First lexical item clearing rax
    Shr rax, 24;                                                                # First lexical item type in lowest byte and all else cleared

    my $success = Label;
    my $print   = Label;

    Cmp rax, $bracketsBase;                                                     # Test for brackets
    IfGe
    Then
     {my $o = $Lex->{bracketsOpen};                                             # Opening brackets
      my $c = $Lex->{bracketsClose};                                            # Closing brackets
      my $O = Rutf8 map {($_, chr(0))} @$o;                                     # Brackets in 3 bytes of utf8 each, with each bracket followed by a zero to make 4 bytes which is more easily addressed
      my $C = Rutf8 map {($_, chr(0))} @$c;                                     # Brackets in 3 bytes of utf8 each, with each bracket followed by a zero to make 4 bytes which is more easily addressed
      Mov r14, $O;                                                              # Address open bracket
      Mov r15, rax;                                                             # The bracket number
      Lea rax, "[r14+4*r15 - 4*$bracketsBase-4]";                               # Index to bracket
      PrintOutUtf8Char;                                                         # Print opening bracket
      Mov r14, $C;                                                              # Address close bracket
      Lea rax, "[r14+4*r15 - 4*$bracketsBase-4]";                               # Closing brackets occupy 3 bytes
      PrintOutUtf8Char;                                                         # Print closing bracket
      Jmp $success;
     };

    Mov r12, -1;                                                                # Alphabet to use
    Cmp rax, $variable;                                                         # Test for variable
    IfEq
    Then
     {my $b = $Lex->{alphabetsOrdered}{variable};                               # Load variable alphabet in dwords
      my @b = map {convertUtf32ToUtf8LE $_} @$b;
      my $a = Rd @b;
      Mov r12, $a;
      Jmp $print;
     };

    Cmp rax, $assign;                                                           # Test for assign operator
    IfEq
    Then
     {my $b = $Lex->{alphabetsOrdered}{assign};                                 # Load assign alphabet in dwords
      my @b = map {convertUtf32ToUtf8LE $_} @$b;
      my $a = Rd @b;
      Mov r12, $a;
      Jmp $print;
     };

    Cmp rax, $dyad;                                                             # Test for dyad
    IfEq
    Then
     {my $b = $Lex->{alphabetsOrdered}{dyad};                                   # Load dyad alphabet in dwords
      my @b = map {convertUtf32ToUtf8LE $_} @$b;
      my $a = Rd @b;
      Mov r12, $a;
      Jmp $print;
     };

    Cmp rax, $Ascii;                                                            # Test for ascii
    IfEq
    Then
     {my $b = $Lex->{alphabetsOrdered}{Ascii};                                  # Load ascii alphabet in dwords
      my @b = map {convertUtf32ToUtf8LE $_} @$b;
      my $a = Rd @b;
      Mov r12, $a;
      Jmp $print;
     };

    PrintErrTraceBack;                                                          # Unknown lexical type
    PrintErrStringNL "Alphabet not found for unexpected lexical item";
    PrintErrRegisterInHex rax;
    Exit(1);

    SetLabel $print;                                                            # Decoded

    $$p{size}->for(sub                                                          # Write each letter out from its position on the stack
     {my ($index, $start, $next, $end) = @_;                                    # Execute body
      $index->setReg(r14);                                                      # Index stack
      ClearRegisters r15;                                                       # Next instruction does not clear the entire register
      Mov r15b, "[r13+4*r14]";                                                  # Load alphabet offset from stack
      Shl r15, 2;                                                               # Each letter is 4 bytes wide in utf8
      Lea rax, "[r12+r15]";                                                     # Address alphabet letter as utf8
      PrintOutUtf8Char;                                                         # Print utf8 character
     });

    SetLabel $success;                                                          # Done

    PopR;
   } [qw(offset source32 size)],
  name => q(Unisyn::Parse::printLexicalItem);

  $s->call(offset => $offset, source32 => $source32, size => $size);
 }

sub print($)                                                                    # Print a parse tree.
 {my ($parse) = @_;                                                             # Parse tree
  my $t = $parse->arena->DescribeTree;

  PushR my ($depthR) = (r12);                                                   # Recursion depth

  my $b = Subroutine                                                            # Print the spacing blanks to offset sub trees
   {V(loop, $depthR)->for(sub
     {PrintOutString "  ";
     });
   } [], name => "Nasm::X86::Tree::dump::spaces";

  my $s = Subroutine                                                            # Print a tree
   {my ($p, $s) = @_;                                                           # Parameters, sub definition

    my $B = $$p{bs};

    $t->address->copy($$p{bs});
    $t->first  ->copy($$p{first});
    $t->find(K(key, 0));                                                        # Key 0 tells us the type of the element - normally a term

    If $t->found == 0,                                                          # Not found key 0
    Then
     {PrintOutString "No type for node";
      Exit(1);
     };

    If $t->data != $term,                                                       # Expected a term
    Then
     {PrintOutString "Expected a term";
      Exit(1);
     };

    my $operands = V(operands);                                                 # Number of operands
    $t->find(K(key, 1));                                                        # Key 1 tells us the number of operands
    If $t->found > 0,                                                           # Found key 1
    Then
     {$operands->copy($t->data);                                                # Number of operands
     },
    Else
     {PrintOutString "Expected at least one operand";
      Exit(1);
     };

    $operands->for(sub                                                          # Each operand
     {my ($index, $start, $next, $end) = @_;                                    # Execute body
      my $i = (1 + $index) * $lexItemWidth;                                     # Operand detail
      $t->find($i+$lexItemType);   my $lex = V(key) ->copy($t->data);           # Lexical type
      $t->find($i+$lexItemOffset); my $off = V(data)->copy($t->data);           # Offset in source
      $t->find($i+$lexItemLength); my $len = V(data)->copy($t->data);           # Length in source

      $b->call;                                                                 # Indent

      If $lex == $term,                                                         # Term
      Then
       {PrintOutStringNL "Term";
        Inc $depthR;                                                            # Increase indentation for sub terms
        $s->call($B, first => $off, $$p{source32});                             # Print sub tree referenced by offset field
        Dec $depthR;                                                            # Restore existing indentation
        $t->first  ->copy($$p{first});                                          # Re-establish addressability to the tree after the recursive call
       },

      Ef {$lex == $semiColon}                                                   # Semicolon
      Then
       {PrintOutStringNL "Semicolon";
       },

      Else
       {If $lex == $variable,                                                   # Variable
        Then
         {PrintOutString "Variable: ";
         },

        Ef {$lex == $assign}                                                    # Assign
        Then
         {PrintOutString "Assign: ";
         },

        Ef {$lex == $OpenBracket}                                               # Open brackets
        Then
         {PrintOutString "Brackets: ";
         },

        Ef {$lex == $dyad}                                                      # Dyad
        Then
         {PrintOutString "Dyad: ";
         },

        Ef {$lex == $Ascii}                                                     # Ascii
        Then
         {PrintOutString "Ascii: ";
         },

        Else                                                                    # Unexpected lexical type
         {PrintErrStringNL "Unexpected lexical type:";
          $lex->d;
          PrintErrTraceBack;
          Exit(1);
         };

        $parse->printLexicalItem($$p{source32}, $off, $len);                    # Print the variable name
        PrintOutNL;
      };

      If $index == 0,                                                           # Operator followed by indented operands
      Then
       {Inc $depthR;
       };
     });

    Dec $depthR;                                                                # Reset indentation after operands
   } [qw(bs first source32)], name => "Nasm::X86::Tree::print";

  ClearRegisters $depthR;                                                       # Depth starts at zero

  $s->call($parse->arena->bs, first => $parse->parse, $parse->source32);

  PopR;
 } # print

#D1 SubQuark                                                                    # A set of quarks describing the method to be called for each lexical operator.  These routines specialize the general purpose quark methods for use on parse methods.

sub Nasm::X86::Arena::DescribeSubQuarks($)                                      # Return a descriptor for a subQuarks in the specified arena.
 {my ($arena) = @_;                                                             # Arena descriptor

  genHash(__PACKAGE__."::SubQuarks",                                            # Sub quarks
    subQuarks => undef,                                                         # The quarks used to map a subroutine name to an offset
   );
 }

sub Nasm::X86::Arena::CreateSubQuarks($)                                        # Create quarks in a specified arena.
 {my ($arena) = @_;                                                             # Arena description optional arena address
  @_ == 1 or confess "One parameter";

  my $q = $arena->DescribeSubQuarks;                                            # Return a descriptor for a tree at the specified offset in the specified arena
  $q->subQuarks = $arena->CreateQuarks;
  $q                                                                            # Description of array
 }

sub Unisyn::Parse::SubQuarks::reload($%)                                        # Reload the description of a set of sub quarks.
 {my ($q, %options) = @_;                                                       # Subquarks, {arena=>arena to use; tree => first tree block; array => first array block}
  @_ >= 1 or confess "One or more parameters";

  $q->subQuarks(%options);
  $q                                                                            # Return upgraded quarks descriptor
 }

sub Unisyn::Parse::SubQuarks::put($$$)                                          # Put a new subroutine definition into the sub quarks.
 {my ($q, $string, $sub) = @_;                                                  # Subquarks, string containing operator type and method name, variable offset to subroutine
  @_ == 3 or confess "3 parameters";
  ref($sub) && ref($sub) =~ m(Nasm::X86::Sub) or
    confess "Subroutine definition required";

  PushR zmm0;
  my $s = CreateShortString(0)->loadConstantString($string);                    # Load the operator name in its alphabet with the alphabet number on the first byte
  my $N = $q->subQuarks->quarkFromSub($sub, $s);                                # Create quark from sub
  PopR;
  $N                                                                            # Created quark number for subroutine
 }

sub Unisyn::Parse::SubQuarks::subFromQuark($$$)                                 # Given the quark number for a lexical item and the quark set of lexical items get the offset of the associated method.
 {my ($q, $lexicals, $number) = @_;                                             # Sub quarks, lexical item quarks, lexical item quark
  @_ == 3 or confess "3 parameters";

  ref($lexicals) && ref($lexicals) =~ m(Nasm::X86::Quarks) or                   # Check that we have been given a quark set as expected
    confess "Quarks expected";

  my $Q = $lexicals->quarkToQuark($number, $q->subQuarks);                      # Either the offset to the specified method or -1.
  my $r = V('sub', -1);                                                         # Matching routine not found
  If $Q >= 0,                                                                   # Quark found
   Then
    {$q->subQuarks->numbersToStrings->get(index=>$Q, element=>$r);              # Load subroutine offset
    };
  $r                                                                            # Return sub routine offset
 }

sub Unisyn::Parse::SubQuarks::lexToString($$$)                                  # Convert a lexical item to a string.
 {my ($q, $alphabet, $op) = @_;                                                 # Sub quarks, the alphabet number, the operator name in that alphabet
  my $a = &lexicalData->{alphabetsOrdered}{$alphabet};                          # Alphabet
  my $n = $$Lex{lexicals}{$alphabet}{number};                                   # Number of lexical type
  my %i = map {$$a[$_]=>$_} keys @$a;
  my @b = ($n, map {$i{ord $_}} split //, $op);                                 # Bytes representing the operator name
  join '', map {chr $_} @b                                                      # String representation
 }

sub Unisyn::Parse::SubQuarks::dyad($$$)                                         # Define a method for a dyadic operator.
 {my ($q, $text, $sub) = @_;                                                    # Sub quarks, sub quarks, the name of the operator as a utf8 string, variable associated subroutine offset
  my $s = $q->lexToString("dyad", $text);                                       # Operator name in operator alphabet preceded by alphabet number
  $q->put($s, $sub);                                                            # Add the named dyad to the sub quarks
 }

sub Unisyn::Parse::SubQuarks::assign($$$)                                       # Define a method for an assign operator.
 {my ($q, $text, $sub) = @_;                                                    # Sub quarks, the name of the operator as a utf8 string, variable associated subroutine offset
  my $s = $q->lexToString("assign", $text);                                     # Operator name in operator alphabet preceded by alphabet number
  $q->put($s, $sub);                                                            # Add the named dyad to the sub quarks
 }

sub assignToShortString($$)                                                     # Create a short string representing a dyad and put it in the specified short string.
 {my ($short, $text) = @_;                                                      # The number of the short string, the text of the operator in the assign alphabet
  lexToShortString($short, "assign", $text);
 }

#D1 Alphabets                                                                   # Translate between alphabets

sub showAlphabet($)                                                             #P Show an alphabet.
 {my ($alphabet) = @_;                                                          # Alphabet name
  my $out;
  my $lex = &lexicalData;
  my $abc = $lex->{alphabetsOrdered}{$alphabet};
  for my $a(@$abc)
   {$out .= chr($a);
   }
  $out
 }

sub asciiToAssignLatin($)                                                       # Translate ascii to the corresponding letters in the assign latin alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz/𝐴𝐵𝐶𝐷𝐸𝐹𝐺𝐻𝐼𝐽𝐾𝐿𝑀𝑁𝑂𝑃𝑄𝑅𝑆𝑇𝑈𝑉𝑊𝑋𝑌𝑍𝑎𝑏𝑐𝑑𝑒𝑓𝑔ℎ𝑖𝑗𝑘𝑙𝑚𝑛𝑜𝑝𝑞𝑟𝑠𝑡𝑢𝑣𝑤𝑥𝑦𝑧/r;
 }

sub asciiToAssignGreek($)                                                       # Translate ascii to the corresponding letters in the assign greek alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/ABGDEZNHIKLMVXOPRQSTUFCYWabgdeznhiklmvxoprqstufcyw/𝛢𝛣𝛤𝛥𝛦𝛧𝛨𝛩𝛪𝛫𝛬𝛭𝛮𝛯𝛰𝛱𝛲𝛳𝛴𝛵𝛶𝛷𝛸𝛹𝛺𝛼𝛽𝛾𝛿𝜀𝜁𝜂𝜃𝜄𝜅𝜆𝜇𝜈𝜉𝜊𝜋𝜌𝜍𝜎𝜏𝜐𝜑𝜒𝜓𝜔/r;
 }

sub asciiToDyadLatin($)                                                         # Translate ascii to the corresponding letters in the dyad latin alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz/𝐀𝐁𝐂𝐃𝐄𝐅𝐆𝐇𝐈𝐉𝐊𝐋𝐌𝐍𝐎𝐏𝐐𝐑𝐒𝐓𝐔𝐕𝐖𝐗𝐘𝐙𝐚𝐛𝐜𝐝𝐞𝐟𝐠𝐡𝐢𝐣𝐤𝐥𝐦𝐧𝐨𝐩𝐪𝐫𝐬𝐭𝐮𝐯𝐰𝐱𝐲𝐳/r;
 }

sub asciiToDyadGreek($)                                                         # Translate ascii to the corresponding letters in the dyad greek alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/ABGDEZNHIKLMVXOPRQSTUFCYWabgdeznhiklmvxoprqstufcyw/𝚨𝚩𝚪𝚫𝚬𝚭𝚮𝚯𝚰𝚱𝚲𝚳𝚴𝚵𝚶𝚷𝚸𝚹𝚺𝚻𝚼𝚽𝚾𝚿𝛀𝛂𝛃𝛄𝛅𝛆𝛇𝛈𝛉𝛊𝛋𝛌𝛍𝛎𝛏𝛐𝛑𝛒𝛓𝛔𝛕𝛖𝛗𝛘𝛙𝛚/r;
 }

sub asciiToPrefixLatin($)                                                       # Translate ascii to the corresponding letters in the prefix latin alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz/𝑨𝑩𝑪𝑫𝑬𝑭𝑮𝑯𝑰𝑱𝑲𝑳𝑴𝑵𝑶𝑷𝑸𝑹𝑺𝑻𝑼𝑽𝑾𝑿𝒀𝒁𝒂𝒃𝒄𝒅𝒆𝒇𝒈𝒉𝒊𝒋𝒌𝒍𝒎𝒏𝒐𝒑𝒒𝒓𝒔𝒕𝒖𝒗𝒘𝒙𝒚𝒛/r;
 }

sub asciiToPrefixGreek($)                                                       # Translate ascii to the corresponding letters in the prefix greek alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/ABGDEZNHIKLMVXOPRQSTUFCYWabgdeznhiklmvxoprqstufcyw/𝜜𝜝𝜞𝜟𝜠𝜡𝜢𝜣𝜤𝜥𝜦𝜧𝜨𝜩𝜪𝜫𝜬𝜭𝜮𝜯𝜰𝜱𝜲𝜳𝜴𝜶𝜷𝜸𝜹𝜺𝜻𝜼𝜽𝜾𝜿𝝀𝝁𝝂𝝃𝝄𝝅𝝆𝝇𝝈𝝉𝝊𝝋𝝌𝝍𝝎/r;
 }

sub asciiToSuffixLatin($)                                                       # Translate ascii to the corresponding letters in the suffix latin alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz/𝘼𝘽𝘾𝘿𝙀𝙁𝙂𝙃𝙄𝙅𝙆𝙇𝙈𝙉𝙊𝙋𝙌𝙍𝙎𝙏𝙐𝙑𝙒𝙓𝙔𝙕𝙖𝙗𝙘𝙙𝙚𝙛𝙜𝙝𝙞𝙟𝙠𝙡𝙢𝙣𝙤𝙥𝙦𝙧𝙨𝙩𝙪𝙫𝙬𝙭𝙮𝙯/r;
 }

sub asciiToSuffixGreek($)                                                       # Translate ascii to the corresponding letters in the suffix greek alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/ABGDEZNHIKLMVXOPRQSTUFCYWabgdeznhiklmvxoprqstufcyw/𝞐𝞑𝞒𝞓𝞔𝞕𝞖𝞗𝞘𝞙𝞚𝞛𝞜𝞝𝞞𝞟𝞠𝞡𝞢𝞣𝞤𝞥𝞦𝞧𝞨𝞪𝞫𝞬𝞭𝞮𝞯𝞰𝞱𝞲𝞳𝞴𝞵𝞶𝞷𝞸𝞹𝞺𝞻𝞼𝞽𝞾𝞿𝟀𝟁𝟂/r;
 }

sub asciiToVariableLatin($)                                                     # Translate ascii to the corresponding letters in the suffix latin alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz/𝗔𝗕𝗖𝗗𝗘𝗙𝗚𝗛𝗜𝗝𝗞𝗟𝗠𝗡𝗢𝗣𝗤𝗥𝗦𝗧𝗨𝗩𝗪𝗫𝗬𝗭𝗮𝗯𝗰𝗱𝗲𝗳𝗴𝗵𝗶𝗷𝗸𝗹𝗺𝗻𝗼𝗽𝗾𝗿𝘀𝘁𝘂𝘃𝘄𝘅𝘆𝘇/r;
 }

sub asciiToVariableGreek($)                                                     # Translate ascii to the corresponding letters in the suffix greek alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/ABGDEZNHIKLMVXOPRQSTUFCYWabgdeznhiklmvxoprqstufcyw/𝝖𝝗𝝘𝝙𝝚𝝛𝝜𝝝𝝞𝝟𝝠𝝡𝝢𝝣𝝤𝝥𝝦𝝧𝝨𝝩𝝪𝝫𝝬𝝭𝝮𝝰𝝱𝝲𝝳𝝴𝝵𝝶𝝷𝝸𝝹𝝺𝝻𝝼𝝽𝝾𝝿𝞀𝞁𝞂𝞃𝞄𝞅𝞆𝞇𝞈/r;
 }

sub asciiToEscaped($)                                                           # Translate ascii to the corresponding letters in the escaped ascii alphabet.
 {my ($in) = @_;                                                                # A string of ascii
  $in =~ tr/abcdefghijklmnopqrstuvwxyz/🅐🅑🅒🅓🅔🅕🅖🅗🅘🅙🅚🅛🅜🅝🅞🅟🅠🅡🅢🅣🅤🅥🅦🅧🅨🅩/r;
 }

sub semiColon()                                                                 # Translate ascii to the corresponding letters in the escaped ascii alphabet.
 {chr(10210)
 }

#d
sub lexicalData {do {
  my $a = bless({
    alphabetRanges   => 14,
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
                          "planck"                           => "\x{210E}",
                          "semiColon"                        => "\x{27E2}",
                          "squaredLatinLetter"               => "\x{1F130}\x{1F131}\x{1F132}\x{1F133}\x{1F134}\x{1F135}\x{1F136}\x{1F137}\x{1F138}\x{1F139}\x{1F13A}\x{1F13B}\x{1F13C}\x{1F13D}\x{1F13E}\x{1F13F}\x{1F140}\x{1F141}\x{1F142}\x{1F143}\x{1F144}\x{1F145}\x{1F146}\x{1F147}\x{1F148}\x{1F149}\x{1F1A5}",
                        },
    alphabetsOrdered => {
                          Ascii     => [0 .. 127, 127312 .. 127337],
                          assign    => [8462, 119860 .. 119911, 120546 .. 120603],
                          dyad      => [119808 .. 119859, 120488 .. 120545],
                          prefix    => [119912 .. 119963, 120604 .. 120661],
                          semiColon => [10210],
                          suffix    => [120380 .. 120431, 120720 .. 120777],
                          variable  => [120276 .. 120327, 120662 .. 120719],
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
                          "assign"       => ["mathematicalItalic", "planck"],
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
                          8462,
                          10210,
                          119859,
                          16897127,
                          119963,
                          120327,
                          120431,
                          872535777,
                          889313051,
                          872535893,
                          872535951,
                          872536009,
                          2147610985,
                          0,
                          0,
                        ],
    lexicalLow       => [
                          33554432,
                          83894542,
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
                          A => [
                            100663296,
                            83886080,
                            33554497,
                            33554464,
                            33554497,
                            33554464,
                            33554464,
                            33554464,
                            33554464,
                          ],
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
                          bvB => [0, 100663296, 16777216],
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
                          s => [100663296, 134217728, 100663296],
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
                          vavav => [100663296, 83886080, 100663296, 83886080, 100663296],
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
                            0,
                            100663296,
                            50331648,
                            100663296,
                            16777216,
                            134217728,
                          ],
                          wsa => [
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
                          A => "\x{1D5EE}\x{1D5EE}\x{1D452}\x{1D45E}\x{1D462}\x{1D44E}\x{1D459}\x{1D460}abc 123    ",
                          brackets => "\x{1D5EE}\x{1D44E}\x{1D460}\x{1D460}\x{1D456}\x{1D454}\x{1D45B}\x{230A}\x{2329}\x{2768}\x{1D5EF}\x{1D5FD}\x{2769}\x{232A}\x{1D429}\x{1D425}\x{1D42E}\x{1D42C}\x{276A}\x{1D600}\x{1D5F0}\x{276B}\x{230B}\x{27E2}",
                          bvB => "\x{2329}\x{1D5EE}\x{1D5EF}\x{1D5F0}\x{232A}",
                          nosemi => "\x{1D5EE}\x{1D44E}\x{1D460}\x{1D460}\x{1D456}\x{1D454}\x{1D45B}\x{230A}\x{2329}\x{2768}\x{1D5EF}\x{1D5FD}\x{2769}\x{232A}\x{1D429}\x{1D425}\x{1D42E}\x{1D42C}\x{276A}\x{1D600}\x{1D5F0}\x{276B}\x{230B}",
                          s => "\x{1D5EE}\x{27E2}\x{1D5EF}",
                          s1 => "\x{1D5EE}\x{1D44E}\n  \n   ",
                          v => "\x{1D5EE}",
                          vav => "\x{1D5EE}\x{1D44E}\x{1D5EF}",
                          vavav => "\x{1D5EE}\x{1D44E}\x{1D5EF}\x{1D44E}\x{1D5F0}",
                          vnsvs => "\x{1D5EE}\x{1D5EE}\n   \x{1D5EF}\x{1D5EF}   ",
                          vnv => "\x{1D5EE}\n\x{1D5EF}",
                          vnvs => "\x{1D5EE}\n\x{1D5EF}    ",
                          ws => "\x{1D5EE}\x{1D44E}\x{1D460}\x{1D460}\x{1D456}\x{1D454}\x{1D45B}\x{230A}\x{2329}\x{2768}\x{1D5EF}\x{1D5FD}\x{2769}\x{232A}\x{1D429}\x{1D425}\x{1D42E}\x{1D42C}\x{276A}\x{1D600}\x{1D5F0}\x{276B}\x{230B}\x{27E2}\x{1D5EE}\x{1D5EE}\x{1D44E}\x{1D460}\x{1D460}\x{1D456}\x{1D454}\x{1D45B}\x{276C}\x{1D5EF}\x{1D5EF}\x{1D429}\x{1D425}\x{1D42E}\x{1D42C}\x{1D5F0}\x{1D5F0}\x{276D}\x{27E2}",
                          wsa => "\x{1D5EE}\x{1D44E}\x{1D460}\x{1D460}\x{1D456}\x{1D454}\x{1D45B}\x{230A}\x{2329}\x{2768}\x{1D5EF}\x{1D5FD}\x{2769}\x{232A}\x{1D429}\x{1D425}\x{1D42E}\x{1D42C}\x{276A}\x{1D600}\x{1D5F0}\x{276B}\x{230B}\x{27E2}\x{1D5EE}\x{1D5EE}\x{1D44E}\x{1D460}\x{1D460}\x{1D456}\x{1D454}\x{1D45B}some--ascii--text\x{1D429}\x{1D425}\x{1D42E}\x{1D42C}\x{1D5F0}\x{1D5F0}\x{27E2}",
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

Parse the B<Unisyn> expression:

    my $expr = "𝗮𝑎𝑠𝑠𝑖𝑔𝑛⌊〈❨𝗯𝗽❩〉𝐩𝐥𝐮𝐬❪𝘀𝗰❫⌋⟢𝗮𝗮𝑎𝑠𝑠𝑖𝑔𝑛❬𝗯𝗯𝐩𝐥𝐮𝐬𝗰𝗰❭⟢";

using:

  create (K(address, Rutf8 $expr))->print;

to get:

  ok Assemble(debug => 0, eq => <<END);
Semicolon
  Term
    Assign: 𝑎𝑠𝑠𝑖𝑔𝑛
      Term
        Variable: 𝗮
      Term
        Brackets: ⌊⌋
          Term
            Term
              Dyad: 𝐩𝐥𝐮𝐬
                Term
                  Brackets: ❨❩
                    Term
                      Term
                        Brackets: ❬❭
                          Term
                            Term
                              Variable: 𝗯𝗽
                Term
                  Brackets: ❰❱
                    Term
                      Term
                        Variable: 𝘀𝗰
  Term
    Assign: 𝑎𝑠𝑠𝑖𝑔𝑛
      Term
        Variable: 𝗮𝗮
      Term
        Brackets: ❴❵
          Term
            Term
              Dyad: 𝐩𝐥𝐮𝐬
                Term
                  Variable: 𝗯𝗯
                Term
                  Variable: 𝗰𝗰
  END

=head1 Description

Parse a Unisyn expression.


Version "20210915".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Create

Create a Unisyn parse of a utf8 string.

=head2 create($address, %options)

Create a new unisyn parse from a utf8 string.

     Parameter  Description
  1  $address   Address of a zero terminated utf8 source string to parse as a variable
  2  %options   Parse options.

B<Example:>


  
    create (K(address, Rutf8 $Lex->{sampleText}{vav}))->print;                    # Create parse tree from source terminated with zero  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok Assemble(debug => 0, eq => <<END);
  Assign: 𝑎
    Term
      Variable: 𝗮
    Term
      Variable: 𝗯
  END
  

=head1 Parse

Parse Unisyn expressions

=head1 Traverse

Traverse the parse tree

=head2 traverseTermsAndCall($parse)

Traverse the terms in parse tree in post order and call the operator subroutine associated with each term.

     Parameter  Description
  1  $parse     Parse tree

B<Example:>


    my $p = create (K(address, Rutf8 $Lex->{sampleText}{A}), operators => sub
     {my ($parse) = @_;
  
      my $assign = Subroutine
       {PrintOutStringNL "call assign";
       } [], name=>"UnisynParse::assign";
  
      my $equals = Subroutine
       {PrintOutStringNL "call equals";
       } [], name=>"UnisynParse::equals";
  
      my $o = $parse->operators;                                                  # Operator subroutines
      $o->assign(asciiToAssignLatin("assign"), $assign);
      $o->assign(asciiToAssignLatin("equals"), $equals);
     });
  
  
    $p->traverseTermsAndCall;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    Assemble(debug => 0, eq => <<END)
  call equals
  END
  

=head1 Print

Print a parse tree

=head2 print($parse)

Print a parse tree.

     Parameter  Description
  1  $parse     Parse tree

B<Example:>


  
    create (K(address, Rutf8 $Lex->{sampleText}{vav}))->print;                    # Create parse tree from source terminated with zero  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok Assemble(debug => 0, eq => <<END);
  Assign: 𝑎
    Term
      Variable: 𝗮
    Term
      Variable: 𝗯
  END
  

=head1 SubQuark

A set of quarks describing the method to be called for each lexical operator.  These routines specialize the general purpose quark methods for use on parse methods.

=head2 Nasm::X86::Arena::DescribeSubQuarks($arena)

Return a descriptor for a subQuarks in the specified arena.

     Parameter  Description
  1  $arena     Arena descriptor

=head2 Nasm::X86::Arena::CreateSubQuarks($arena)

Create quarks in a specified arena.

     Parameter  Description
  1  $arena     Arena description optional arena address

=head2 Unisyn::Parse::SubQuarks::reload($q, %options)

Reload the description of a set of sub quarks.

     Parameter  Description
  1  $q         Subquarks
  2  %options   {arena=>arena to use; tree => first tree block; array => first array block}

=head2 Unisyn::Parse::SubQuarks::put($q, $string, $sub)

Put a new subroutine definition into the sub quarks.

     Parameter  Description
  1  $q         Subquarks
  2  $string    String containing operator type and method name
  3  $sub       Variable offset to subroutine

=head2 Unisyn::Parse::SubQuarks::subFromQuark($q, $lexicals, $number)

Given the quark number for a lexical item and the quark set of lexical items get the offset of the associated method.

     Parameter  Description
  1  $q         Sub quarks
  2  $lexicals  Lexical item quarks
  3  $number    Lexical item quark

=head2 Unisyn::Parse::SubQuarks::lexToString($q, $alphabet, $op)

Convert a lexical item to a string.

     Parameter  Description
  1  $q         Sub quarks
  2  $alphabet  The alphabet number
  3  $op        The operator name in that alphabet

=head2 Unisyn::Parse::SubQuarks::dyad($q, $text, $sub)

Define a method for a dyadic operator.

     Parameter  Description
  1  $q         Sub quarks
  2  $text      Sub quarks
  3  $sub       The name of the operator as a utf8 string

=head2 Unisyn::Parse::SubQuarks::assign($q, $text, $sub)

Define a method for an assign operator.

     Parameter  Description
  1  $q         Sub quarks
  2  $text      The name of the operator as a utf8 string
  3  $sub       Variable associated subroutine offset

=head2 assignToShortString($short, $text)

Create a short string representing a dyad and put it in the specified short string.

     Parameter  Description
  1  $short     The number of the short string
  2  $text      The text of the operator in the assign alphabet

=head1 Alphabets

Translate between alphabets

=head2 asciiToAssignLatin($in)

Translate ascii to the corresponding letters in the assign latin alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 asciiToAssignGreek($in)

Translate ascii to the corresponding letters in the assign greek alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 asciiToDyadLatin($in)

Translate ascii to the corresponding letters in the dyad latin alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 asciiToDyadGreek($in)

Translate ascii to the corresponding letters in the dyad greek alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 asciiToPrefixLatin($in)

Translate ascii to the corresponding letters in the prefix latin alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 asciiToPrefixGreek($in)

Translate ascii to the corresponding letters in the prefix greek alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 asciiToSuffixLatin($in)

Translate ascii to the corresponding letters in the suffix latin alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 asciiToSuffixGreek($in)

Translate ascii to the corresponding letters in the suffix greek alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 asciiToVariableLatin($in)

Translate ascii to the corresponding letters in the suffix latin alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 asciiToVariableGreek($in)

Translate ascii to the corresponding letters in the suffix greek alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 asciiToEscaped($in)

Translate ascii to the corresponding letters in the escaped ascii alphabet.

     Parameter  Description
  1  $in        A string of ascii

=head2 semiColon()

Translate ascii to the corresponding letters in the escaped ascii alphabet.



=head1 Hash Definitions




=head2 Unisyn::Parse Definition


Sub quarks




=head3 Output fields


=head4 address8

Address of source string as utf8

=head4 arena

Arena containing tree

=head4 fails

Number of failures encountered in this parse

=head4 operators

Methods implementing each lexical operator

=head4 parse

Offset to the head of the parse tree

=head4 quarks

Quarks representing the strings used in this parse

=head4 size8

Size of source string as utf8

=head4 source32

Source text as utf32

=head4 sourceLength32

Length of utf32 string

=head4 sourceSize32

Size of utf32 allocation

=head4 subQuarks

The quarks used to map a subroutine name to an offset



=head1 Private Methods

=head2 getAlpha($register, $address, $index)

Load the position of a lexical item in its alphabet from the current character.

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

Load the details of the character currently being processed so that we have the index of the character in the upper half of the current character and the lexical type of the character in the lowest byte.


=head2 checkStackHas($depth)

Check that we have at least the specified number of elements on the stack.

     Parameter  Description
  1  $depth     Number of elements required on the stack

=head2 pushElement()

Push the current element on to the stack.


=head2 pushEmpty()

Push the empty element on to the stack.


=head2 lexicalNameFromLetter($l)

Lexical name for a lexical item described by its letter.

     Parameter  Description
  1  $l         Letter of the lexical item

=head2 lexicalNumberFromLetter($l)

Lexical number for a lexical item described by its letter.

     Parameter  Description
  1  $l         Letter of the lexical item

=head2 lexicalItemLength($source32, $offset)

Put the length of a lexical item into variable B<size>.

     Parameter  Description
  1  $source32  B<address> of utf32 source representation
  2  $offset    B<offset> to lexical item in utf32

=head2 new($depth, $description)

Create a new term in the parse tree rooted on the stack.

     Parameter     Description
  1  $depth        Stack depth to be converted
  2  $description  Text reason why we are creating a new term

=head2 error($message)

Write an error message and stop.

     Parameter  Description
  1  $message   Error message

=head2 testSet($set, $register)

Test a set of items, setting the Zero Flag is one matches else clear the Zero flag.

     Parameter  Description
  1  $set       Set of lexical letters
  2  $register  Register to test

=head2 checkSet($set)

Check that one of a set of items is on the top of the stack or complain if it is not.

     Parameter  Description
  1  $set       Set of lexical letters

=head2 reduce($priority)

Convert the longest possible expression on top of the stack into a term  at the specified priority.

     Parameter  Description
  1  $priority  Priority of the operators to reduce

=head2 reduceMultiple($priority)

Reduce existing operators on the stack.

     Parameter  Description
  1  $priority  Priority of the operators to reduce

=head2 accept_a()

Assign.


=head2 accept_b()

Open.


=head2 accept_B()

Closing parenthesis.


=head2 accept_d()

Infix but not assign or semi-colon.


=head2 accept_p()

Prefix.


=head2 accept_q()

Post fix.


=head2 accept_s()

Semi colon.


=head2 accept_v()

Variable.


=head2 parseExpression()

Parse the string of classified lexical items addressed by register $start of length $length.  The resulting parse tree (if any) is returned in r15.


=head2 MatchBrackets(@parameters)

Replace the low three bytes of a utf32 bracket character with 24 bits of offset to the matching opening or closing bracket. Opening brackets have even codes from 0x10 to 0x4e while the corresponding closing bracket has a code one higher.

     Parameter    Description
  1  @parameters  Parameters

=head2 ClassifyNewLines(@parameters)

Scan input string looking for opportunities to convert new lines into semi colons.

     Parameter    Description
  1  @parameters  Parameters

=head2 ClassifyWhiteSpace(@parameters)

Classify white space per: "lib/Unisyn/whiteSpace/whiteSpaceClassification.pl".

     Parameter    Description
  1  @parameters  Parameters

=head2 parseUtf8($parse, @parameters)

Parse a unisyn expression encoded as utf8 and return the parse tree.

     Parameter    Description
  1  $parse       Parse
  2  @parameters  Parameters

=head2 printLexicalItem($parse, $source32, $offset, $size)

Print the utf8 string corresponding to a lexical item at a variable offset.

     Parameter  Description
  1  $parse     Parse tree
  2  $source32  B<address> of utf32 source representation
  3  $offset    B<offset> to lexical item in utf32
  4  $size      B<size> in utf32 chars of item

=head2 showAlphabet($alphabet)

Show an alphabet.

     Parameter  Description
  1  $alphabet  Alphabet name

=head2 T($key, $expected, %options)

Parse some text and dump the results.

     Parameter  Description
  1  $key       Key of text to be parsed
  2  $expected  Expected result
  3  %options   Options

=head2 C($key, $expected, %options)

Parse some text and print the results.

     Parameter  Description
  1  $key       Key of text to be parsed
  2  $expected  Expected result
  3  %options   Options


=head1 Index


1 L<accept_a|/accept_a> - Assign.

2 L<accept_B|/accept_B> - Closing parenthesis.

3 L<accept_b|/accept_b> - Open.

4 L<accept_d|/accept_d> - Infix but not assign or semi-colon.

5 L<accept_p|/accept_p> - Prefix.

6 L<accept_q|/accept_q> - Post fix.

7 L<accept_s|/accept_s> - Semi colon.

8 L<accept_v|/accept_v> - Variable.

9 L<asciiToAssignGreek|/asciiToAssignGreek> - Translate ascii to the corresponding letters in the assign greek alphabet.

10 L<asciiToAssignLatin|/asciiToAssignLatin> - Translate ascii to the corresponding letters in the assign latin alphabet.

11 L<asciiToDyadGreek|/asciiToDyadGreek> - Translate ascii to the corresponding letters in the dyad greek alphabet.

12 L<asciiToDyadLatin|/asciiToDyadLatin> - Translate ascii to the corresponding letters in the dyad latin alphabet.

13 L<asciiToEscaped|/asciiToEscaped> - Translate ascii to the corresponding letters in the escaped ascii alphabet.

14 L<asciiToPrefixGreek|/asciiToPrefixGreek> - Translate ascii to the corresponding letters in the prefix greek alphabet.

15 L<asciiToPrefixLatin|/asciiToPrefixLatin> - Translate ascii to the corresponding letters in the prefix latin alphabet.

16 L<asciiToSuffixGreek|/asciiToSuffixGreek> - Translate ascii to the corresponding letters in the suffix greek alphabet.

17 L<asciiToSuffixLatin|/asciiToSuffixLatin> - Translate ascii to the corresponding letters in the suffix latin alphabet.

18 L<asciiToVariableGreek|/asciiToVariableGreek> - Translate ascii to the corresponding letters in the suffix greek alphabet.

19 L<asciiToVariableLatin|/asciiToVariableLatin> - Translate ascii to the corresponding letters in the suffix latin alphabet.

20 L<assignToShortString|/assignToShortString> - Create a short string representing a dyad and put it in the specified short string.

21 L<C|/C> - Parse some text and print the results.

22 L<checkSet|/checkSet> - Check that one of a set of items is on the top of the stack or complain if it is not.

23 L<checkStackHas|/checkStackHas> - Check that we have at least the specified number of elements on the stack.

24 L<ClassifyNewLines|/ClassifyNewLines> - Scan input string looking for opportunities to convert new lines into semi colons.

25 L<ClassifyWhiteSpace|/ClassifyWhiteSpace> - Classify white space per: "lib/Unisyn/whiteSpace/whiteSpaceClassification.

26 L<create|/create> - Create a new unisyn parse from a utf8 string.

27 L<error|/error> - Write an error message and stop.

28 L<getAlpha|/getAlpha> - Load the position of a lexical item in its alphabet from the current character.

29 L<getLexicalCode|/getLexicalCode> - Load the lexical code of the current character in memory into the specified register.

30 L<lexicalItemLength|/lexicalItemLength> - Put the length of a lexical item into variable B<size>.

31 L<lexicalNameFromLetter|/lexicalNameFromLetter> - Lexical name for a lexical item described by its letter.

32 L<lexicalNumberFromLetter|/lexicalNumberFromLetter> - Lexical number for a lexical item described by its letter.

33 L<loadCurrentChar|/loadCurrentChar> - Load the details of the character currently being processed so that we have the index of the character in the upper half of the current character and the lexical type of the character in the lowest byte.

34 L<MatchBrackets|/MatchBrackets> - Replace the low three bytes of a utf32 bracket character with 24 bits of offset to the matching opening or closing bracket.

35 L<Nasm::X86::Arena::CreateSubQuarks|/Nasm::X86::Arena::CreateSubQuarks> - Create quarks in a specified arena.

36 L<Nasm::X86::Arena::DescribeSubQuarks|/Nasm::X86::Arena::DescribeSubQuarks> - Return a descriptor for a subQuarks in the specified arena.

37 L<new|/new> - Create a new term in the parse tree rooted on the stack.

38 L<parseExpression|/parseExpression> - Parse the string of classified lexical items addressed by register $start of length $length.

39 L<parseUtf8|/parseUtf8> - Parse a unisyn expression encoded as utf8 and return the parse tree.

40 L<print|/print> - Print a parse tree.

41 L<printLexicalItem|/printLexicalItem> - Print the utf8 string corresponding to a lexical item at a variable offset.

42 L<pushElement|/pushElement> - Push the current element on to the stack.

43 L<pushEmpty|/pushEmpty> - Push the empty element on to the stack.

44 L<putLexicalCode|/putLexicalCode> - Put the specified lexical code into the current character in memory.

45 L<reduce|/reduce> - Convert the longest possible expression on top of the stack into a term  at the specified priority.

46 L<reduceMultiple|/reduceMultiple> - Reduce existing operators on the stack.

47 L<semiColon|/semiColon> - Translate ascii to the corresponding letters in the escaped ascii alphabet.

48 L<showAlphabet|/showAlphabet> - Show an alphabet.

49 L<T|/T> - Parse some text and dump the results.

50 L<testSet|/testSet> - Test a set of items, setting the Zero Flag is one matches else clear the Zero flag.

51 L<traverseTermsAndCall|/traverseTermsAndCall> - Traverse the terms in parse tree in post order and call the operator subroutine associated with each term.

52 L<Unisyn::Parse::SubQuarks::assign|/Unisyn::Parse::SubQuarks::assign> - Define a method for an assign operator.

53 L<Unisyn::Parse::SubQuarks::dyad|/Unisyn::Parse::SubQuarks::dyad> - Define a method for a dyadic operator.

54 L<Unisyn::Parse::SubQuarks::lexToString|/Unisyn::Parse::SubQuarks::lexToString> - Convert a lexical item to a string.

55 L<Unisyn::Parse::SubQuarks::put|/Unisyn::Parse::SubQuarks::put> - Put a new subroutine definition into the sub quarks.

56 L<Unisyn::Parse::SubQuarks::reload|/Unisyn::Parse::SubQuarks::reload> - Reload the description of a set of sub quarks.

57 L<Unisyn::Parse::SubQuarks::subFromQuark|/Unisyn::Parse::SubQuarks::subFromQuark> - Given the quark number for a lexical item and the quark set of lexical items get the offset of the associated method.

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
   {plan tests => 23;
   }
  else
   {plan skip_all => qq(Nasm or Intel 64 emulator not available);
   }
 }
else
 {plan skip_all => qq(Not supported on: $^O);
 }

my $startTime = time;                                                           # Tests

eval {goto latest} if !caller(0) and -e "/home/phil";                           # Go to latest test if specified

sub T($$%)                                                                      #P Parse some text and dump the results.
 {my ($key, $expected, %options) = @_;                                          # Key of text to be parsed, expected result, options
  my $source  = $$Lex{sampleText}{$key};                                        # String to be parsed in utf8
  defined $source or confess "No such source";
  my $address = Rutf8 $source;
  my $size    = StringLength V(string, $address);

  my $p = create V(address, $address), %options;                                # Parse

  if (1)                                                                        # Print the parse tree if requested
   {my $t = $p->arena->DescribeTree;
    $t->first->copy($p->parse);
    $t->dump;
   }

  Assemble(debug => 0, eq => $expected);
 }

sub C($$%)                                                                      #P Parse some text and print the results.
 {my ($key, $expected, %options) = @_;                                          # Key of text to be parsed, expected result, options
  create (K(address, Rutf8 $Lex->{sampleText}{$key}), %options)->print;

  Assemble(debug => 0, eq => $expected);
 }

#latest:
ok T(q(brackets), <<END, debug => 0) if 1;
Tree at:  0000 0000 0000 0AD8  length: 0000 0000 0000 000A
  0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
  0000 0000 0000 0014   0000 0000 0000 0000   0000 0000 0000 0000   0000 0A18 0000 0009   0000 00D8 0000 0009   0000 0008 0000 0006   0000 0001 0000 0005   0000 0003 0000 0009
  0000 0B18 0280 000A   0000 0000 0000 0000   0000 0000 0000 0000   0000 000D 0000 000C   0000 0009 0000 0008   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
    index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0003
    index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0005
    index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0001
    index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0006
    index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0008
    index: 0000 0000 0000 0006   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0007   key: 0000 0000 0000 0009   data: 0000 0000 0000 00D8 subTree
    index: 0000 0000 0000 0008   key: 0000 0000 0000 000C   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0009   key: 0000 0000 0000 000D   data: 0000 0000 0000 0A18 subTree
  Tree at:  0000 0000 0000 00D8  length: 0000 0000 0000 0006
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0001   0000 0000 0000 0006   0000 0001 0000 0009
    0000 0118 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0006
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0000
      index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0000
  end
  Tree at:  0000 0000 0000 0A18  length: 0000 0000 0000 0008
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 0010   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0998 0000 0009   0000 0007 0000 0001   0000 0007 0000 0000   0000 0002 0000 0009
    0000 0A58 0080 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0009 0000 0008   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0002
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0000
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0007
      index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0007
      index: 0000 0000 0000 0006   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0007   key: 0000 0000 0000 0009   data: 0000 0000 0000 0998 subTree
    Tree at:  0000 0000 0000 0998  length: 0000 0000 0000 0004
      0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
      0000 0000 0000 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 07D8 0000 0009   0000 0001 0000 0009
      0000 09D8 0008 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0005 0000 0004   0000 0001 0000 0000
        index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
        index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
        index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
        index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 07D8 subTree
      Tree at:  0000 0000 0000 07D8  length: 0000 0000 0000 000A
        0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
        0000 0000 0000 0014   0000 0000 0000 0000   0000 0000 0000 0000   0000 0718 0000 0009   0000 0518 0000 0009   0000 0006 0000 0004   0000 000E 0000 0003   0000 0003 0000 0009
        0000 0818 0280 000A   0000 0000 0000 0000   0000 0000 0000 0000   0000 000D 0000 000C   0000 0009 0000 0008   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
          index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
          index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0003
          index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0003
          index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 000E
          index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0004
          index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0006
          index: 0000 0000 0000 0006   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
          index: 0000 0000 0000 0007   key: 0000 0000 0000 0009   data: 0000 0000 0000 0518 subTree
          index: 0000 0000 0000 0008   key: 0000 0000 0000 000C   data: 0000 0000 0000 0009
          index: 0000 0000 0000 0009   key: 0000 0000 0000 000D   data: 0000 0000 0000 0718 subTree
        Tree at:  0000 0000 0000 0518  length: 0000 0000 0000 0008
          0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
          0000 0000 0000 0010   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0498 0000 0009   0000 0003 0000 0001   0000 0008 0000 0000   0000 0002 0000 0009
          0000 0558 0080 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0009 0000 0008   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
            index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
            index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0002
            index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0000
            index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0008
            index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
            index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0003
            index: 0000 0000 0000 0006   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
            index: 0000 0000 0000 0007   key: 0000 0000 0000 0009   data: 0000 0000 0000 0498 subTree
          Tree at:  0000 0000 0000 0498  length: 0000 0000 0000 0004
            0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
            0000 0000 0000 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 03D8 0000 0009   0000 0001 0000 0009
            0000 04D8 0008 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0005 0000 0004   0000 0001 0000 0000
              index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
              index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
              index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
              index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 03D8 subTree
            Tree at:  0000 0000 0000 03D8  length: 0000 0000 0000 0008
              0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
              0000 0000 0000 0010   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0358 0000 0009   0000 0002 0000 0001   0000 0009 0000 0000   0000 0002 0000 0009
              0000 0418 0080 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0009 0000 0008   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
                index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
                index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0002
                index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0000
                index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0009
                index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
                index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0002
                index: 0000 0000 0000 0006   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
                index: 0000 0000 0000 0007   key: 0000 0000 0000 0009   data: 0000 0000 0000 0358 subTree
              Tree at:  0000 0000 0000 0358  length: 0000 0000 0000 0004
                0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
                0000 0000 0000 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0218 0000 0009   0000 0001 0000 0009
                0000 0398 0008 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0005 0000 0004   0000 0001 0000 0000
                  index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
                  index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
                  index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
                  index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0218 subTree
                Tree at:  0000 0000 0000 0218  length: 0000 0000 0000 0006
                  0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
                  0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0001 0000 0002   0000 000A 0000 0006   0000 0001 0000 0009
                  0000 0258 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
                    index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
                    index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
                    index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0006
                    index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 000A
                    index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0002
                    index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0001
                end
              end
            end
          end
        end
        Tree at:  0000 0000 0000 0718  length: 0000 0000 0000 0008
          0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
          0000 0000 0000 0010   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0698 0000 0009   0000 0005 0000 0001   0000 0012 0000 0000   0000 0002 0000 0009
          0000 0758 0080 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0009 0000 0008   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
            index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
            index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0002
            index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0000
            index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0012
            index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
            index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0005
            index: 0000 0000 0000 0006   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
            index: 0000 0000 0000 0007   key: 0000 0000 0000 0009   data: 0000 0000 0000 0698 subTree
          Tree at:  0000 0000 0000 0698  length: 0000 0000 0000 0004
            0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
            0000 0000 0000 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 05D8 0000 0009   0000 0001 0000 0009
            0000 06D8 0008 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0005 0000 0004   0000 0001 0000 0000
              index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
              index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
              index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
              index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 05D8 subTree
            Tree at:  0000 0000 0000 05D8  length: 0000 0000 0000 0006
              0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
              0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0004 0000 0002   0000 0013 0000 0006   0000 0001 0000 0009
              0000 0618 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
                index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
                index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
                index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0006
                index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0013
                index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0002
                index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0004
            end
          end
        end
      end
    end
  end
end
END

#latest:
ok T(q(vav), <<END) if 1;
Tree at:  0000 0000 0000 02D8  length: 0000 0000 0000 000A
  0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
  0000 0000 0000 0014   0000 0000 0000 0000   0000 0000 0000 0000   0000 0218 0000 0009   0000 00D8 0000 0009   0000 0002 0000 0001   0000 0001 0000 0005   0000 0003 0000 0009
  0000 0318 0280 000A   0000 0000 0000 0000   0000 0000 0000 0000   0000 000D 0000 000C   0000 0009 0000 0008   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
    index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0003
    index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0005
    index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0001
    index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
    index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0002
    index: 0000 0000 0000 0006   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0007   key: 0000 0000 0000 0009   data: 0000 0000 0000 00D8 subTree
    index: 0000 0000 0000 0008   key: 0000 0000 0000 000C   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0009   key: 0000 0000 0000 000D   data: 0000 0000 0000 0218 subTree
  Tree at:  0000 0000 0000 00D8  length: 0000 0000 0000 0006
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0001   0000 0000 0000 0006   0000 0001 0000 0009
    0000 0118 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0006
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0000
      index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0000
  end
  Tree at:  0000 0000 0000 0218  length: 0000 0000 0000 0006
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0001 0000 0001   0000 0002 0000 0006   0000 0001 0000 0009
    0000 0258 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0006
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0002
      index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0001
  end
end
END

if (1) {                                                                        #Tcreate #Tprint
  create (K(address, Rutf8 $Lex->{sampleText}{vav}))->print;                    # Create parse tree from source terminated with zero

  ok Assemble(debug => 0, eq => <<END);
Assign: 𝑎
  Term
    Variable: 𝗮
  Term
    Variable: 𝗯
END
 }

#latest:
ok C(q(vavav), <<END);
Assign: 𝑎
  Term
    Variable: 𝗮
  Term
    Assign: 𝑎
      Term
        Variable: 𝗯
      Term
        Variable: 𝗰
END

#latest:
ok T(q(bvB), <<END) if 1;
Tree at:  0000 0000 0000 0298  length: 0000 0000 0000 0008
  0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
  0000 0000 0000 0010   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0218 0000 0009   0000 0001 0000 0001   0000 0000 0000 0000   0000 0002 0000 0009
  0000 02D8 0080 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0009 0000 0008   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
    index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0002
    index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0000
    index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0000
    index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
    index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0001
    index: 0000 0000 0000 0006   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0007   key: 0000 0000 0000 0009   data: 0000 0000 0000 0218 subTree
  Tree at:  0000 0000 0000 0218  length: 0000 0000 0000 0004
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 0008   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 00D8 0000 0009   0000 0001 0000 0009
    0000 0258 0008 0004   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 00D8 subTree
    Tree at:  0000 0000 0000 00D8  length: 0000 0000 0000 0006
      0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
      0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0003   0000 0001 0000 0006   0000 0001 0000 0009
      0000 0118 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
        index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
        index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
        index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0006
        index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0001
        index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0003
        index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0000
    end
  end
end
END

#latest:
ok C(q(bvB), <<END);
Brackets: ❨❩
  Term
    Term
      Variable: 𝗮𝗯𝗰
END

#latest:
ok C(q(brackets), <<END);
Assign: 𝑎𝑠𝑠𝑖𝑔𝑛
  Term
    Variable: 𝗮
  Term
    Brackets: ⌊⌋
      Term
        Term
          Dyad: 𝐩𝐥𝐮𝐬
            Term
              Brackets: ❨❩
                Term
                  Term
                    Brackets: ❬❭
                      Term
                        Term
                          Variable: 𝗯𝗽
            Term
              Brackets: ❰❱
                Term
                  Term
                    Variable: 𝘀𝗰
END

#latest:
ok C(q(ws), <<END);
Semicolon
  Term
    Assign: 𝑎𝑠𝑠𝑖𝑔𝑛
      Term
        Variable: 𝗮
      Term
        Brackets: ⌊⌋
          Term
            Term
              Dyad: 𝐩𝐥𝐮𝐬
                Term
                  Brackets: ❨❩
                    Term
                      Term
                        Brackets: ❬❭
                          Term
                            Term
                              Variable: 𝗯𝗽
                Term
                  Brackets: ❰❱
                    Term
                      Term
                        Variable: 𝘀𝗰
  Term
    Assign: 𝑎𝑠𝑠𝑖𝑔𝑛
      Term
        Variable: 𝗮𝗮
      Term
        Brackets: ❴❵
          Term
            Term
              Dyad: 𝐩𝐥𝐮𝐬
                Term
                  Variable: 𝗯𝗯
                Term
                  Variable: 𝗰𝗰
END

#latest:;
ok T(q(s), <<END) if 1;
Tree at:  0000 0000 0000 02D8  length: 0000 0000 0000 000A
  0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
  0000 0000 0000 0014   0000 0000 0000 0000   0000 0000 0000 0000   0000 0218 0000 0009   0000 00D8 0000 0009   0000 0002 0000 0001   0000 0001 0000 0008   0000 0003 0000 0009
  0000 0318 0280 000A   0000 0000 0000 0000   0000 0000 0000 0000   0000 000D 0000 000C   0000 0009 0000 0008   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
    index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0003
    index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0008
    index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0001
    index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
    index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0002
    index: 0000 0000 0000 0006   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0007   key: 0000 0000 0000 0009   data: 0000 0000 0000 00D8 subTree
    index: 0000 0000 0000 0008   key: 0000 0000 0000 000C   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0009   key: 0000 0000 0000 000D   data: 0000 0000 0000 0218 subTree
  Tree at:  0000 0000 0000 00D8  length: 0000 0000 0000 0006
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0001   0000 0000 0000 0006   0000 0001 0000 0009
    0000 0118 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0006
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0000
      index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0000
  end
  Tree at:  0000 0000 0000 0218  length: 0000 0000 0000 0006
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0001 0000 0001   0000 0002 0000 0006   0000 0001 0000 0009
    0000 0258 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0006
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0002
      index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0001
  end
end
END

#latest:
ok C(q(s), <<END);
Semicolon
  Term
    Variable: 𝗮
  Term
    Variable: 𝗯
END

#latest:
ok T(q(A), <<END) if 1;
Tree at:  0000 0000 0000 03D8  length: 0000 0000 0000 000A
  0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
  0000 0000 0000 0014   0000 0000 0000 0000   0000 0000 0000 0000   0000 0218 0000 0009   0000 00D8 0000 0009   0000 0002 0000 0006   0000 0002 0000 0005   0000 0003 0000 0009
  0000 0418 0280 000A   0000 0000 0000 0000   0000 0000 0000 0000   0000 000D 0000 000C   0000 0009 0000 0008   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
    index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0003
    index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0005
    index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0002
    index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0006
    index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0002
    index: 0000 0000 0000 0006   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0007   key: 0000 0000 0000 0009   data: 0000 0000 0000 00D8 subTree
    index: 0000 0000 0000 0008   key: 0000 0000 0000 000C   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0009   key: 0000 0000 0000 000D   data: 0000 0000 0000 0218 subTree
  Tree at:  0000 0000 0000 00D8  length: 0000 0000 0000 0006
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0002   0000 0000 0000 0006   0000 0001 0000 0009
    0000 0118 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0006
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0000
      index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0002
      index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0000
  end
  Tree at:  0000 0000 0000 0218  length: 0000 0000 0000 0006
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0001 0000 0007   0000 0008 0000 0002   0000 0001 0000 0009
    0000 0258 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0002
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0008
      index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0007
      index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0001
  end
end
END

#latest:
ok C(q(A), <<END);
Assign: 𝑒𝑞𝑢𝑎𝑙𝑠
  Term
    Variable: 𝗮𝗮
  Term
    Ascii: abc 123
END

=pod
# q(𝚨𝚩𝚾𝚫𝚬𝚽𝚪𝚯𝚰J𝚱𝚲𝚳𝚮𝚶𝚷𝚹𝚸𝚺𝚻𝚼𝚴𝛀𝚵𝚿𝚭𝛂𝛃𝛘𝛅𝛆𝛗𝛄𝛉𝛊j𝛋𝛌𝛍𝛈𝛐𝛑𝛓𝛒𝛔𝛕𝛖𝛎𝛚𝛏𝛙𝛇)
# q(𝜜𝜝𝜲𝜟𝜠𝜱𝜞𝜣𝜤J𝜥𝜦𝜧𝜢𝜪𝜫𝜭𝜬𝜮𝜯𝜰𝜨𝜴𝜩𝜳𝜡𝜶𝜷𝝌𝜹𝜺𝝋𝜸𝜽𝜾j𝜿𝝀𝝁𝜼𝝄𝝅𝝇𝝆𝝈𝝉𝝊𝝂𝝎𝝃𝝍𝜻)
# q(𝞐𝞑𝞦𝞓𝞔𝞥𝞒𝞗𝞘J𝞙𝞚𝞛𝞖𝞞𝞟𝞡𝞠𝞢𝞣𝞤𝞜𝞨𝞝𝞧𝞕𝞪𝞫𝟀𝞭𝞮𝞿𝞬𝞱𝞲j𝞳𝞴𝞵𝞰𝞸𝞹𝞻𝞺𝞼𝞽𝞾𝞶𝟂𝞷𝟁𝞯)
# q(𝝖𝝗𝝬𝝙𝝚𝝫𝝘𝝝𝝞J𝝟𝝠𝝡𝝜𝝤𝝥𝝧𝝦𝝨𝝩𝝪𝝢𝝮𝝣𝝭𝝛𝝰𝝱𝞆𝝳𝝴𝞅𝝲𝝷𝝸j𝝹𝝺𝝻𝝶𝝾𝝿𝞁𝞀𝞂𝞃𝞄𝝼𝞈𝝽𝞇𝝵)
=cut
#latest:
is_deeply asciiToDyadLatin    ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"), q(𝐀𝐁𝐂𝐃𝐄𝐅𝐆𝐇𝐈𝐉𝐊𝐋𝐌𝐍𝐎𝐏𝐐𝐑𝐒𝐓𝐔𝐕𝐖𝐗𝐘𝐙𝐚𝐛𝐜𝐝𝐞𝐟𝐠𝐡𝐢𝐣𝐤𝐥𝐦𝐧𝐨𝐩𝐪𝐫𝐬𝐭𝐮𝐯𝐰𝐱𝐲𝐳);
is_deeply asciiToDyadGreek    ("ABGDEZNHIKLMVXOPRQSTUFCYWabgdeznhiklmvxoprqstufcyw"),   q(𝚨𝚩𝚪𝚫𝚬𝚭𝚮𝚯𝚰𝚱𝚲𝚳𝚴𝚵𝚶𝚷𝚸𝚹𝚺𝚻𝚼𝚽𝚾𝚿𝛀𝛂𝛃𝛄𝛅𝛆𝛇𝛈𝛉𝛊𝛋𝛌𝛍𝛎𝛏𝛐𝛑𝛒𝛓𝛔𝛕𝛖𝛗𝛘𝛙𝛚);
is_deeply asciiToPrefixLatin  ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"), q(𝑨𝑩𝑪𝑫𝑬𝑭𝑮𝑯𝑰𝑱𝑲𝑳𝑴𝑵𝑶𝑷𝑸𝑹𝑺𝑻𝑼𝑽𝑾𝑿𝒀𝒁𝒂𝒃𝒄𝒅𝒆𝒇𝒈𝒉𝒊𝒋𝒌𝒍𝒎𝒏𝒐𝒑𝒒𝒓𝒔𝒕𝒖𝒗𝒘𝒙𝒚𝒛);
is_deeply asciiToPrefixGreek  ("ABGDEZNHIKLMVXOPRQSTUFCYWabgdeznhiklmvxoprqstufcyw"),   q(𝜜𝜝𝜞𝜟𝜠𝜡𝜢𝜣𝜤𝜥𝜦𝜧𝜨𝜩𝜪𝜫𝜬𝜭𝜮𝜯𝜰𝜱𝜲𝜳𝜴𝜶𝜷𝜸𝜹𝜺𝜻𝜼𝜽𝜾𝜿𝝀𝝁𝝂𝝃𝝄𝝅𝝆𝝇𝝈𝝉𝝊𝝋𝝌𝝍𝝎);
is_deeply asciiToSuffixLatin  ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"), q(𝘼𝘽𝘾𝘿𝙀𝙁𝙂𝙃𝙄𝙅𝙆𝙇𝙈𝙉𝙊𝙋𝙌𝙍𝙎𝙏𝙐𝙑𝙒𝙓𝙔𝙕𝙖𝙗𝙘𝙙𝙚𝙛𝙜𝙝𝙞𝙟𝙠𝙡𝙢𝙣𝙤𝙥𝙦𝙧𝙨𝙩𝙪𝙫𝙬𝙭𝙮𝙯);
is_deeply asciiToSuffixGreek  ("ABGDEZNHIKLMVXOPRQSTUFCYWabgdeznhiklmvxoprqstufcyw"),   q(𝞐𝞑𝞒𝞓𝞔𝞕𝞖𝞗𝞘𝞙𝞚𝞛𝞜𝞝𝞞𝞟𝞠𝞡𝞢𝞣𝞤𝞥𝞦𝞧𝞨𝞪𝞫𝞬𝞭𝞮𝞯𝞰𝞱𝞲𝞳𝞴𝞵𝞶𝞷𝞸𝞹𝞺𝞻𝞼𝞽𝞾𝞿𝟀𝟁𝟂);
is_deeply asciiToVariableLatin("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"), q(𝗔𝗕𝗖𝗗𝗘𝗙𝗚𝗛𝗜𝗝𝗞𝗟𝗠𝗡𝗢𝗣𝗤𝗥𝗦𝗧𝗨𝗩𝗪𝗫𝗬𝗭𝗮𝗯𝗰𝗱𝗲𝗳𝗴𝗵𝗶𝗷𝗸𝗹𝗺𝗻𝗼𝗽𝗾𝗿𝘀𝘁𝘂𝘃𝘄𝘅𝘆𝘇);
is_deeply asciiToVariableGreek("ABGDEZNHIKLMVXOPRQSTUFCYWabgdeznhiklmvxoprqstufcyw"),   q(𝝖𝝗𝝘𝝙𝝚𝝛𝝜𝝝𝝞𝝟𝝠𝝡𝝢𝝣𝝤𝝥𝝦𝝧𝝨𝝩𝝪𝝫𝝬𝝭𝝮𝝰𝝱𝝲𝝳𝝴𝝵𝝶𝝷𝝸𝝹𝝺𝝻𝝼𝝽𝝾𝝿𝞀𝞁𝞂𝞃𝞄𝞅𝞆𝞇𝞈);
is_deeply asciiToEscaped      ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"), q(ABCDEFGHIJKLMNOPQRSTUVWXYZ🅐🅑🅒🅓🅔🅕🅖🅗🅘🅙🅚🅛🅜🅝🅞🅟🅠🅡🅢🅣🅤🅥🅦🅧🅨🅩);
is_deeply semiColon, q(⟢);

#latest:
ok T(q(A), <<END,
Quark : 0000 0000 0000 0000 = 0000 0000 0040 207B
Quark : 0000 0000 0000 0001 = 0000 0000 0040 20EF
Tree at:  0000 0000 0000 0698  length: 0000 0000 0000 000B
  0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
  0000 0000 0000 0016   0000 0000 0000 0000   0000 0000 0000 04D8   0000 0009 0000 0398   0000 0009 0000 0002   0000 0006 0000 0002   0000 0005 0040 20EF   0000 0003 0000 0009
  0000 06D8 0500 000B   0000 0000 0000 0000   0000 0000 0000 000D   0000 000C 0000 0009   0000 0008 0000 0007   0000 0006 0000 0005   0000 0004 0000 0002   0000 0001 0000 0000
    index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0003
    index: 0000 0000 0000 0002   key: 0000 0000 0000 0002   data: 0000 0000 0040 20EF
    index: 0000 0000 0000 0003   key: 0000 0000 0000 0004   data: 0000 0000 0000 0005
    index: 0000 0000 0000 0004   key: 0000 0000 0000 0005   data: 0000 0000 0000 0002
    index: 0000 0000 0000 0005   key: 0000 0000 0000 0006   data: 0000 0000 0000 0006
    index: 0000 0000 0000 0006   key: 0000 0000 0000 0007   data: 0000 0000 0000 0002
    index: 0000 0000 0000 0007   key: 0000 0000 0000 0008   data: 0000 0000 0000 0009
    index: 0000 0000 0000 0008   key: 0000 0000 0000 0009   data: 0000 0000 0000 0398 subTree
    index: 0000 0000 0000 0009   key: 0000 0000 0000 000C   data: 0000 0000 0000 0009
    index: 0000 0000 0000 000A   key: 0000 0000 0000 000D   data: 0000 0000 0000 04D8 subTree
  Tree at:  0000 0000 0000 0398  length: 0000 0000 0000 0006
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0002   0000 0000 0000 0006   0000 0001 0000 0009
    0000 03D8 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0006
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0000
      index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0002
      index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0000
  end
  Tree at:  0000 0000 0000 04D8  length: 0000 0000 0000 0006
    0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000
    0000 0000 0000 000C   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0001 0000 0007   0000 0008 0000 0002   0000 0001 0000 0009
    0000 0518 0000 0006   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0000 0000 0000   0000 0007 0000 0006   0000 0005 0000 0004   0000 0001 0000 0000
      index: 0000 0000 0000 0000   key: 0000 0000 0000 0000   data: 0000 0000 0000 0009
      index: 0000 0000 0000 0001   key: 0000 0000 0000 0001   data: 0000 0000 0000 0001
      index: 0000 0000 0000 0002   key: 0000 0000 0000 0004   data: 0000 0000 0000 0002
      index: 0000 0000 0000 0003   key: 0000 0000 0000 0005   data: 0000 0000 0000 0008
      index: 0000 0000 0000 0004   key: 0000 0000 0000 0006   data: 0000 0000 0000 0007
      index: 0000 0000 0000 0005   key: 0000 0000 0000 0007   data: 0000 0000 0000 0001
  end
end
END
operators => sub                                                                # Define lexical operator methods
 {my ($parse) = @_;                                                             # Parse definition
  my $o = $parse->operators;                                                    # Sub quarks describing operators

  my $assign = Subroutine
   {PrintOutStringNL "call assign";
   } [], name=>"UnisynParse::assign";

  my $equals = Subroutine
   {PrintOutStringNL "call equals";
   } [], name=>"UnisynParse::equals";

  $o->assign(asciiToAssignLatin("assign"), $assign);
  $o->assign(asciiToAssignLatin("equals"), $equals);
  $parse->operators->subQuarks->dumpSubs;
 });

#latest:
if (1) {                                                                        #TtraverseTermsAndCall
  my $p = create (K(address, Rutf8 $Lex->{sampleText}{A}), operators => sub
   {my ($parse) = @_;

    my $assign = Subroutine
     {PrintOutStringNL "call assign";
     } [], name=>"UnisynParse::assign";

    my $equals = Subroutine
     {PrintOutStringNL "call equals";
     } [], name=>"UnisynParse::equals";

    my $o = $parse->operators;                                                  # Operator subroutines
    $o->assign(asciiToAssignLatin("assign"), $assign);
    $o->assign(asciiToAssignLatin("equals"), $equals);
   });

  $p->traverseTermsAndCall;

  Assemble(debug => 0, eq => <<END)
call equals
END
 }

unlink $_ for qw(hash print2 sde-log.txt sde-ptr-check.out.txt z.txt);          # Remove incidental files

say STDERR sprintf("# Finished in %.2fs, bytes: %s, execs: %s ",  time - $startTime,
  map {numberWithCommas $_}
    $Nasm::X86::totalBytesAssembled, $Nasm::X86::instructionsExecuted);
