# Name

Zero::NWayTree - N-Way-Tree in Zero assembler language.

<div>

    <p><a href="https://github.com/philiprbrenan/zero"><img src="https://github.com/philiprbrenan/zero/workflows/Test/badge.svg"></a>
</div>

# Synopsis

Create a tree, load it from an array of random numbers, then print out the
results. Show the number of instructions executed in the process.  The
challenge, should you wish to acceopt it, is to reduce these instruction counts
to the minimum possible while still passing all the tests.

    {my $W = 3; my $N = 107; my @r = randomArray $N;

     Start 1;
     my $t = New($W);                                                              # Create tree at expected location in memory

     my $a = Array "aaa";
     for my $I(1..$N)                                                              # Load array
      {my $i = $I-1;
       Mov [$a, $i, "aaa"], $r[$i];
      }

     my $f = FindResult_new;

     ForArray                                                                      # Create tree
      {my ($i, $k) = @_;
       my $n = Keys($t);
       AssertEq $n, $i;                                                            # Check tree size
       my $K = Add $k, $k;
       Tally 1;
       Insert($t, $k, $K,                                                          # Insert a new node
         findResult=>          $f,
         maximumNumberOfKeys=> $W,
         splitPoint=>          int($W/2),
         rightStart=>          int($W/2)+1,
       );
       Tally 0;
      } $a, q(aaa);

     Iterate                                                                       # Iterate tree
      {my ($find) = @_;                                                            # Find result
       my $k = FindResult_key($find);
       Out $k;
       Tally 2;
       my $f = Find($t, $k, findResult=>$f);                                       # Find
       Tally 0;
       my $d = FindResult_data($f);
       my $K = Add $k, $k;
       AssertEq $K, $d;                                                            # Check result
      } $t;

     Tally 3;
     Iterate {} $t;                                                                # Iterate tree
     Tally 0;

     my $e = Execute(suppressOutput=>1);

     is_deeply $e->out, [1..$N];                                                   # Expected sequence

     #say STDERR dump $e->tallyCount;
     is_deeply $e->tallyCount,  24712;                                             # Insertion instruction counts

     #say STDERR dump $e->tallyTotal;
     is_deeply $e->tallyTotal, { 1 => 15666, 2 => 6294, 3 => 2752};

     #say STDERR dump $e->tallyCounts->{1};
     is_deeply $e->tallyCounts->{1}, {                                             # Insert tally
     add               => 159,
     array             => 247,
     arrayCountGreater => 2,
     arrayCountLess    => 262,
     arrayIndex        => 293,
     dec               => 30,
     inc               => 726,
     jEq               => 894,
     jGe               => 648,
     jLe               => 461,
     jLt               => 565,
     jmp               => 878,
     jNe               => 908,
     mov               => 7724,
     moveLong          => 171,
     not               => 631,
     resize            => 161,
     shiftUp           => 300,
     subtract          => 606,
   };

     #say STDERR dump $e->tallyCounts->{2};
     is_deeply $e->tallyCounts->{2}, {                                             # Find tally
     add => 137,
     arrayCountLess => 223,
     arrayIndex => 330,
     inc => 360,
     jEq => 690,
     jGe => 467,
     jLe => 467,
     jmp => 604,
     jNe => 107,
     mov => 1975,
     not => 360,
     subtract => 574};

     #say STDERR dump $e->tallyCounts->{3};
     is_deeply $e->tallyCounts->{3}, {                                             # Iterate tally
     add        => 107,
     array      => 1,
     arrayIndex => 72,
     dec        => 72,
     free       => 1,
     inc        => 162,
     jEq        => 260,
     jFalse     => 28,
     jGe        => 316,
     jmp        => 252,
     jNe        => 117,
     jTrue      => 73,
     mov        => 1111,
     not        => 180};

     #say STDERR printTreeKeys($e->memory); x;
     #say STDERR printTreeData($e->memory); x;
     is_deeply printTreeKeys($e->memory), <<END;
                                                                                                                   38                                                                                                    72
                                                                21                                                                                                       56                                                                                                 89
                               10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
           3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
     1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
   END

     is_deeply printTreeData($e->memory), <<END;
                                                                                                                   76                                                                                                   144
                                                                42                                                                                                      112                                                                                                178
                               20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
           6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
     2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
   END

# Description

Version 20230514.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see [Index](#index).

# Constructor

Create a new tree.

## New($n)

Create a variable referring to a new tree descriptor.

       Parameter  Description
    1  $n         Maximum number of keys per node in this tree

**Example:**

    if (1)                                                                          
     {Start 1;
    
      Out New(3);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [1];
      is_deeply $e->memory, { 1 => bless([0, 0, 3, 0], "Tree") };
     }
    
    if (1)                                                                             
     {my $W = 3; my $N = 66;
    
      Start 1;
    
      my $t = New($W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      For
       {my ($i, $check, $next, $end) = @_;                                          # Insert
        my $d = Add $i, $i;
    
        Insert($t, $i, $d);
       } $N;
    
      For                                                                           # Find each prior element
       {my ($j, $check, $next, $end) = @_;
        my $d = Add $j, $j;
        AssertEq $d, FindResult_data(Find($t, $j));
       } $N;
      AssertNe FindResult_found, FindResult_cmp(Find($t, -1));                      # Should not be present
      AssertNe FindResult_found, FindResult_cmp(Find($t, $N));
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [];                                                        # No asserts
     }
    

## Keys($tree)

Get the number of keys in the tree..

       Parameter  Description
    1  $tree      Tree to examine

**Example:**

    if (1)                                                                                
     {my $W = 3; my $N = 107; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $a = Array "aaa";
      for my $I(1..$N)                                                              # Load array
       {my $i = $I-1;
        Mov [$a, $i, "aaa"], $r[$i];
       }
    
      my $f = FindResult_new;
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
    
        my $n = Keys($t);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       } $a, q(aaa);
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree
      Tally 0;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24712;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal, { 1 => 15666, 2 => 6294, 3 => 2752};
    
      #say STDERR dump $e->tallyCounts->{1};
      is_deeply $e->tallyCounts->{1}, {                                             # Insert tally
      add               => 159,
      array             => 247,
      arrayCountGreater => 2,
      arrayCountLess    => 262,
      arrayIndex        => 293,
      dec               => 30,
      inc               => 726,
      jEq               => 894,
      jGe               => 648,
      jLe               => 461,
      jLt               => 565,
      jmp               => 878,
      jNe               => 908,
      mov               => 7724,
      moveLong          => 171,
      not               => 631,
      resize            => 161,
      shiftUp           => 300,
      subtract          => 606,
    };
    
      #say STDERR dump $e->tallyCounts->{2};
      is_deeply $e->tallyCounts->{2}, {                                             # Find tally
      add => 137,
      arrayCountLess => 223,
      arrayIndex => 330,
      inc => 360,
      jEq => 690,
      jGe => 467,
      jLe => 467,
      jmp => 604,
      jNe => 107,
      mov => 1975,
      not => 360,
      subtract => 574};
    
      #say STDERR dump $e->tallyCounts->{3};
      is_deeply $e->tallyCounts->{3}, {                                             # Iterate tally
      add        => 107,
      array      => 1,
      arrayIndex => 72,
      dec        => 72,
      free       => 1,
      inc        => 162,
      jEq        => 260,
      jFalse     => 28,
      jGe        => 316,
      jmp        => 252,
      jNe        => 117,
      jTrue      => 73,
      mov        => 1111,
      not        => 180};
    
      #say STDERR printTreeKeys($e->memory); x;
      #say STDERR printTreeData($e->memory); x;
      is_deeply printTreeKeys($e->memory), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      is_deeply printTreeData($e->memory), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
    
     }
    

# Find

Find a key in a tree.

## FindResult\_cmp($f)

Get comparison from find result.

       Parameter  Description
    1  $f         Find result

**Example:**

    if (1)                                                                             
     {my $W = 3; my $N = 66;
    
      Start 1;
      my $t = New($W);
    
      For
       {my ($i, $check, $next, $end) = @_;                                          # Insert
        my $d = Add $i, $i;
    
        Insert($t, $i, $d);
       } $N;
    
      For                                                                           # Find each prior element
       {my ($j, $check, $next, $end) = @_;
        my $d = Add $j, $j;
        AssertEq $d, FindResult_data(Find($t, $j));
       } $N;
    
      AssertNe FindResult_found, FindResult_cmp(Find($t, -1));                      # Should not be present  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      AssertNe FindResult_found, FindResult_cmp(Find($t, $N));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [];                                                        # No asserts
     }
    

## FindResult\_data($f)

Get data field from find results.

       Parameter  Description
    1  $f         Find result

**Example:**

    if (1)                                                                                
     {my $W = 3; my $N = 107; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $a = Array "aaa";
      for my $I(1..$N)                                                              # Load array
       {my $i = $I-1;
        Mov [$a, $i, "aaa"], $r[$i];
       }
    
      my $f = FindResult_new;
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       } $a, q(aaa);
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
    
        my $d = FindResult_data($f);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree
      Tally 0;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24712;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal, { 1 => 15666, 2 => 6294, 3 => 2752};
    
      #say STDERR dump $e->tallyCounts->{1};
      is_deeply $e->tallyCounts->{1}, {                                             # Insert tally
      add               => 159,
      array             => 247,
      arrayCountGreater => 2,
      arrayCountLess    => 262,
      arrayIndex        => 293,
      dec               => 30,
      inc               => 726,
      jEq               => 894,
      jGe               => 648,
      jLe               => 461,
      jLt               => 565,
      jmp               => 878,
      jNe               => 908,
      mov               => 7724,
      moveLong          => 171,
      not               => 631,
      resize            => 161,
      shiftUp           => 300,
      subtract          => 606,
    };
    
      #say STDERR dump $e->tallyCounts->{2};
      is_deeply $e->tallyCounts->{2}, {                                             # Find tally
      add => 137,
      arrayCountLess => 223,
      arrayIndex => 330,
      inc => 360,
      jEq => 690,
      jGe => 467,
      jLe => 467,
      jmp => 604,
      jNe => 107,
      mov => 1975,
      not => 360,
      subtract => 574};
    
      #say STDERR dump $e->tallyCounts->{3};
      is_deeply $e->tallyCounts->{3}, {                                             # Iterate tally
      add        => 107,
      array      => 1,
      arrayIndex => 72,
      dec        => 72,
      free       => 1,
      inc        => 162,
      jEq        => 260,
      jFalse     => 28,
      jGe        => 316,
      jmp        => 252,
      jNe        => 117,
      jTrue      => 73,
      mov        => 1111,
      not        => 180};
    
      #say STDERR printTreeKeys($e->memory); x;
      #say STDERR printTreeData($e->memory); x;
      is_deeply printTreeKeys($e->memory), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      is_deeply printTreeData($e->memory), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
    
     }
    

## FindResult\_key($f)

Get key field from find results.

       Parameter  Description
    1  $f         Find result

**Example:**

    if (1)                                                                                
     {my $W = 3; my $N = 107; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $a = Array "aaa";
      for my $I(1..$N)                                                              # Load array
       {my $i = $I-1;
        Mov [$a, $i, "aaa"], $r[$i];
       }
    
      my $f = FindResult_new;
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       } $a, q(aaa);
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
    
        my $k = FindResult_key($find);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree
      Tally 0;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24712;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal, { 1 => 15666, 2 => 6294, 3 => 2752};
    
      #say STDERR dump $e->tallyCounts->{1};
      is_deeply $e->tallyCounts->{1}, {                                             # Insert tally
      add               => 159,
      array             => 247,
      arrayCountGreater => 2,
      arrayCountLess    => 262,
      arrayIndex        => 293,
      dec               => 30,
      inc               => 726,
      jEq               => 894,
      jGe               => 648,
      jLe               => 461,
      jLt               => 565,
      jmp               => 878,
      jNe               => 908,
      mov               => 7724,
      moveLong          => 171,
      not               => 631,
      resize            => 161,
      shiftUp           => 300,
      subtract          => 606,
    };
    
      #say STDERR dump $e->tallyCounts->{2};
      is_deeply $e->tallyCounts->{2}, {                                             # Find tally
      add => 137,
      arrayCountLess => 223,
      arrayIndex => 330,
      inc => 360,
      jEq => 690,
      jGe => 467,
      jLe => 467,
      jmp => 604,
      jNe => 107,
      mov => 1975,
      not => 360,
      subtract => 574};
    
      #say STDERR dump $e->tallyCounts->{3};
      is_deeply $e->tallyCounts->{3}, {                                             # Iterate tally
      add        => 107,
      array      => 1,
      arrayIndex => 72,
      dec        => 72,
      free       => 1,
      inc        => 162,
      jEq        => 260,
      jFalse     => 28,
      jGe        => 316,
      jmp        => 252,
      jNe        => 117,
      jTrue      => 73,
      mov        => 1111,
      not        => 180};
    
      #say STDERR printTreeKeys($e->memory); x;
      #say STDERR printTreeData($e->memory); x;
      is_deeply printTreeKeys($e->memory), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      is_deeply printTreeData($e->memory), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
    
     }
    

