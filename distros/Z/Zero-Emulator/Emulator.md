# Name

Zero::Emulator - Assemble and emulate a program written in the [Zero](https://github.com/philiprbrenan/zero) assembly programming language.

<div>

    <p><a href="https://github.com/philiprbrenan/zero"><img src="https://github.com/philiprbrenan/zero/workflows/Test/badge.svg"></a>
</div>

# Synopsis

Say "hello world":

    Start 1;

    Out "hello World";

    my $e = Execute;

    is_deeply $e->out, ["hello World"];

# Description

Version 20230514.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see [Index](#index).

# Execution

## Start($version)

Start the current assembly using the specified version of the Zero language.  At  the moment only version 1 works.

       Parameter  Description
    1  $version   Version desired - at the moment only 1

**Example:**

    if (1)                                                                            
    
     {Start 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out "hello World";
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["hello World"];
     }
    

## Add($target, $s1, $s2)

Add the source locations together and store the result in the target area.

       Parameter  Description
    1  $target    Target address
    2  $s1        Source one
    3  $s2        Source two

**Example:**

    if (1)                                                                          
     {Start 1;
    
      my $a = Add 3, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out  $a;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [5];
     }
    
    if (1)                                                                           
     {Start 1;
      my $a = Subtract 4, 2;
      Out $a;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [2];
     }
    

## Subtract($target, $s1, $s2)

Subtract the second source operand value from the first source operand value and store the result in the target area.

       Parameter  Description
    1  $target    Target address
    2  $s1        Source one
    3  $s2        Source two

**Example:**

    if (1)                                                                           
     {Start 1;
    
      my $a = Subtract 4, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [2];
     }
    

## Array($name)

Create a new memory area and write its number into the address named by the target operand.

       Parameter  Description
    1  $name      Name of allocation

**Example:**

    if (1)                                                                             
     {Start 1;
    
      my $a = Array "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Mov [$a, 0, "aaa"], 1;
        Mov [$a, 1, "aaa"], 22;
        Mov [$a, 2, "aaa"], 333;
      my $n = ArraySize $a, "aaa";
      DumpArray $a, "AAAA";
    
      ForArray
       {my ($i, $e, $check, $next, $end) = @_;
        Out $i; Out $e;
       }  $a, "aaa";
    
      Nop;
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {1=>[1, 22, 333]};
    
      is_deeply $e->out,
    [ "AAAA",
      "bless([1, 22, 333], \"aaa\")",
      "Stack trace",
      "    1     6 dumpArray",
      0,
      1,
      1,
      22,
      2,
      333];
     }
    

## Free($target, $source)

Free the memory area named by the target operand after confirming that it has the name specified on the source operand.

       Parameter  Description
    1  $target    Target area yielding the id of the area to be freed
    2  $source    Source area yielding the name of the area to be freed

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array "node";
    
      Free $a, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [
      "Wrong name: aaa for array with name: node",
      "    1     2 free",
    ];
     }
    
    if (1)                                                                           
     {Start 1;
      my $a = Array "node";
      Out $a;
      Mov [$a, 1, 'node'], 1;
      Mov [$a, 2, 'node'], 2;
      Mov 1, [$a, \1, 'node'];
      Dump "dddd";
    
      Free $a, "node";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [
      1,
      "dddd",
      "-2=bless([], \"return\")",
      "-1=bless([], \"params\")",
      "0=bless([1, 1], \"stackArea\")",
      "1=bless([undef, 1, 2], \"node\")",
      "Stack trace",
      "    1     6 dump",
    ];
     }
    

## ArraySize($area, $name)

The current size of an array.

       Parameter  Description
    1  $area      Location of area
    2  $name      Name of area

**Example:**

    if (1)                                                                             
     {Start 1;
      my $a = Array "aaa";
        Mov [$a, 0, "aaa"], 1;
        Mov [$a, 1, "aaa"], 22;
        Mov [$a, 2, "aaa"], 333;
    
      my $n = ArraySize $a, "aaa";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      DumpArray $a, "AAAA";
    
      ForArray
       {my ($i, $e, $check, $next, $end) = @_;
        Out $i; Out $e;
       }  $a, "aaa";
    
      Nop;
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {1=>[1, 22, 333]};
    
      is_deeply $e->out,
    [ "AAAA",
      "bless([1, 22, 333], \"aaa\")",
      "Stack trace",
      "    1     6 dumpArray",
      0,
      1,
      1,
      22,
      2,
      333];
     }
    

## ArrayIndex()

Find the 1 based index of the second source operand in the array referenced by the first source operand if it is present in the array else 0 into the target location.  The business of returning -1 leads to the inferno of try catch.

**Example:**

    if (1)                                                                            
     {Start 1;
      my $a = Array "aaa";
      Mov [$a, 0, "aaa"], 10;
      Mov [$a, 1, "aaa"], 20;
      Mov [$a, 2, "aaa"], 30;
    
    
      Out ArrayIndex $a, 30;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayIndex $a, 20;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayIndex $a, 10;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayIndex $a, 15;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayCountLess $a, 35;
      Out ArrayCountLess $a, 25;
      Out ArrayCountLess $a, 15;
      Out ArrayCountLess $a,  5;
    
      Out ArrayCountGreater $a, 35;
      Out ArrayCountGreater $a, 25;
      Out ArrayCountGreater $a, 15;
      Out ArrayCountGreater $a,  5;
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [3,2,1,0,  3,2,1,0, 0,1,2,3];
     }
    

## ArrayCountLess()

Count the number of elements in the array specified by the first source operand that are less than the element supplied by the second source operand and place the result in the target location.

**Example:**

    if (1)                                                                            
     {Start 1;
      my $a = Array "aaa";
      Mov [$a, 0, "aaa"], 10;
      Mov [$a, 1, "aaa"], 20;
      Mov [$a, 2, "aaa"], 30;
    
      Out ArrayIndex $a, 30;
      Out ArrayIndex $a, 20;
      Out ArrayIndex $a, 10;
      Out ArrayIndex $a, 15;
    
    
      Out ArrayCountLess $a, 35;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayCountLess $a, 25;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayCountLess $a, 15;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayCountLess $a,  5;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayCountGreater $a, 35;
      Out ArrayCountGreater $a, 25;
      Out ArrayCountGreater $a, 15;
      Out ArrayCountGreater $a,  5;
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [3,2,1,0,  3,2,1,0, 0,1,2,3];
     }
    

## ArrayCountGreater()

Count the number of elements in the array specified by the first source operand that are greater than the element supplied by the second source operand and place the result in the target location.

**Example:**

    if (1)                                                                            
     {Start 1;
      my $a = Array "aaa";
      Mov [$a, 0, "aaa"], 10;
      Mov [$a, 1, "aaa"], 20;
      Mov [$a, 2, "aaa"], 30;
    
      Out ArrayIndex $a, 30;
      Out ArrayIndex $a, 20;
      Out ArrayIndex $a, 10;
      Out ArrayIndex $a, 15;
    
      Out ArrayCountLess $a, 35;
      Out ArrayCountLess $a, 25;
      Out ArrayCountLess $a, 15;
      Out ArrayCountLess $a,  5;
    
    
      Out ArrayCountGreater $a, 35;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayCountGreater $a, 25;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayCountGreater $a, 15;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out ArrayCountGreater $a,  5;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [3,2,1,0,  3,2,1,0, 0,1,2,3];
     }
    

## Call($p)

Call the subroutine at the target address.

       Parameter  Description
    1  $p         Procedure description

**Example:**

    if (1)                                                                           
     {Start 1;
      my $w = Procedure 'write', sub
       {Out 'aaa';
        Return;
       };
    
      Call $w;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["aaa"];
     }
    
    if (1)                                                                          
     {Start 1;
      my $w = Procedure 'write', sub
       {my $a = ParamsGet 0;
        Out $a;
        Return;
       };
      ParamsPut 0, 'bbb';
    
      Call $w;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["bbb"];
     }
    
    if (1)                                                                            
     {Start 1;
      my $w = Procedure 'write', sub
       {ReturnPut 0, "ccc";
        Return;
       };
    
      Call $w;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ReturnGet \0, 0;
      Out \0;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["ccc"];
     }
    
    if (1)                                                                            
     {Start 1;
      my $a = Array "aaa";
      Dump "dddd";
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [
      "dddd",
      "-2=bless([], \"return\")",
      "-1=bless([], \"params\")",
      "0=bless([1], \"stackArea\")",
      "1=bless([], \"aaa\")",
      "Stack trace",
      "    1     2 dump",
    ];
     }
    
    if (1)                                                                              
     {Start 1;
      my $a = Array "aaa";
      my $i = Mov 1;
      my $v = Mov 11;
      ParamsPut 0, $a;
      ParamsPut 1, $i;
      ParamsPut 2, $v;
      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
        my $i = ParamsGet 1;
        my $v = ParamsGet 2;
        Mov [$a, \$i, 'aaa'], $v;
        Return;
       };
    
      Call $set;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $V = Mov [$a, \$i, 'aaa'];
      AssertEq $v, $V;
      Out [$a, \$i, 'aaa'];
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [11];
     }
    
    if (1)                                                                            
     {Start 1;
      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
       };
      ParamsPut 0, 1;
    
      Call $set;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ParamsPut 0, 1;
    
      Call $set;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [];
     }
    