## Find($tree, $key, %options)

Find a key in a tree returning a [FindResult](https://metacpan.org/pod/FindResult) describing the outcome of the search.

       Parameter  Description
    1  $tree      Tree to search
    2  $key       Key to find
    3  %options   Options

**Example:**

    if (1)                                                                             
     {my $W = 3; my $N = 66;
    
      Start 1;
      my $t = New($W);
    
      For
       {my ($i, $check, $next, $end) = @_;                                          # Insert
        my $d = Add $i, $i;
    
        Insert($t, $i, $d);
       } $N;
    
    
      For                                                                           # Find each prior element  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($j, $check, $next, $end) = @_;
        my $d = Add $j, $j;
    
        AssertEq $d, FindResult_data(Find($t, $j));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       } $N;
    
      AssertNe FindResult_found, FindResult_cmp(Find($t, -1));                      # Should not be present  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      AssertNe FindResult_found, FindResult_cmp(Find($t, $N));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [];                                                        # No asserts
     }
    
    if (1)                                                                                
     {my $W = 3; my $N = 107; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $a = Array "aaa";
      for my $I(1..$N)                                                              # Load array
       {my $i = $I-1;
        Mov [$a, $i, "aaa"], $r[$i];
       }
    
      my $f = FindResult_new;
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       } $a, q(aaa);
    
      Iterate                                                                       # Iterate tree
    
       {my ($find) = @_;                                                            # Find result  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
    
        my $f = Find($t, $k, findResult=>$f);                                       # Find  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree
      Tally 0;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24712;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal, { 1 => 15666, 2 => 6294, 3 => 2752};
    
      #say STDERR dump $e->tallyCounts->{1};
      is_deeply $e->tallyCounts->{1}, {                                             # Insert tally
      add               => 159,
      array             => 247,
      arrayCountGreater => 2,
      arrayCountLess    => 262,
      arrayIndex        => 293,
      dec               => 30,
      inc               => 726,
      jEq               => 894,
      jGe               => 648,
      jLe               => 461,
      jLt               => 565,
      jmp               => 878,
      jNe               => 908,
      mov               => 7724,
      moveLong          => 171,
      not               => 631,
      resize            => 161,
      shiftUp           => 300,
      subtract          => 606,
    };
    
      #say STDERR dump $e->tallyCounts->{2};
    
      is_deeply $e->tallyCounts->{2}, {                                             # Find tally  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      add => 137,
      arrayCountLess => 223,
      arrayIndex => 330,
      inc => 360,
      jEq => 690,
      jGe => 467,
      jLe => 467,
      jmp => 604,
      jNe => 107,
      mov => 1975,
      not => 360,
      subtract => 574};
    
      #say STDERR dump $e->tallyCounts->{3};
      is_deeply $e->tallyCounts->{3}, {                                             # Iterate tally
      add        => 107,
      array      => 1,
      arrayIndex => 72,
      dec        => 72,
      free       => 1,
      inc        => 162,
      jEq        => 260,
      jFalse     => 28,
      jGe        => 316,
      jmp        => 252,
      jNe        => 117,
      jTrue      => 73,
      mov        => 1111,
      not        => 180};
    
      #say STDERR printTreeKeys($e->memory); x;
      #say STDERR printTreeData($e->memory); x;
      is_deeply printTreeKeys($e->memory), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      is_deeply printTreeData($e->memory), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
    
     }
    

# Insert

Create a new entry ina tree connecting a key to data.

## Insert($tree, $key, $data, %options)

Insert a key and its associated data into a tree.

       Parameter  Description
    1  $tree      Tree
    2  $key       Key
    3  $data      Data
    4  %options

**Example:**

    if (1)                                                                          
     {Start 1;
      my $t = New(3);                                                               # Create tree
      my $f = Find($t, 1);
      my $c = FindResult_cmp($f);
      AssertEq($c, FindResult_notFound);
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [];
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, 1, 11);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {
      1 => bless([1, 1, 3, 3], "Tree"),
      3 => bless([1, 1, 0, 1, 4, 5, 0], "Node"),
      4 => bless([1], "Keys"),
      5 => bless([11], "Data")};
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, 1, 11);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Insert($t, 2, 22);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {
      1 => bless([2, 1, 3, 3], "Tree"),
      3 => bless([2, 1, 0, 1, 4, 5, 0], "Node"),
      4 => bless([1, 2], "Keys"),
      5 => bless([11, 22], "Data")};
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {
      1 => bless([3, 1, 3, 3], "Tree"),
      3 => bless([3, 1, 0, 1, 4, 5, 0], "Node"),
      4 => bless([1, 2, 3], "Keys"),
      5 => bless([11, 22, 33], "Data")};
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {
      1  => bless([4, 3, 3, 3], "Tree"),
      3  => bless([1, 1, 0, 1, 4, 5, 15], "Node"),
      4  => bless([2], "Keys"),
      5  => bless([22], "Data"),
      9  => bless([1, 2, 3, 1, 10, 11, 0], "Node"),
      10 => bless([1], "Keys"),
      11 => bless([11], "Data"),
      12 => bless([2, 3, 3, 1, 13, 14, 0], "Node"),
      13 => bless([3, 4], "Keys"),
      14 => bless([33, 44], "Data"),
      15 => bless([9, 12], "Down")};
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..5;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->memory, {
      1  => bless([5, 4, 3, 3], "Tree"),
      3  => bless([2, 1, 0, 1, 4, 5, 15], "Node"),
      4  => bless([2, 4], "Keys"),
      5  => bless([22, 44], "Data"),
      9  => bless([1, 2, 3, 1, 10, 11, 0], "Node"),
      10 => bless([1], "Keys"),
      11 => bless([11], "Data"),
      12 => bless([1, 3, 3, 1, 13, 14, 0], "Node"),
      13 => bless([3], "Keys"),
      14 => bless([33], "Data"),
      15 => bless([9, 12, 17], "Down"),
      17 => bless([1, 4, 3, 1, 18, 19, 0], "Node"),
      18 => bless([5], "Keys"),
      19 => bless([55], "Data")};
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..6;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {
      1  => bless([6, 4, 3, 3], "Tree"),
      3  => bless([2, 1, 0, 1, 4, 5, 15], "Node"),
      4  => bless([2, 4], "Keys"),
      5  => bless([22, 44], "Data"),
      9  => bless([1, 2, 3, 1, 10, 11, 0], "Node"),
      10 => bless([1], "Keys"),
      11 => bless([11], "Data"),
      12 => bless([1, 3, 3, 1, 13, 14, 0], "Node"),
      13 => bless([3], "Keys"),
      14 => bless([33], "Data"),
      15 => bless([9, 12, 17], "Down"),
      17 => bless([2, 4, 3, 1, 18, 19, 0], "Node"),
      18 => bless([5, 6], "Keys"),
      19 => bless([55, 66], "Data")};
     }
    
    if (1)                                                                             
     {my $W = 3; my $N = 66;
    
      Start 1;
      my $t = New($W);
    
      For
    
       {my ($i, $check, $next, $end) = @_;                                          # Insert  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $d = Add $i, $i;
    
    
        Insert($t, $i, $d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       } $N;
    
      For                                                                           # Find each prior element
       {my ($j, $check, $next, $end) = @_;
        my $d = Add $j, $j;
        AssertEq $d, FindResult_data(Find($t, $j));
       } $N;
      AssertNe FindResult_found, FindResult_cmp(Find($t, -1));                      # Should not be present
      AssertNe FindResult_found, FindResult_cmp(Find($t, $N));
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [];                                                        # No asserts
     }
    

# Iteration

Iterate over the keys and their associated data held in a tree.

## Iterate($block, $tree)

Iterate over a tree.

       Parameter  Description
    1  $block     Block of code to execute for each key in tree
    2  $tree      Tree

**Example:**

    if (1)                                                                                
     {my $W = 3; my $N = 107; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $a = Array "aaa";
      for my $I(1..$N)                                                              # Load array
       {my $i = $I-1;
        Mov [$a, $i, "aaa"], $r[$i];
       }
    
      my $f = FindResult_new;
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       } $a, q(aaa);
    
    
      Iterate                                                                       # Iterate tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
    
      Iterate {} $t;                                                                # Iterate tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      Tally 0;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24712;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal, { 1 => 15666, 2 => 6294, 3 => 2752};
    
      #say STDERR dump $e->tallyCounts->{1};
      is_deeply $e->tallyCounts->{1}, {                                             # Insert tally
      add               => 159,
      array             => 247,
      arrayCountGreater => 2,
      arrayCountLess    => 262,
      arrayIndex        => 293,
      dec               => 30,
      inc               => 726,
      jEq               => 894,
      jGe               => 648,
      jLe               => 461,
      jLt               => 565,
      jmp               => 878,
      jNe               => 908,
      mov               => 7724,
      moveLong          => 171,
      not               => 631,
      resize            => 161,
      shiftUp           => 300,
      subtract          => 606,
    };
    
      #say STDERR dump $e->tallyCounts->{2};
      is_deeply $e->tallyCounts->{2}, {                                             # Find tally
      add => 137,
      arrayCountLess => 223,
      arrayIndex => 330,
      inc => 360,
      jEq => 690,
      jGe => 467,
      jLe => 467,
      jmp => 604,
      jNe => 107,
      mov => 1975,
      not => 360,
      subtract => 574};
    
      #say STDERR dump $e->tallyCounts->{3};
    
      is_deeply $e->tallyCounts->{3}, {                                             # Iterate tally  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      add        => 107,
      array      => 1,
      arrayIndex => 72,
      dec        => 72,
      free       => 1,
      inc        => 162,
      jEq        => 260,
      jFalse     => 28,
      jGe        => 316,
      jmp        => 252,
      jNe        => 117,
      jTrue      => 73,
      mov        => 1111,
      not        => 180};
    
      #say STDERR printTreeKeys($e->memory); x;
      #say STDERR printTreeData($e->memory); x;
      is_deeply printTreeKeys($e->memory), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      is_deeply printTreeData($e->memory), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
    
     }
    