## Confess()

Confess.

**Example:**

    if (1)                                                                          
     {Start 1;
      my $c = Procedure 'confess', sub
    
       {Confess;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       };
      Call $c;
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, ["Confess at:", "    2     3 confess", "    1     6 call"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## Dump($title)

Dump memory.

       Parameter  Description
    1  $title     Title

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Array "node";
      Out $a;
      Mov [$a, 1, 'node'], 1;
      Mov [$a, 2, 'node'], 2;
      Mov 1, [$a, \1, 'node'];
    
      Dump "dddd";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Free $a, "node";
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [
      1,
      "dddd",
      "-2=bless([], \"return\")",
      "-1=bless([], \"params\")",
      "0=bless([1, 1], \"stackArea\")",
      "1=bless([undef, 1, 2], \"node\")",
      "Stack trace",
      "    1     6 dump",
    ];
     }
    

## DumpArray($target, $title)

Dump an array.

       Parameter  Description
    1  $target    Array to dump
    2  $title     Title of dump

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Array "aaa";
        Mov [$a, 0, "aaa"], 1;
        Mov [$a, 1, "aaa"], 22;
        Mov [$a, 2, "aaa"], 333;
    
      DumpArray $a, "AAAA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out,
     ["AAAA",
      "bless([1, 22, 333], \"aaa\")",
      "Stack trace",
      "    1     5 dumpArray",
    ];
     }
    

## Trace($source)

Trace.

       Parameter  Description
    1  $source    Trace setting

**Example:**

    if (1)                                                                            
     {Start 1;
    
      Trace 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfEq 1, 2,
      Then
       {Mov 1, 1;
        Mov 2, 1;
       },
      Else
       {Mov 3, 3;
        Mov 4, 4;
       };
      IfEq 2, 2,
      Then
       {Mov 1, 1;
        Mov 2, 1;
       },
      Else
       {Mov 3, 3;
        Mov 4, 4;
       };
      my $e = Execute(suppressOutput=>1);
      is_deeply scalar($e->out->@*), 14;
     }
    

## TracePoints($source)

Enable trace points.

       Parameter  Description
    1  $source    Trace points if true

**Example:**

    if (1)                                                                          
     {my $N = 5;
      Start 1;
    
      TracePoints 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      For
       {my $a = Mov 1;
        Inc $a;
       } $N;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [
    
      "TracePoints: 1",  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      "Trace",
      "    1     6 tracePoint",
      "Trace",
      "    1     6 tracePoint",
      "Trace",
      "    1     6 tracePoint",
      "Trace",
      "    1     6 tracePoint",
      "Trace",
      "    1     6 tracePoint",
    ];
     }
    

## Dec($target)

Decrement the target.

       Parameter  Description
    1  $target    Target address

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 3;
    
      Dec $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [2];
     }
    

## Inc($target)

Increment the target.

       Parameter  Description
    1  $target    Target address

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 3;
    
      Inc $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [4];
     }
    

## Jmp($target)

Jump to a label.

       Parameter  Description
    1  $target    Target address

**Example:**

    if (1)                                                                          
     {Start 1;
    
      Jmp (my $a = label);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out  1;
    
        Jmp (my $b = label);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      setLabel($a);
        Out  2;
      setLabel($b);
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [2];
     }
    

## Jle($target, $source, $source2)

Jump to a target label if the first source field is less than or equal to the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
      Mov [$a, 0, 'aaa'], $b;
      Mov [$b, 0, 'bbb'], 99;
      For
       {my ($i, $check, $next, $end) = @_;
        my $c = Mov [$a, \0, 'aaa'];
        my $d = Mov [$c, \0, 'bbb'];
        Jeq $next, $d, $d;
        Jne $next, $d, $d;
    
        Jle $next, $d, $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Jlt $next, $d, $d;
        Jge $next, $d, $d;
        Jgt $next, $d, $d;
       } 3;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       24 instructions executed";
      is_deeply $e->memory, { 1=>  bless([2], "aaa"), 2=>  bless([99], "bbb") };
     }
    

## Jlt($target, $source, $source2)

Jump to a target label if the first source field is less than the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
      Mov [$a, 0, 'aaa'], $b;
      Mov [$b, 0, 'bbb'], 99;
      For
       {my ($i, $check, $next, $end) = @_;
        my $c = Mov [$a, \0, 'aaa'];
        my $d = Mov [$c, \0, 'bbb'];
        Jeq $next, $d, $d;
        Jne $next, $d, $d;
        Jle $next, $d, $d;
    
        Jlt $next, $d, $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Jge $next, $d, $d;
        Jgt $next, $d, $d;
       } 3;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       24 instructions executed";
      is_deeply $e->memory, { 1=>  bless([2], "aaa"), 2=>  bless([99], "bbb") };
     }
    

## Jge($target, $source, $source2)

Jump to a target label if the first source field is greater than or equal to the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
      Mov [$a, 0, 'aaa'], $b;
      Mov [$b, 0, 'bbb'], 99;
      For
       {my ($i, $check, $next, $end) = @_;
        my $c = Mov [$a, \0, 'aaa'];
        my $d = Mov [$c, \0, 'bbb'];
        Jeq $next, $d, $d;
        Jne $next, $d, $d;
        Jle $next, $d, $d;
        Jlt $next, $d, $d;
    
        Jge $next, $d, $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Jgt $next, $d, $d;
       } 3;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       24 instructions executed";
      is_deeply $e->memory, { 1=>  bless([2], "aaa"), 2=>  bless([99], "bbb") };
     }
    

## Jgt($target, $source, $source2)

Jump to a target label if the first source field is greater than the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
      Mov [$a, 0, 'aaa'], $b;
      Mov [$b, 0, 'bbb'], 99;
      For
       {my ($i, $check, $next, $end) = @_;
        my $c = Mov [$a, \0, 'aaa'];
        my $d = Mov [$c, \0, 'bbb'];
        Jeq $next, $d, $d;
        Jne $next, $d, $d;
        Jle $next, $d, $d;
        Jlt $next, $d, $d;
        Jge $next, $d, $d;
    
        Jgt $next, $d, $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       } 3;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       24 instructions executed";
      is_deeply $e->memory, { 1=>  bless([2], "aaa"), 2=>  bless([99], "bbb") };
     }
    

## Jeq($target, $source, $source2)

Jump to a target label if the first source field is equal to the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
      Mov [$a, 0, 'aaa'], $b;
      Mov [$b, 0, 'bbb'], 99;
      For
       {my ($i, $check, $next, $end) = @_;
        my $c = Mov [$a, \0, 'aaa'];
        my $d = Mov [$c, \0, 'bbb'];
    
        Jeq $next, $d, $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Jne $next, $d, $d;
        Jle $next, $d, $d;
        Jlt $next, $d, $d;
        Jge $next, $d, $d;
        Jgt $next, $d, $d;
       } 3;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       24 instructions executed";
      is_deeply $e->memory, { 1=>  bless([2], "aaa"), 2=>  bless([99], "bbb") };
     }
    

## Jne($target, $source, $source2)

Jump to a target label if the first source field is not equal to the second source field.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test
    3  $source2

**Example:**

    if (1)                                                                                 
     {Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
      Mov [$a, 0, 'aaa'], $b;
      Mov [$b, 0, 'bbb'], 99;
      For
       {my ($i, $check, $next, $end) = @_;
        my $c = Mov [$a, \0, 'aaa'];
        my $d = Mov [$c, \0, 'bbb'];
        Jeq $next, $d, $d;
    
        Jne $next, $d, $d;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Jle $next, $d, $d;
        Jlt $next, $d, $d;
        Jge $next, $d, $d;
        Jgt $next, $d, $d;
       } 3;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       24 instructions executed";
      is_deeply $e->memory, { 1=>  bless([2], "aaa"), 2=>  bless([99], "bbb") };
     }
    

## JFalse($target, $source)

Jump to a target label if the first source field is equal to zero.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Mov 1;
      Block
       {my ($start, $good, $bad, $end) = @_;
        JTrue $end, $a;
        Out 1;
       };
      Block
       {my ($start, $good, $bad, $end) = @_;
    
        JFalse $end, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out 2;
       };
      Mov $a, 0;
      Block
       {my ($start, $good, $bad, $end) = @_;
        JTrue $end, $a;
        Out 3;
       };
      Block
       {my ($start, $good, $bad, $end) = @_;
    
        JFalse $end, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out 4;
       };
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [2, 3];
     }
    

## JTrue($target, $source)

Jump to a target label if the first source field is not equal to zero.

       Parameter  Description
    1  $target    Target label
    2  $source    Source to test

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Mov 1;
      Block
       {my ($start, $good, $bad, $end) = @_;
    
        JTrue $end, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out 1;
       };
      Block
       {my ($start, $good, $bad, $end) = @_;
        JFalse $end, $a;
        Out 2;
       };
      Mov $a, 0;
      Block
       {my ($start, $good, $bad, $end) = @_;
    
        JTrue $end, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out 3;
       };
      Block
       {my ($start, $good, $bad, $end) = @_;
        JFalse $end, $a;
        Out 4;
       };
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [2, 3];
     }
    

## Label($source)

Create a label.

       Parameter  Description
    1  $source    Name of label

**Example:**

    if (1)                                                                           
     {Start 1;
      Mov 0, 1;
      Jlt ((my $a = label), \0, 2);
        Out  1;
        Jmp (my $b = label);
      setLabel($a);
        Out  2;
      setLabel($b);
    
      Jgt ((my $c = label), \0, 3);
        Out  1;
        Jmp (my $d = label);
      setLabel($c);
        Out  2;
      setLabel($d);
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [2,1];
     }
    
    if (1)                                                                          
     {Start 1;
      Mov 0, 0;
      my $a = setLabel;
        Out \0;
        Inc \0;
      Jlt $a, \0, 10;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [0..9];
     }
    

## Clear($target)

Clear the first bytes of an area.  The area is specified by the first element of the address, the number of locations to clear is specified by the second element of the target address.

       Parameter  Description
    1  $target    Target address

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Array "aaa";
    
      Clear [$a, 10, 'aaa'];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->memory->{1}, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
     }
    

## LeAddress()

Load the address component.

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Array "array";
      my $b = Mov 2;
      my $c = Mov 5;
    
      my $d = LeAddress $c;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $f = LeArea    [$a, \0, 'array'];
      Out $d;
      Out $f;
      Mov [$a, \$b, 'array'], 22;
      Mov [$a, \$c, 'array'], 33;
      Mov [$f, \$d, 'array'], 44;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out,    [2,1];
      is_deeply $e->memory, {1=>[undef, undef, 44, undef, undef, 33]};
     }
    

## LeArea()

Load the address component.

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Array "array";
      my $b = Mov 2;
      my $c = Mov 5;
      my $d = LeAddress $c;
    
      my $f = LeArea    [$a, \0, 'array'];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $d;
      Out $f;
      Mov [$a, \$b, 'array'], 22;
      Mov [$a, \$c, 'array'], 33;
      Mov [$f, \$d, 'array'], 44;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out,    [2,1];
      is_deeply $e->memory, {1=>[undef, undef, 44, undef, undef, 33]};
     }
    

## Mov()

Copy a constant or memory address to the target address.

**Example:**

    if (1)                                                                          
     {Start 1;
    
      my $a = Mov 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [2];
     }
    
     {Start 1;                                                                      
    
    if (1)                                                                          
     {Start 1;
      my $a = Array "aaa";
    
      Mov     [$a,  1, "aaa"],  11;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov  1, [$a, \1, "aaa"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out \1;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [11];
     }
    
    if (1)                                                                           
     {Start 1;
      my $a = Array "alloc";
    
      my $b = Mov 99;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $c = Mov $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov [$a, 0, 'alloc'], $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov [$c, 1, 'alloc'], 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok Execute(memory=>  { 1=>  bless([99, 2], "alloc") });
     }
    
    if (1)                                                                            
     {Start 1;
      my $a = Array "aaa";
      Dump "dddd";
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [
      "dddd",
      "-2=bless([], \"return\")",
      "-1=bless([], \"params\")",
      "0=bless([1], \"stackArea\")",
      "1=bless([], \"aaa\")",
      "Stack trace",
      "    1     2 dump",
    ];
     }
    
    if (1)                                                                              
     {Start 1;
      my $a = Array "aaa";
    
      my $i = Mov 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $v = Mov 11;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ParamsPut 0, $a;
      ParamsPut 1, $i;
      ParamsPut 2, $v;
      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
        my $i = ParamsGet 1;
        my $v = ParamsGet 2;
    
        Mov [$a, \$i, 'aaa'], $v;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Return;
       };
      Call $set;
    
      my $V = Mov [$a, \$i, 'aaa'];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      AssertEq $v, $V;
      Out [$a, \$i, 'aaa'];
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [11];
     }
    
    if (1)                                                                            
     {Start 1;
      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
       };
      ParamsPut 0, 1;
      Call $set;
      ParamsPut 0, 1;
      Call $set;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [];
     }
    
    if (1)                                                                                 
     {Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
    
      Mov [$a, 0, 'aaa'], $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Mov [$b, 0, 'bbb'], 99;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      For
       {my ($i, $check, $next, $end) = @_;
    
        my $c = Mov [$a, \0, 'aaa'];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        my $d = Mov [$c, \0, 'bbb'];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Jeq $next, $d, $d;
        Jne $next, $d, $d;
        Jle $next, $d, $d;
        Jlt $next, $d, $d;
        Jge $next, $d, $d;
        Jgt $next, $d, $d;
       } 3;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       24 instructions executed";
      is_deeply $e->memory, { 1=>  bless([2], "aaa"), 2=>  bless([99], "bbb") };
     }
    
    if (1)                                                                           
     {Start 1;
      my $a = Array 'aaa';
    
      my $b = Mov 2;                                                                # Location to move to in a  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      For
       {my ($i, $check, $next, $end) = @_;
    
        Mov [$a, \$b, 'aaa'], 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Jeq $next, [$a, \$b, 'aaa'], 1;
       } 3;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       19 instructions executed";
      is_deeply $e->memory, {1=>  bless([undef, undef, 1], "aaa")};
     }
    
    if (1)                                                                           
     {Start 1;
      my $a = Array "aaa";
    
        Mov [$a, 0, "aaa"], 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        Mov [$a, 1, "aaa"], 22;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        Mov [$a, 2, "aaa"], 333;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      DumpArray $a, "AAAA";
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out,
     ["AAAA",
      "bless([1, 22, 333], \"aaa\")",
      "Stack trace",
      "    1     5 dumpArray",
    ];
     }
    

## MoveLong($target, $source, $source2)

Copy the number of elements specified by the second source operand from the location specified by the first source operand to the target operand.

       Parameter  Description
    1  $target    Target of move
    2  $source    Source of move
    3  $source2   Length of move

**Example:**

    if (1)                                                                          
     {my $N = 10;
      Start 1;
      my $a = Array "aaa";
      my $b = Array "bbb";
      For
       {my ($i, $Check, $Next, $End) = @_;
        Mov [$a, \$i, "aaa"], $i;
        my $j = Add $i, 100;
        Mov [$b, \$i, "bbb"], $j;
       } $N;
    
    
      MoveLong [$b, \2, 'bbb'], [$a, \4, 'aaa'], 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory,
    {
      1 => bless([0 .. 9], "aaa"),
      2 => bless([100, 101, 4, 5, 6, 105 .. 109], "bbb"),
    };
     }
    

## Not()

Move and not.

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 3;
    
      my $b = Not $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $c = Not $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      Out $b;
      Out $c;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [3, "", 1];
     }
    