# Print

Print trees horizontally.

## printTreeKeys($m)

Print the keys held in a tree.

       Parameter  Description
    1  $m         Memory

**Example:**

    if (1)                                                                                
     {my $W = 3; my $N = 107; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $a = Array "aaa";
      for my $I(1..$N)                                                              # Load array
       {my $i = $I-1;
        Mov [$a, $i, "aaa"], $r[$i];
       }
    
      my $f = FindResult_new;
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       } $a, q(aaa);
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree
      Tally 0;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24712;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal, { 1 => 15666, 2 => 6294, 3 => 2752};
    
      #say STDERR dump $e->tallyCounts->{1};
      is_deeply $e->tallyCounts->{1}, {                                             # Insert tally
      add               => 159,
      array             => 247,
      arrayCountGreater => 2,
      arrayCountLess    => 262,
      arrayIndex        => 293,
      dec               => 30,
      inc               => 726,
      jEq               => 894,
      jGe               => 648,
      jLe               => 461,
      jLt               => 565,
      jmp               => 878,
      jNe               => 908,
      mov               => 7724,
      moveLong          => 171,
      not               => 631,
      resize            => 161,
      shiftUp           => 300,
      subtract          => 606,
    };
    
      #say STDERR dump $e->tallyCounts->{2};
      is_deeply $e->tallyCounts->{2}, {                                             # Find tally
      add => 137,
      arrayCountLess => 223,
      arrayIndex => 330,
      inc => 360,
      jEq => 690,
      jGe => 467,
      jLe => 467,
      jmp => 604,
      jNe => 107,
      mov => 1975,
      not => 360,
      subtract => 574};
    
      #say STDERR dump $e->tallyCounts->{3};
      is_deeply $e->tallyCounts->{3}, {                                             # Iterate tally
      add        => 107,
      array      => 1,
      arrayIndex => 72,
      dec        => 72,
      free       => 1,
      inc        => 162,
      jEq        => 260,
      jFalse     => 28,
      jGe        => 316,
      jmp        => 252,
      jNe        => 117,
      jTrue      => 73,
      mov        => 1111,
      not        => 180};
    
    
      #say STDERR printTreeKeys($e->memory); x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      #say STDERR printTreeData($e->memory); x;
    
      is_deeply printTreeKeys($e->memory), <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
      is_deeply printTreeData($e->memory), <<END;
                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
    
     }
    

## printTreeData($m)

Print the data held in a tree.

       Parameter  Description
    1  $m         Memory

**Example:**

    if (1)                                                                                
     {my $W = 3; my $N = 107; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);                                                              # Create tree at expected location in memory
    
      my $a = Array "aaa";
      for my $I(1..$N)                                                              # Load array
       {my $i = $I-1;
        Mov [$a, $i, "aaa"], $r[$i];
       }
    
      my $f = FindResult_new;
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K,                                                          # Insert a new node
          findResult=>          $f,
          maximumNumberOfKeys=> $W,
          splitPoint=>          int($W/2),
          rightStart=>          int($W/2)+1,
        );
        Tally 0;
       } $a, q(aaa);
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        Tally 2;
        my $f = Find($t, $k, findResult=>$f);                                       # Find
        Tally 0;
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      Tally 3;
      Iterate {} $t;                                                                # Iterate tree
      Tally 0;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      #say STDERR dump $e->tallyCount;
      is_deeply $e->tallyCount,  24712;                                             # Insertion instruction counts
    
      #say STDERR dump $e->tallyTotal;
      is_deeply $e->tallyTotal, { 1 => 15666, 2 => 6294, 3 => 2752};
    
      #say STDERR dump $e->tallyCounts->{1};
      is_deeply $e->tallyCounts->{1}, {                                             # Insert tally
      add               => 159,
      array             => 247,
      arrayCountGreater => 2,
      arrayCountLess    => 262,
      arrayIndex        => 293,
      dec               => 30,
      inc               => 726,
      jEq               => 894,
      jGe               => 648,
      jLe               => 461,
      jLt               => 565,
      jmp               => 878,
      jNe               => 908,
      mov               => 7724,
      moveLong          => 171,
      not               => 631,
      resize            => 161,
      shiftUp           => 300,
      subtract          => 606,
    };
    
      #say STDERR dump $e->tallyCounts->{2};
      is_deeply $e->tallyCounts->{2}, {                                             # Find tally
      add => 137,
      arrayCountLess => 223,
      arrayIndex => 330,
      inc => 360,
      jEq => 690,
      jGe => 467,
      jLe => 467,
      jmp => 604,
      jNe => 107,
      mov => 1975,
      not => 360,
      subtract => 574};
    
      #say STDERR dump $e->tallyCounts->{3};
      is_deeply $e->tallyCounts->{3}, {                                             # Iterate tally
      add        => 107,
      array      => 1,
      arrayIndex => 72,
      dec        => 72,
      free       => 1,
      inc        => 162,
      jEq        => 260,
      jFalse     => 28,
      jGe        => 316,
      jmp        => 252,
      jNe        => 117,
      jTrue      => 73,
      mov        => 1111,
      not        => 180};
    
      #say STDERR printTreeKeys($e->memory); x;
    
      #say STDERR printTreeData($e->memory); x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply printTreeKeys($e->memory), <<END;
                                                                                                                    38                                                                                                    72
                                                                 21                                                                                                       56                                                                                                 89
                                10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
            3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
      1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
    END
    
    
      is_deeply printTreeData($e->memory), <<END;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                                                                                                                    76                                                                                                   144
                                                                 42                                                                                                      112                                                                                                178
                                20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
            6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
      2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
    END
    
     }
    