## Nop()

Do nothing (but do it well!).

**Example:**

    if (1)                                                                          
     {Start 1;
    
      Nop;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      ok Execute(out=>[]);
     }
    
    if (1)                                                                             
     {Start 1;
      my $a = Array "aaa";
        Mov [$a, 0, "aaa"], 1;
        Mov [$a, 1, "aaa"], 22;
        Mov [$a, 2, "aaa"], 333;
      my $n = ArraySize $a, "aaa";
      DumpArray $a, "AAAA";
    
      ForArray
       {my ($i, $e, $check, $next, $end) = @_;
        Out $i; Out $e;
       }  $a, "aaa";
    
    
      Nop;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {1=>[1, 22, 333]};
    
      is_deeply $e->out,
    [ "AAAA",
      "bless([1, 22, 333], \"aaa\")",
      "Stack trace",
      "    1     6 dumpArray",
      0,
      1,
      1,
      22,
      2,
      333];
     }
    

## Out($source)

Write memory contents to out.

       Parameter  Description
    1  $source    Either a scalar constant or memory address to output

**Example:**

    if (1)                                                                            
     {Start 1;
    
      Out "hello World";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["hello World"];
     }
    

## Procedure($name, $source)

Define a procedure.

       Parameter  Description
    1  $name      Name of procedure
    2  $source    Source code as a subroutine# $assembly->instruction(action=>"procedure"

**Example:**

    if (1)                                                                          
     {Start 1;
    
      my $add = Procedure 'add2', sub  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my $a = ParamsGet 0;
        my $b = Add $a, 2;
        ReturnPut 0, $b;
        Return;
       };
      ParamsPut 0, 2;
      Call $add;
      my $c = ReturnGet 0;
      Out $c;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [4];
     }
    
    if (1)                                                                          
     {Start 1;
      for my $i(1..10)
       {Out $i;
       };
      IfTrue 0,
      Then
       {Out 99;
       };
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [1..10];
     }
    

## ParamsGet()

Get a word from the parameters in the previous frame and store it in the current frame.

**Example:**

    if (1)                                                                              
     {Start 1;
      my $a = Array "aaa";
      my $i = Mov 1;
      my $v = Mov 11;
      ParamsPut 0, $a;
      ParamsPut 1, $i;
      ParamsPut 2, $v;
      my $set = Procedure 'set', sub
    
       {my $a = ParamsGet 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        my $i = ParamsGet 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        my $v = ParamsGet 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Mov [$a, \$i, 'aaa'], $v;
        Return;
       };
      Call $set;
      my $V = Mov [$a, \$i, 'aaa'];
      AssertEq $v, $V;
      Out [$a, \$i, 'aaa'];
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [11];
     }
    

## ParamsPut($target, $source)

Put a word into the parameters list to make it visible in a called procedure.

       Parameter  Description
    1  $target    Parameter number
    2  $source    Address to fetch parameter from

**Example:**

    if (1)                                                                              
     {Start 1;
      my $a = Array "aaa";
      my $i = Mov 1;
      my $v = Mov 11;
    
      ParamsPut 0, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ParamsPut 1, $i;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      ParamsPut 2, $v;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $set = Procedure 'set', sub
       {my $a = ParamsGet 0;
        my $i = ParamsGet 1;
        my $v = ParamsGet 2;
        Mov [$a, \$i, 'aaa'], $v;
        Return;
       };
      Call $set;
      my $V = Mov [$a, \$i, 'aaa'];
      AssertEq $v, $V;
      Out [$a, \$i, 'aaa'];
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [11];
     }
    

## Return()

Return from a procedure via the call stack.

**Example:**

    if (1)                                                                           
     {Start 1;
      my $w = Procedure 'write', sub
       {Out 'aaa';
    
        Return;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       };
      Call $w;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["aaa"];
     }
    

## ReturnGet(if (@\_ == 1))

Get a word from the return area and save it.

       Parameter     Description
    1  if (@_ == 1)  Create a variable

**Example:**

    if (1)                                                                            
     {Start 1;
      my $w = Procedure 'write', sub
       {ReturnPut 0, "ccc";
        Return;
       };
      Call $w;
    
      ReturnGet \0, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out \0;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["ccc"];
     }
    

## ReturnPut($target, $source)

Put a word into the return area.

       Parameter  Description
    1  $target    Offset in return area to write to
    2  $source    Memory address whose contents are to be placed in the return area

**Example:**

    if (1)                                                                            
     {Start 1;
      my $w = Procedure 'write', sub
    
       {ReturnPut 0, "ccc";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Return;
       };
      Call $w;
      ReturnGet \0, 0;
      Out \0;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["ccc"];
     }
    

## Resize($target, $source)

Resize the target area to the source size.

       Parameter  Description
    1  $target    Target address
    2  $source    Source address

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array 'aaa';
      Mov [$a, 0, 'aaa'], 1;
      Mov [$a, 1, 'aaa'], 2;
      Mov [$a, 2, 'aaa'], 3;
    
      Resize $a, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->memory, {1=>  [1, 2]};
     }
    

## Pop(if (@\_ == 0))

Pop the memory area specified by the source operand into the memory address specified by the target operand.

       Parameter     Description
    1  if (@_ == 0)  Pop current stack frame into a local variable

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Array "aaa";
      Push $a, 1;
      Push $a, 2;
    
      my $c = Pop $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $d = Pop $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Out $c;
      Out $d;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out,    [2, 1];
      is_deeply $e->memory, { 1=>  []};
     }
    

## Push()

Push the value in the current stack frame specified by the source operand onto the memory area identified by the target operand.

**Example:**

    if (1)                                                                           
     {Start 1;
      my $a = Array "aaa";
    
      Push $a, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Push $a, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $c = Pop $a;
      my $d = Pop $a;
    
      Out $c;
      Out $d;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out,    [2, 1];
      is_deeply $e->memory, { 1=>  []};
     }
    

## ShiftLeft(my ($target, $source)

Shift left within an element.

       Parameter    Description
    1  my ($target  Target to shift
    2  $source      Amount to shift

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 1;
    
      ShiftLeft $a, $a;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [2];
     }
    

## ShiftRight(my ($target, $source)

Shift right with an element.

       Parameter    Description
    1  my ($target  Target to shift
    2  $source      Amount to shift

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 4;
    
      ShiftRight $a, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $a;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [2];
     }
    

## ShiftUp($target, $source)

Shift an element up one in an area.

       Parameter  Description
    1  $target    Target to shift
    2  $source    Amount to shift

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array "array";
      Mov [$a, 0, 'array'], 0;
      Mov [$a, 1, 'array'], 1;
      Mov [$a, 2, 'array'], 2;
    
      ShiftUp [$a, 1, 'array'], 99;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->memory, {1=>[0, 99, 1, 2]};
     }
    

## ShiftDown(if (@\_ == 1))

Shift an element down one in an area.

       Parameter     Description
    1  if (@_ == 1)  Create a variable

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Array "array";
      Mov [$a, 0, 'array'], 0;
      Mov [$a, 1, 'array'], 99;
      Mov [$a, 2, 'array'], 2;
    
      my $b = ShiftDown [$a, \1, 'array'];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Out $b;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->memory, {1=>[0, 2]};
      is_deeply $e->out,    [99];
     }
    

## Watch($target)

Shift an element down one in an area.

       Parameter  Description
    1  $target    Memory address to watch

**Example:**

    if (1)                                                                          
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      my $c = Mov 3;
    
      Watch $b;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Mov $a, 4;
      Mov $b, 5;
      Mov $c, 6;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out,
    [
      "Change at watched area: 0 (stackArea), address: 1
  ",
      "    1     6 mov",
      "Current value: 2",
      "New     value: 5",
      "-2=bless([], \"return\")",
      "-1=bless([], \"params\")",
      "0=bless([4, 2, 3], \"stackArea\")",
    ];
     }
    

## Tally($source)

Counts instructions when enabled.

       Parameter  Description
    1  $source    Tally instructions when true

**Example:**

    if (1)                                                                           
     {my $N = 5;
      Start 1;
      For
    
       {Tally 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $a = Mov 1;
    
        Tally 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Inc $a;
    
        Tally 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       } $N;
      my $e = Execute;
    
      is_deeply $e->tallyCount, 2 * $N;
      is_deeply $e->tallyCounts,{ 1 => {mov => $N}, 2 => {inc => $N}};
     }
    

## Then($t)

Then block.

       Parameter  Description
    1  $t         Then block subroutine

**Example:**

    if (1)                                                                            
     {Start 1;
      Trace 1;
      IfEq 1, 2,
    
      Then  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Mov 1, 1;
        Mov 2, 1;
       },
      Else
       {Mov 3, 3;
        Mov 4, 4;
       };
      IfEq 2, 2,
    
      Then  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Mov 1, 1;
        Mov 2, 1;
       },
      Else
       {Mov 3, 3;
        Mov 4, 4;
       };
      my $e = Execute(suppressOutput=>1);
      is_deeply scalar($e->out->@*), 14;
     }
    

## Else($e)

Else block.

       Parameter  Description
    1  $e         Else block subroutine

**Example:**

    if (1)                                                                            
     {Start 1;
      Trace 1;
      IfEq 1, 2,
      Then
       {Mov 1, 1;
        Mov 2, 1;
       },
    
      Else  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Mov 3, 3;
        Mov 4, 4;
       };
      IfEq 2, 2,
      Then
       {Mov 1, 1;
        Mov 2, 1;
       },
    
      Else  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Mov 3, 3;
        Mov 4, 4;
       };
      my $e = Execute(suppressOutput=>1);
      is_deeply scalar($e->out->@*), 14;
     }
    

## IfFalse($a, %options)

Execute then clause if the specified memory address is zero representing false.

       Parameter  Description
    1  $a         Memory address
    2  %options   Then block

**Example:**

    if (1)                                                                            
     {Start 1;
    
      IfFalse 1,  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Then
       {Out 1
       },
      Else
       {Out 0
       };
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [0];
     }
    

## IfTrue($a, %options)

Execute then clause if the specified memory address is not zero representing true.

       Parameter  Description
    1  $a         Memory address
    2  %options   Then block

**Example:**

    if (1)                                                                          
     {Start 1;
    
      IfTrue 1,  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Then
       {Out 1
       },
      Else
       {Out 0
       };
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [1];
     }
    

## IfEq($a, $b, %options)

Execute then or else clause depending on whether two memory locations are equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
    
      IfEq $a, $a, Then {Out "Eq"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfNe $a, $a, Then {Out "Ne"};
      IfLe $a, $a, Then {Out "Le"};
      IfLt $a, $a, Then {Out "Lt"};
      IfGe $a, $a, Then {Out "Ge"};
      IfGt $a, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Eq", "Le", "Ge"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
    
      IfEq $a, $b, Then {Out "Eq"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfNe $a, $b, Then {Out "Ne"};
      IfLe $a, $b, Then {Out "Le"};
      IfLt $a, $b, Then {Out "Lt"};
      IfGe $a, $b, Then {Out "Ge"};
      IfGt $a, $b, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Le", "Lt"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
    
      IfEq $b, $a, Then {Out "Eq"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfNe $b, $a, Then {Out "Ne"};
      IfLe $b, $a, Then {Out "Le"};
      IfLt $b, $a, Then {Out "Lt"};
      IfGe $b, $a, Then {Out "Ge"};
      IfGt $b, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Ge", "Gt"];
     }
    

## IfNe($a, $b, %options)

Execute then or else clause depending on whether two memory locations are not equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $a, Then {Out "Eq"};
    
      IfNe $a, $a, Then {Out "Ne"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLe $a, $a, Then {Out "Le"};
      IfLt $a, $a, Then {Out "Lt"};
      IfGe $a, $a, Then {Out "Ge"};
      IfGt $a, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Eq", "Le", "Ge"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $b, Then {Out "Eq"};
    
      IfNe $a, $b, Then {Out "Ne"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLe $a, $b, Then {Out "Le"};
      IfLt $a, $b, Then {Out "Lt"};
      IfGe $a, $b, Then {Out "Ge"};
      IfGt $a, $b, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Le", "Lt"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $b, $a, Then {Out "Eq"};
    
      IfNe $b, $a, Then {Out "Ne"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLe $b, $a, Then {Out "Le"};
      IfLt $b, $a, Then {Out "Lt"};
      IfGe $b, $a, Then {Out "Ge"};
      IfGt $b, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Ge", "Gt"];
     }
    

## IfLt($a, $b, %options)

Execute then or else clause depending on whether two memory locations are less than.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $a, Then {Out "Eq"};
      IfNe $a, $a, Then {Out "Ne"};
      IfLe $a, $a, Then {Out "Le"};
    
      IfLt $a, $a, Then {Out "Lt"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGe $a, $a, Then {Out "Ge"};
      IfGt $a, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Eq", "Le", "Ge"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $b, Then {Out "Eq"};
      IfNe $a, $b, Then {Out "Ne"};
      IfLe $a, $b, Then {Out "Le"};
    
      IfLt $a, $b, Then {Out "Lt"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGe $a, $b, Then {Out "Ge"};
      IfGt $a, $b, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Le", "Lt"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $b, $a, Then {Out "Eq"};
      IfNe $b, $a, Then {Out "Ne"};
      IfLe $b, $a, Then {Out "Le"};
    
      IfLt $b, $a, Then {Out "Lt"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGe $b, $a, Then {Out "Ge"};
      IfGt $b, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Ge", "Gt"];
     }
    

## IfLe($a, $b, %options)

Execute then or else clause depending on whether two memory locations are less than or equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $a, Then {Out "Eq"};
      IfNe $a, $a, Then {Out "Ne"};
    
      IfLe $a, $a, Then {Out "Le"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLt $a, $a, Then {Out "Lt"};
      IfGe $a, $a, Then {Out "Ge"};
      IfGt $a, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Eq", "Le", "Ge"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $b, Then {Out "Eq"};
      IfNe $a, $b, Then {Out "Ne"};
    
      IfLe $a, $b, Then {Out "Le"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLt $a, $b, Then {Out "Lt"};
      IfGe $a, $b, Then {Out "Ge"};
      IfGt $a, $b, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Le", "Lt"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $b, $a, Then {Out "Eq"};
      IfNe $b, $a, Then {Out "Ne"};
    
      IfLe $b, $a, Then {Out "Le"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfLt $b, $a, Then {Out "Lt"};
      IfGe $b, $a, Then {Out "Ge"};
      IfGt $b, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Ge", "Gt"];
     }
    

## IfGt($a, $b, %options)

Execute then or else clause depending on whether two memory locations are greater than.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $a, Then {Out "Eq"};
      IfNe $a, $a, Then {Out "Ne"};
      IfLe $a, $a, Then {Out "Le"};
      IfLt $a, $a, Then {Out "Lt"};
      IfGe $a, $a, Then {Out "Ge"};
    
      IfGt $a, $a, Then {Out "Gt"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Eq", "Le", "Ge"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $b, Then {Out "Eq"};
      IfNe $a, $b, Then {Out "Ne"};
      IfLe $a, $b, Then {Out "Le"};
      IfLt $a, $b, Then {Out "Lt"};
      IfGe $a, $b, Then {Out "Ge"};
    
      IfGt $a, $b, Then {Out "Gt"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Le", "Lt"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $b, $a, Then {Out "Eq"};
      IfNe $b, $a, Then {Out "Ne"};
      IfLe $b, $a, Then {Out "Le"};
      IfLt $b, $a, Then {Out "Lt"};
      IfGe $b, $a, Then {Out "Ge"};
    
      IfGt $b, $a, Then {Out "Gt"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Ge", "Gt"];
     }
    

## IfGe($a, $b, %options)

Execute then or else clause depending on whether two memory locations are greater than or equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options   Then block

**Example:**

    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $a, Then {Out "Eq"};
      IfNe $a, $a, Then {Out "Ne"};
      IfLe $a, $a, Then {Out "Le"};
      IfLt $a, $a, Then {Out "Lt"};
    
      IfGe $a, $a, Then {Out "Ge"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGt $a, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Eq", "Le", "Ge"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $a, $b, Then {Out "Eq"};
      IfNe $a, $b, Then {Out "Ne"};
      IfLe $a, $b, Then {Out "Le"};
      IfLt $a, $b, Then {Out "Lt"};
    
      IfGe $a, $b, Then {Out "Ge"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGt $a, $b, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Le", "Lt"];
     }
    
    if (1)                                                                                   
     {Start 1;
      my $a = Mov 1;
      my $b = Mov 2;
      IfEq $b, $a, Then {Out "Eq"};
      IfNe $b, $a, Then {Out "Ne"};
      IfLe $b, $a, Then {Out "Le"};
      IfLt $b, $a, Then {Out "Lt"};
    
      IfGe $b, $a, Then {Out "Ge"};  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      IfGt $b, $a, Then {Out "Gt"};
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Ne", "Ge", "Gt"];
     }
    

## Assert(%options)

Assert regardless.

       Parameter  Description
    1  %options   Options

**Example:**

    if (1)                                                                          
     {Start 1;
    
      Assert;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, ["Assert failed", "    1     1 assert"];  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
    

## AssertEq($a, $b, %options)

Assert two memory locations are equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertEq \0, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Assert 1 == 2 failed", "    1     2 assertEq"];
     }
    

## AssertNe($a, $b, %options)

Assert two memory locations are not equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertNe \0, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Assert 1 != 1 failed", "    1     2 assertNe"];
     }
    

## AssertLt($a, $b, %options)

Assert two memory locations are less than.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertLt \0, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Assert 1 <  0 failed", "    1     2 assertLt"];
     }
    

## AssertLe($a, $b, %options)

Assert two memory locations are less than or equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertLe \0, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Assert 1 <= 0 failed", "    1     2 assertLe"];
     }
    

## AssertGt($a, $b, %options)

Assert two memory locations are greater than.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertGt \0, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Assert 1 >  2 failed", "    1     2 assertGt"];
     }
    

## AssertGe($a, $b, %options)

Assert are greater than or equal.

       Parameter  Description
    1  $a         First memory address
    2  $b         Second memory address
    3  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      Mov 0, 1;
    
      AssertGe \0, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, ["Assert 1 >= 2 failed", "    1     2 assertGe"];
     }
    

## AssertTrue($a, %options)

Assert true.

       Parameter  Description
    1  $a         Source operand
    2  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      AssertFalse 0;
    
      AssertTrue  0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1, trace=>1);
      is_deeply $e->out,
    [ "   1     0     1   assertFalse                      
  ",
    
      "AssertTrue 0 failed",  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      "    1     2 assertTrue",
      "   2     1     1    assertTrue                      
  "];
     }
    

## AssertFalse($a, %options)

Assert false.

       Parameter  Description
    1  $a         Source operand
    2  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      AssertTrue  1;
    
      AssertFalse 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1, trace=>1);
      is_deeply $e->out,
    [ "   1     0     1    assertTrue                      
  ",
    
      "AssertFalse 1 failed",  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      "    1     2 assertFalse",
      "   2     1     1   assertFalse                      
  "];
    
     }
    

## For($block, $range, %options)

For loop 0..range-1 or in reverse.

       Parameter  Description
    1  $block     Block
    2  $range     Limit
    3  %options   Options

**Example:**

    if (1)                                                                           
     {my $N = 5;
      Start 1;
    
      For  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Tally 1;
        my $a = Mov 1;
        Tally 2;
        Inc $a;
        Tally 0;
       } $N;
      my $e = Execute;
    
      is_deeply $e->tallyCount, 2 * $N;
      is_deeply $e->tallyCounts,{ 1 => {mov => $N}, 2 => {inc => $N}};
     }
    

## ForArray($block, $area, $name, %options)

For loop to process each element of the named area.

       Parameter  Description
    1  $block     Block of code
    2  $area      Area
    3  $name      Area name
    4  %options   Options

**Example:**

    if (1)                                                                             
     {Start 1;
      my $a = Array "aaa";
        Mov [$a, 0, "aaa"], 1;
        Mov [$a, 1, "aaa"], 22;
        Mov [$a, 2, "aaa"], 333;
      my $n = ArraySize $a, "aaa";
      DumpArray $a, "AAAA";
    
    
      ForArray  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($i, $e, $check, $next, $end) = @_;
        Out $i; Out $e;
       }  $a, "aaa";
    
      Nop;
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {1=>[1, 22, 333]};
    
      is_deeply $e->out,
    [ "AAAA",
      "bless([1, 22, 333], \"aaa\")",
      "Stack trace",
      "    1     6 dumpArray",
      0,
      1,
      1,
      22,
      2,
      333];
     }
    

## Good($good)

A good ending.

       Parameter  Description
    1  $good      What to do on a good ending

**Example:**

    if (1)                                                                            
     {Start 1;
      Block
       {my ($start, $good, $bad, $end) = @_;
        Out 1;
        Jmp $good;
       }
    
      Good  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Out 2;
       },
      Bad
       {Out 3;
       };
      Out 4;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [1,2,4];
     }
    

## Bad($bad)

A bad ending.

       Parameter  Description
    1  $bad       What to do on a bad ending

**Example:**

    if (1)                                                                            
     {Start 1;
      Block
       {my ($start, $good, $bad, $end) = @_;
        Out 1;
        Jmp $good;
       }
      Good
       {Out 2;
       },
    
      Bad  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {Out 3;
       };
      Out 4;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [1,2,4];
     }
    

## Block($block, %options)

Block of code that can either be restarted or come to a good or a bad ending.

       Parameter  Description
    1  $block     Block
    2  %options   Options

**Example:**

    if (1)                                                                            
     {Start 1;
    
      Block  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($start, $good, $bad, $end) = @_;
        Out 1;
        Jmp $good;
       }
      Good
       {Out 2;
       },
      Bad
       {Out 3;
       };
      Out 4;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [1,2,4];
     }
    
    if (1)                                                                          
     {Start 1;
    
      Block  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($start, $good, $bad, $end) = @_;
        Out 1;
        Jmp $bad;
       }
      Good
       {Out 2;
       },
      Bad
       {Out 3;
       };
      Out 4;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [1,3,4];
     }
    