# Utilities

Utility functions.

## randomArray($N)

Create a random array.

       Parameter  Description
    1  $N         Size of array

**Example:**

    if (1)                                                                          
    
     {my $W = 3; my $N = 76; my @r = randomArray $N;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Start 1;
      my $t = New($W);
    
      for my $i(0..$N-1)
       {Insert($t, $r[$i], $r[$i]);
       }
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
       } $t;
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [1..$N];
     }
    

# Index

1 [Find](#find) - Find a key in a tree returning a [FindResult](https://metacpan.org/pod/FindResult) describing the outcome of the search.

2 [FindResult\_cmp](#findresult_cmp) - Get comparison from find result.

3 [FindResult\_data](#findresult_data) - Get data field from find results.

4 [FindResult\_key](#findresult_key) - Get key field from find results.

5 [Insert](#insert) - Insert a key and its associated data into a tree.

6 [Iterate](#iterate) - Iterate over a tree.

7 [Keys](#keys) - Get the number of keys in the tree.

8 [New](#new) - Create a variable referring to a new tree descriptor.

9 [printTreeData](#printtreedata) - Print the data held in a tree.

10 [printTreeKeys](#printtreekeys) - Print the keys held in a tree.

11 [randomArray](#randomarray) - Create a random array.

# Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via **cpan**:

    sudo cpan install Zero::NWayTree

# Author

[philiprbrenan@gmail.com](mailto:philiprbrenan@gmail.com)

[http://www.appaapps.com](http://www.appaapps.com)

# Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.