## Execute(%options)

Execute the current assembly.

       Parameter  Description
    1  %options   Options

**Example:**

    if (1)                                                                            
     {Start 1;
      Out "hello World";
    
      my $e = Execute(suppressOutput=>1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply $e->out, ["hello World"];
     }
    

# Private Methods

## Zero::Emulator::Execution::areaContent($exec, $address)

Content of an area containing a address in memory in the specified execution.

       Parameter  Description
    1  $exec      Execution environment
    2  $address   Address specification

## Zero::Emulator::Execution::dumpMemory($exec)

Dump memory.

       Parameter  Description
    1  $exec      Execution environment

## Zero::Emulator::Execution::analyzeExecutionResultsLeast($exec, %options)

Analyze execution results for least used code.

       Parameter  Description
    1  $exec      Execution results
    2  %options   Options

## Zero::Emulator::Execution::analyzeExecutionResultsMost($exec, %options)

Analyze execution results for most used code.

       Parameter  Description
    1  $exec      Execution results
    2  %options   Options

## Zero::Emulator::Execution::analyzeExecutionNotRead($exec, %options)

Analyze execution results for variables never read.

       Parameter  Description
    1  $exec      Execution results
    2  %options   Options

## Zero::Emulator::Execution::analyzeExecutionResultsDoubleWrite($exec, %options)

Analyze execution results - double writes.

       Parameter  Description
    1  $exec      Execution results
    2  %options   Options

## Zero::Emulator::Execution::analyzeExecutionResults($exec, %options)

Analyze execution results.

       Parameter  Description
    1  $exec      Execution results
    2  %options   Options

## Zero::Emulator::Execution::check($exec, $area, $name)

Check that a user area access is valid.

       Parameter  Description
    1  $exec      Execution environment
    2  $area      Area
    3  $name      Expected area name

## Zero::Emulator::Execution::getMemory($exec, $area, $address, $name, %options)

Get from memory.

       Parameter  Description
    1  $exec      Execution environment
    2  $area      Area
    3  $address   Address
    4  $name      Expected name of area
    5  %options   Options

## Zero::Emulator::Execution::get($exec, $area, $address)

Get from memory.

       Parameter  Description
    1  $exec      Execution environment
    2  $area      Area
    3  $address   Address

## Zero::Emulator::Execution::set($exec, $address, $value)

Set the value of an address at the specified address in memory in the current execution environment.

       Parameter  Description
    1  $exec      Execution environment
    2  $address   Address specification
    3  $value     Value

## Zero::Emulator::Execution::stackArea($exec)

Current stack frame.

       Parameter  Description
    1  $exec      Execution environment

## Zero::Emulator::Execution::address($exec, $area, $address, $name)

Record a reference to memory.

       Parameter  Description
    1  $exec      Execution environment
    2  $area      Area
    3  $address   Address in area
    4  $name      Memory

## Zero::Emulator::Execution::stackTrace($exec, $title)

Create a stack trace.

       Parameter  Description
    1  $exec      Execution environment
    2  $title     Title

## Zero::Emulator::Execution::stackTraceAndExit($exec, $title, %options)

Create a stack trace and exit from the emulated program.

       Parameter  Description
    1  $exec      Execution environment
    2  $title     Title
    3  %options   Options

## Zero::Emulator::Execution::allocMemory($exec, $name, $stacked)

Create the name of a new memory area.

       Parameter  Description
    1  $exec      Execution environment
    2  $name      Name of allocation
    3  $stacked   Stacked if true

## Zero::Emulator::Execution::setMemoryType($exec, $area, $name)

Set the type of a memory area - a name that can be used to confirm the validity of reads and writes to that array represented by that area.

       Parameter  Description
    1  $exec      Execution environment
    2  $area      Area name
    3  $name      Name of allocation

## Zero::Emulator::Execution::notRead()

Record the unused memory locations in the current stack frame.

## Zero::Emulator::Execution::rwWrite($exec, $area, $address)

Observe write to memory.

       Parameter  Description
    1  $exec      Area in memory
    2  $area      Address within area
    3  $address

## Zero::Emulator::Execution::markAsRead($exec, $area, $address)

Mark a memory address as having been read from.

       Parameter  Description
    1  $exec      Area in memory
    2  $area      Address within area
    3  $address

## Zero::Emulator::Execution::rwRead($exec, $area, $address)

Observe read from memory.

       Parameter  Description
    1  $exec      Area in memory
    2  $area      Address within area
    3  $address

## Zero::Emulator::Execution::left($exec, $ref, $extra)

Address a memory address.

       Parameter  Description
    1  $exec      Reference
    2  $ref       An optional extra offset to add or subtract to the final memory address
    3  $extra

## Zero::Emulator::Execution::leftSuppress($exec, $ref)

Indicate that a memory address has been read.

       Parameter  Description
    1  $exec      Execution environment
    2  $ref       Reference

## Zero::Emulator::Execution::right($exec, $ref)

Get a constant or a memory address.

       Parameter  Description
    1  $exec      Location
    2  $ref       Optional area

## Zero::Emulator::Execution::jumpOp($exec, $i, $check)

Jump to the target address if the tested memory area if the condition is matched.

       Parameter  Description
    1  $exec      Execution environment
    2  $i         Instruction
    3  $check     Check

## Zero::Emulator::Execution::assert1($exec, $test, $sub)

Assert true or false.

       Parameter  Description
    1  $exec      Execution environment
    2  $test      Text of test
    3  $sub       Subroutine of test

## Zero::Emulator::Execution::assert($exec, $test, $sub)

Assert generically.

       Parameter  Description
    1  $exec      Execution environment
    2  $test      Text of test
    3  $sub       Subroutine of test

## Zero::Emulator::Execution::assign($exec, $target, $value)

Assign - check for pointless assignments.

       Parameter  Description
    1  $exec      Execution environment
    2  $target    Target of assign
    3  $value     Value to assign

## Zero::Emulator::Execution::allocateSystemAreas($exec)

Allocate system areas for a new stack frame.

       Parameter  Description
    1  $exec      Execution environment

## Zero::Emulator::Execution::freeSystemAreas($exec, $c)

Free system areas for the specified stack frame.

       Parameter  Description
    1  $exec      Execution environment
    2  $c         Stack frame

## Zero::Emulator::Execution::currentInstruction($exec)

Locate current instruction.

       Parameter  Description
    1  $exec      Execution environment

## Zero::Emulator::Execution::createInitialStackEntry($exec)

Create the initial stack frame.

       Parameter  Description
    1  $exec      Execution environment

## Zero::Emulator::Execution::checkArrayName($exec, $area, $name)

Check the name of an array.

       Parameter  Description
    1  $exec      Execution environment
    2  $area      Array
    3  $name      Array name

## Zero::Emulator::Execution::locateAreaElement($exec, $area, $op)

Locate an element in an array.

       Parameter  Description
    1  $exec      Execution environment
    2  $area      Array
    3  $op        Operation

## Zero::Emulator::Execution::countAreaElement($exec, $area, $op)

Count the number of elements in array that meet some specification.

       Parameter  Description
    1  $exec      Execution environment
    2  $area      Array
    3  $op        Operation

## Zero::Emulator::Code::execute($block, %options)

Execute a block of code.

       Parameter  Description
    1  $block     Block of code
    2  %options   Execution options

## Zero::Emulator::Execution::formatTrace($exec)

Describe last memory assignment.

       Parameter  Description
    1  $exec      Execution

## TracePoint(%options)

Trace point - a point in the code where the flow of execution might change.

       Parameter  Description
    1  %options   Parameters

## Ifx($cmp, $a, $b, %options)

Execute then or else clause depending on whether two memory locations are equal.

       Parameter  Description
    1  $cmp       Comparison
    2  $a         First memory address
    3  $b         Second memory address
    4  %options   Then block

## Assert1($op, $a)

Assert operation.

       Parameter  Description
    1  $op        Operation
    2  $a         Source operand

## Assert2($op, $a, $b)

Assert operation.

       Parameter  Description
    1  $op        Operation
    2  $a         First memory address
    3  $b         Second memory address

## Var($value)

Create a variable initialized to the specified value.

       Parameter  Description
    1  $value     Value

# Index

1 [Add](#add) - Add the source locations together and store the result in the target area.

2 [Array](#array) - Create a new memory area and write its number into the address named by the target operand.

3 [ArrayCountGreater](#arraycountgreater) - Count the number of elements in the array specified by the first source operand that are greater than the element supplied by the second source operand and place the result in the target location.

4 [ArrayCountLess](#arraycountless) - Count the number of elements in the array specified by the first source operand that are less than the element supplied by the second source operand and place the result in the target location.

5 [ArrayIndex](#arrayindex) - Find the 1 based index of the second source operand in the array referenced by the first source operand if it is present in the array else 0 into the target location.

6 [ArraySize](#arraysize) - The current size of an array.

7 [Assert](#assert) - Assert regardless.

8 [Assert1](#assert1) - Assert operation.

9 [Assert2](#assert2) - Assert operation.

10 [AssertEq](#asserteq) - Assert two memory locations are equal.

11 [AssertFalse](#assertfalse) - Assert false.

12 [AssertGe](#assertge) - Assert are greater than or equal.

13 [AssertGt](#assertgt) - Assert two memory locations are greater than.

14 [AssertLe](#assertle) - Assert two memory locations are less than or equal.

15 [AssertLt](#assertlt) - Assert two memory locations are less than.

16 [AssertNe](#assertne) - Assert two memory locations are not equal.

17 [AssertTrue](#asserttrue) - Assert true.

18 [Bad](#bad) - A bad ending.

19 [Block](#block) - Block of code that can either be restarted or come to a good or a bad ending.

20 [Call](#call) - Call the subroutine at the target address.

21 [Clear](#clear) - Clear the first bytes of an area.

22 [Confess](#confess) - Confess.

23 [Dec](#dec) - Decrement the target.

24 [Dump](#dump) - Dump memory.

25 [DumpArray](#dumparray) - Dump an array.

26 [Else](#else) - Else block.

27 [Execute](#execute) - Execute the current assembly.

28 [For](#for) - For loop 0.

29 [ForArray](#forarray) - For loop to process each element of the named area.

30 [Free](#free) - Free the memory area named by the target operand after confirming that it has the name specified on the source operand.

31 [Good](#good) - A good ending.

32 [IfEq](#ifeq) - Execute then or else clause depending on whether two memory locations are equal.

33 [IfFalse](#iffalse) - Execute then clause if the specified memory address is zero representing false.

34 [IfGe](#ifge) - Execute then or else clause depending on whether two memory locations are greater than or equal.

35 [IfGt](#ifgt) - Execute then or else clause depending on whether two memory locations are greater than.

36 [IfLe](#ifle) - Execute then or else clause depending on whether two memory locations are less than or equal.

37 [IfLt](#iflt) - Execute then or else clause depending on whether two memory locations are less than.

38 [IfNe](#ifne) - Execute then or else clause depending on whether two memory locations are not equal.

39 [IfTrue](#iftrue) - Execute then clause if the specified memory address is not zero representing true.

40 [Ifx](#ifx) - Execute then or else clause depending on whether two memory locations are equal.

41 [Inc](#inc) - Increment the target.

42 [Jeq](#jeq) - Jump to a target label if the first source field is equal to the second source field.

43 [JFalse](#jfalse) - Jump to a target label if the first source field is equal to zero.

44 [Jge](#jge) - Jump to a target label if the first source field is greater than or equal to the second source field.

45 [Jgt](#jgt) - Jump to a target label if the first source field is greater than the second source field.

46 [Jle](#jle) - Jump to a target label if the first source field is less than or equal to the second source field.

47 [Jlt](#jlt) - Jump to a target label if the first source field is less than the second source field.

48 [Jmp](#jmp) - Jump to a label.

49 [Jne](#jne) - Jump to a target label if the first source field is not equal to the second source field.

50 [JTrue](#jtrue) - Jump to a target label if the first source field is not equal to zero.

51 [Label](#label) - Create a label.

52 [LeAddress](#leaddress) - Load the address component.

53 [LeArea](#learea) - Load the address component.

54 [Mov](#mov) - Copy a constant or memory address to the target address.

55 [MoveLong](#movelong) - Copy the number of elements specified by the second source operand from the location specified by the first source operand to the target operand.

56 [Nop](#nop) - Do nothing (but do it well!).

57 [Not](#not) - Move and not.

58 [Out](#out) - Write memory contents to out.

59 [ParamsGet](#paramsget) - Get a word from the parameters in the previous frame and store it in the current frame.

60 [ParamsPut](#paramsput) - Put a word into the parameters list to make it visible in a called procedure.

61 [Pop](#pop) - Pop the memory area specified by the source operand into the memory address specified by the target operand.

62 [Procedure](#procedure) - Define a procedure.

63 [Push](#push) - Push the value in the current stack frame specified by the source operand onto the memory area identified by the target operand.

64 [Resize](#resize) - Resize the target area to the source size.

65 [Return](#return) - Return from a procedure via the call stack.

66 [ReturnGet](#returnget) - Get a word from the return area and save it.

67 [ReturnPut](#returnput) - Put a word into the return area.

68 [ShiftDown](#shiftdown) - Shift an element down one in an area.

69 [ShiftLeft](#shiftleft) - Shift left within an element.

70 [ShiftRight](#shiftright) - Shift right with an element.

71 [ShiftUp](#shiftup) - Shift an element up one in an area.

72 [Start](#start) - Start the current assembly using the specified version of the Zero language.

73 [Subtract](#subtract) - Subtract the second source operand value from the first source operand value and store the result in the target area.

74 [Tally](#tally) - Counts instructions when enabled.

75 [Then](#then) - Then block.

76 [Trace](#trace) - Trace.

77 [TracePoint](#tracepoint) - Trace point - a point in the code where the flow of execution might change.

78 [TracePoints](#tracepoints) - Enable trace points.

79 [Var](#var) - Create a variable initialized to the specified value.

80 [Watch](#watch) - Shift an element down one in an area.

81 [Zero::Emulator::Code::execute](#zero-emulator-code-execute) - Execute a block of code.

82 [Zero::Emulator::Execution::address](#zero-emulator-execution-address) - Record a reference to memory.

83 [Zero::Emulator::Execution::allocateSystemAreas](#zero-emulator-execution-allocatesystemareas) - Allocate system areas for a new stack frame.

84 [Zero::Emulator::Execution::allocMemory](#zero-emulator-execution-allocmemory) - Create the name of a new memory area.

85 [Zero::Emulator::Execution::analyzeExecutionNotRead](#zero-emulator-execution-analyzeexecutionnotread) - Analyze execution results for variables never read.

86 [Zero::Emulator::Execution::analyzeExecutionResults](#zero-emulator-execution-analyzeexecutionresults) - Analyze execution results.

87 [Zero::Emulator::Execution::analyzeExecutionResultsDoubleWrite](#zero-emulator-execution-analyzeexecutionresultsdoublewrite) - Analyze execution results - double writes.

88 [Zero::Emulator::Execution::analyzeExecutionResultsLeast](#zero-emulator-execution-analyzeexecutionresultsleast) - Analyze execution results for least used code.

89 [Zero::Emulator::Execution::analyzeExecutionResultsMost](#zero-emulator-execution-analyzeexecutionresultsmost) - Analyze execution results for most used code.

90 [Zero::Emulator::Execution::areaContent](#zero-emulator-execution-areacontent) - Content of an area containing a address in memory in the specified execution.

91 [Zero::Emulator::Execution::assert](#zero-emulator-execution-assert) - Assert generically.

92 [Zero::Emulator::Execution::assert1](#zero-emulator-execution-assert1) - Assert true or false.

93 [Zero::Emulator::Execution::assign](#zero-emulator-execution-assign) - Assign - check for pointless assignments.

94 [Zero::Emulator::Execution::check](#zero-emulator-execution-check) - Check that a user area access is valid.

95 [Zero::Emulator::Execution::checkArrayName](#zero-emulator-execution-checkarrayname) - Check the name of an array.

96 [Zero::Emulator::Execution::countAreaElement](#zero-emulator-execution-countareaelement) - Count the number of elements in array that meet some specification.

97 [Zero::Emulator::Execution::createInitialStackEntry](#zero-emulator-execution-createinitialstackentry) - Create the initial stack frame.

98 [Zero::Emulator::Execution::currentInstruction](#zero-emulator-execution-currentinstruction) - Locate current instruction.

99 [Zero::Emulator::Execution::dumpMemory](#zero-emulator-execution-dumpmemory) - Dump memory.

100 [Zero::Emulator::Execution::formatTrace](#zero-emulator-execution-formattrace) - Describe last memory assignment.

101 [Zero::Emulator::Execution::freeSystemAreas](#zero-emulator-execution-freesystemareas) - Free system areas for the specified stack frame.

102 [Zero::Emulator::Execution::get](#zero-emulator-execution-get) - Get from memory.

103 [Zero::Emulator::Execution::getMemory](#zero-emulator-execution-getmemory) - Get from memory.

104 [Zero::Emulator::Execution::jumpOp](#zero-emulator-execution-jumpop) - Jump to the target address if the tested memory area if the condition is matched.

105 [Zero::Emulator::Execution::left](#zero-emulator-execution-left) - Address a memory address.

106 [Zero::Emulator::Execution::leftSuppress](#zero-emulator-execution-leftsuppress) - Indicate that a memory address has been read.

107 [Zero::Emulator::Execution::locateAreaElement](#zero-emulator-execution-locateareaelement) - Locate an element in an array.

108 [Zero::Emulator::Execution::markAsRead](#zero-emulator-execution-markasread) - Mark a memory address as having been read from.

109 [Zero::Emulator::Execution::notRead](#zero-emulator-execution-notread) - Record the unused memory locations in the current stack frame.

110 [Zero::Emulator::Execution::right](#zero-emulator-execution-right) - Get a constant or a memory address.

111 [Zero::Emulator::Execution::rwRead](#zero-emulator-execution-rwread) - Observe read from memory.

112 [Zero::Emulator::Execution::rwWrite](#zero-emulator-execution-rwwrite) - Observe write to memory.

113 [Zero::Emulator::Execution::set](#zero-emulator-execution-set) - Set the value of an address at the specified address in memory in the current execution environment.

114 [Zero::Emulator::Execution::setMemoryType](#zero-emulator-execution-setmemorytype) - Set the type of a memory area - a name that can be used to confirm the validity of reads and writes to that array represented by that area.

115 [Zero::Emulator::Execution::stackArea](#zero-emulator-execution-stackarea) - Current stack frame.

116 [Zero::Emulator::Execution::stackTrace](#zero-emulator-execution-stacktrace) - Create a stack trace.

117 [Zero::Emulator::Execution::stackTraceAndExit](#zero-emulator-execution-stacktraceandexit) - Create a stack trace and exit from the emulated program.

# Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via **cpan**:

    sudo cpan install Zero::Emulator

# Author

[philiprbrenan@gmail.com](mailto:philiprbrenan@gmail.com)

[http://www.appaapps.com](http://www.appaapps.com)

# Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.
