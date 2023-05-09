# Name

Zero::NWayTree - N-Way-Tree in Zero assembler language.

<div>

    <p><a href="https://github.com/philiprbrenan/zero"><img src="https://github.com/philiprbrenan/zero/workflows/Test/badge.svg"></a>
</div>

# Synopsis

Create a tree, load it from an array of random numbers, then print out the
results:

    my $W = 3; my $N = 107; my @r = randomArray $N;

    Start 1;
    my $t = New($W);                                                              # Create tree at expected location in memory

    my $a = Array "aaa";
    for my $I(1..$N)                                                              # Load array
     {my $i = $I-1;
      Mov [$a, $i, "aaa"], $r[$i];
     }

    ForArray                                                                      # Create tree
     {my ($i, $k) = @_;
      my $n = Keys($t);
      AssertEq $n, $i;                                                            # Check tree size
      my $K = Add $k, $k;
      Tally 1;
      Insert($t, $k, $K);                                                         # Insert a new node
      Tally 0;
     } $a, q(aaa);

    Iterate                                                                       # Iterate tree
     {my ($find) = @_;                                                            # Find result
      my $k = FindResult_key($find);
      Out $k;
      my $f = Find($t, $k);                                                       # Find
      my $d = FindResult_data($f);
      my $K = Add $k, $k;
      AssertEq $K, $d;                                                            # Check result
     } $t;

    my $e = Execute(suppressOutput=>1);

    is_deeply $e->out, [1..$N];                                                   # Expected sequence

    is_deeply $e->tallyCount,  26177;                                             # Insertion instruction counts
    is_deeply $e->tallyCounts->{1}, {
    add        => 860,
    array      => 607,
    call       => 107,
    free       => 360,
    inc        => 1044,
    jEq        => 631,
    jGe        => 1667,
    jLe        => 461,
    jLt        => 565,
    jmp        => 1436,
    jNe        => 1095,
    mov        => 12328,
    not        => 695,
    paramsGet  => 321,
    paramsPut  => 321,
    resize     => 12,
    return     => 107,
    shiftRight => 68,
    shiftUp    => 300,
    subtract   => 641,
    tracePoint => 2551,
  };

# Description

Version 20230513.

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

    
      for my $i(1..$N)
       {Insert($t, $i, my $d = $i+$i);
        for my $j(1..$i)
         {AssertEq $j+$j, FindResult_data(Find($t, $j));
         }
        AssertNe FindResult_found, FindResult_cmp(Find($t, 0));
        AssertNe FindResult_found, FindResult_cmp(Find($t, $i+1));
       }
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [];
     }
    
    if (1)                                                                            
     {my $W = 3; my $N = 66; my @r = randomArray $N;
    
      Start 1;
    
      my $t = New($W);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      for my $i(1..$N)
       {my $k = $r[$i-1]; my $d = $k*2;
        Insert($t, $k, $d);
        AssertEq $d, FindResult_data(Find($t, $k));
       }
    
      my $e = Execute(suppressOutput=>1);
      is_deeply printTreeKeys($e->memory), <<END;
                                                                                            30
                                         13                                                                                           44                               55
                        7                                     20             25                                  37                                     50                               61
         2     4              9    11          15    17                23          27                33    35          39    41                47             52                58             63    65
      1     3     5  6     8    10    12    14    16    18 19    21 22    24    26    28 29    31 32    34    36    38    40    42 43    45 46    48 49    51    53 54    56 57    59 60    62    64    66
    END
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
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
    
        my $n = Keys($t);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K);                                                         # Insert a new node
        Tally 0;
       } $a, q(aaa);
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        my $f = Find($t, $k);                                                       # Find
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      is_deeply $e->tallyCount,  23612;                                             # Insertion instruction counts
    
      #say STDERR "AAAA
  ", dump($e->tallyCounts->{1});
    
      is_deeply $e->tallyCounts->{1}, {
      add => 860,
      array => 607,
      arrayIndex => 7,
      call => 107,
      dec => 7,
      free => 360,
      inc => 1044,
      jEq => 631,
      jGe => 1660,
      jLe => 461,
      jLt => 565,
      jmp => 1436,
      jNe => 1088,
      mov => 12314,
      not => 695,
      paramsGet => 321,
      paramsPut => 321,
      resize => 12,
      return => 107,
      shiftRight => 68,
      shiftUp => 300,
      subtract => 641,
    };
     }
    

## FindResult\_key($f)

Get key from find result..

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
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K);                                                         # Insert a new node
        Tally 0;
       } $a, q(aaa);
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
    
        my $k = FindResult_key($find);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        Out $k;
        my $f = Find($t, $k);                                                       # Find
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      is_deeply $e->tallyCount,  23612;                                             # Insertion instruction counts
    
      #say STDERR "AAAA
  ", dump($e->tallyCounts->{1});
    
      is_deeply $e->tallyCounts->{1}, {
      add => 860,
      array => 607,
      arrayIndex => 7,
      call => 107,
      dec => 7,
      free => 360,
      inc => 1044,
      jEq => 631,
      jGe => 1660,
      jLe => 461,
      jLt => 565,
      jmp => 1436,
      jNe => 1088,
      mov => 12314,
      not => 695,
      paramsGet => 321,
      paramsPut => 321,
      resize => 12,
      return => 107,
      shiftRight => 68,
      shiftUp => 300,
      subtract => 641,
    };
     }
    

## FindResult\_cmp($f)

Get comparison from find result..

       Parameter  Description
    1  $f         Find result

**Example:**

    if (1)                                                                           
     {Start 1;
      my $f = FindResult_new(1, 2, 3, 4);
      my $n = FindResult_node($f);
      my $k = FindResult_key($f);
    
      my $c = FindResult_cmp($f);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $i = FindResult_index($f);
      Out $_ for $n, $c, $k, $i;
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out,    [1, 3, 2, 4];
      is_deeply $e->memory, {1=>[1, 3, 2, 4]};
     }
    

## FindResult\_data($f)

Get data field from find results..

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
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K);                                                         # Insert a new node
        Tally 0;
       } $a, q(aaa);
    
      Iterate                                                                       # Iterate tree
       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        my $f = Find($t, $k);                                                       # Find
    
        my $d = FindResult_data($f);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      is_deeply $e->tallyCount,  23612;                                             # Insertion instruction counts
    
      #say STDERR "AAAA
  ", dump($e->tallyCounts->{1});
    
      is_deeply $e->tallyCounts->{1}, {
      add => 860,
      array => 607,
      arrayIndex => 7,
      call => 107,
      dec => 7,
      free => 360,
      inc => 1044,
      jEq => 631,
      jGe => 1660,
      jLe => 461,
      jLt => 565,
      jmp => 1436,
      jNe => 1088,
      mov => 12314,
      not => 695,
      paramsGet => 321,
      paramsPut => 321,
      resize => 12,
      return => 107,
      shiftRight => 68,
      shiftUp => 300,
      subtract => 641,
    };
     }
    

# Find

Find a key in a tree.

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
    
      for my $i(1..$N)
       {Insert($t, $i, my $d = $i+$i);
        for my $j(1..$i)
    
         {AssertEq $j+$j, FindResult_data(Find($t, $j));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

         }
    
        AssertNe FindResult_found, FindResult_cmp(Find($t, 0));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
        AssertNe FindResult_found, FindResult_cmp(Find($t, $i+1));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       }
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [];
     }
    
    if (1)                                                                            
     {my $W = 3; my $N = 66; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);
    
      for my $i(1..$N)
       {my $k = $r[$i-1]; my $d = $k*2;
        Insert($t, $k, $d);
    
        AssertEq $d, FindResult_data(Find($t, $k));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       }
    
      my $e = Execute(suppressOutput=>1);
      is_deeply printTreeKeys($e->memory), <<END;
                                                                                            30
                                         13                                                                                           44                               55
                        7                                     20             25                                  37                                     50                               61
         2     4              9    11          15    17                23          27                33    35          39    41                47             52                58             63    65
      1     3     5  6     8    10    12    14    16    18 19    21 22    24    26    28 29    31 32    34    36    38    40    42 43    45 46    48 49    51    53 54    56 57    59 60    62    64    66
    END
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
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K);                                                         # Insert a new node
        Tally 0;
       } $a, q(aaa);
    
      Iterate                                                                       # Iterate tree
    
       {my ($find) = @_;                                                            # Find result  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $k = FindResult_key($find);
        Out $k;
    
        my $f = Find($t, $k);                                                       # Find  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      is_deeply $e->tallyCount,  23612;                                             # Insertion instruction counts
    
      #say STDERR "AAAA
  ", dump($e->tallyCounts->{1});
    
      is_deeply $e->tallyCounts->{1}, {
      add => 860,
      array => 607,
      arrayIndex => 7,
      call => 107,
      dec => 7,
      free => 360,
      inc => 1044,
      jEq => 631,
      jGe => 1660,
      jLe => 461,
      jLt => 565,
      jmp => 1436,
      jNe => 1088,
      mov => 12314,
      not => 695,
      paramsGet => 321,
      paramsPut => 321,
      resize => 12,
      return => 107,
      shiftRight => 68,
      shiftUp => 300,
      subtract => 641,
    };
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
      1 => bless([1, 1, 3, 2], "Tree"),
      2 => bless([1, 1, 0, 1, 3, 4, 0], "Node"),
      3 => bless([1], "Keys"),
      4 => bless([11], "Data")};
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, 1, 11);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      Insert($t, 2, 22);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {
      1 => bless([2, 1, 3, 2], "Tree"),
      2 => bless([2, 1, 0, 1, 3, 4, 0], "Node"),
      3 => bless([1, 2], "Keys"),
      4 => bless([11, 22], "Data")};
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {
      1 => bless([3, 1, 3, 2], "Tree"),
      2 => bless([3, 1, 0, 1, 3, 4, 0], "Node"),
      3 => bless([1, 2, 3], "Keys"),
      4 => bless([11, 22, 33], "Data")}
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {
      1  => bless([4, 3, 3, 2], "Tree"),
      2  => bless([1, 1, 0, 1, 3, 4, 11], "Node"),
      3  => bless([2], "Keys"),
      4  => bless([22], "Data"),
      5  => bless([1, 2, 2, 1, 6, 7, 0], "Node"),
      6  => bless([1], "Keys"),
      7  => bless([11], "Data"),
      8  => bless([2, 3, 2, 1, 9, 10, 0], "Node"),
      9  => bless([3, 4], "Keys"),
      10 => bless([33, 44], "Data"),
      11 => bless([5, 8], "Down"),
    };
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..5;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {
      1  => bless([5, 5, 3, 2], "Tree"),
      2  => bless([2, 1, 0, 1, 3, 4, 11], "Node"),
      3  => bless([2, 4], "Keys"),
      4  => bless([22, 44], "Data"),
      5  => bless([1, 2, 2, 1, 6, 7, 0], "Node"),
      6  => bless([1], "Keys"),
      7  => bless([11], "Data"),
      11 => bless([5, 14, 17], "Down"),
      14 => bless([1, 4, 2, 1, 15, 16, 0], "Node"),
      15 => bless([3], "Keys"),
      16 => bless([33], "Data"),
      17 => bless([1, 5, 2, 1, 18, 19, 0], "Node"),
      18 => bless([5], "Keys"),
      19 => bless([55], "Data")}
     }
    
    if (1)                                                                          
     {Start 1;
      my $t = New(3);
    
      Insert($t, $_, "$_$_") for 1..6;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->memory, {
      1  => bless([6, 5, 3, 2], "Tree"),
      2  => bless([2, 1, 0, 1, 3, 4, 11], "Node"),
      3  => bless([2, 4], "Keys"),
      4  => bless([22, 44], "Data"),
      5  => bless([1, 2, 2, 1, 6, 7, 0], "Node"),
      6  => bless([1], "Keys"),
      7  => bless([11], "Data"),
      11 => bless([5, 14, 17], "Down"),
      14 => bless([1, 4, 2, 1, 15, 16, 0], "Node"),
      15 => bless([3], "Keys"),
      16 => bless([33], "Data"),
      17 => bless([2, 5, 2, 1, 18, 19, 0], "Node"),
      18 => bless([5, 6], "Keys"),
      19 => bless([55, 66], "Data")};
     }
    
    if (1)                                                                            
     {my $W = 3; my $N = 66;
    
      Start 1;
      my $t = New($W);
    
      for my $i(1..$N)
    
       {Insert($t, $i, my $d = $i+$i);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        for my $j(1..$i)
         {AssertEq $j+$j, FindResult_data(Find($t, $j));
         }
        AssertNe FindResult_found, FindResult_cmp(Find($t, 0));
        AssertNe FindResult_found, FindResult_cmp(Find($t, $i+1));
       }
    
      my $e = Execute(suppressOutput=>1);
      is_deeply $e->out, [];
     }
    
    if (1)                                                                            
     {my $W = 3; my $N = 66; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);
    
      for my $i(1..$N)
       {my $k = $r[$i-1]; my $d = $k*2;
    
        Insert($t, $k, $d);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

        AssertEq $d, FindResult_data(Find($t, $k));
       }
    
      my $e = Execute(suppressOutput=>1);
      is_deeply printTreeKeys($e->memory), <<END;
                                                                                            30
                                         13                                                                                           44                               55
                        7                                     20             25                                  37                                     50                               61
         2     4              9    11          15    17                23          27                33    35          39    41                47             52                58             63    65
      1     3     5  6     8    10    12    14    16    18 19    21 22    24    26    28 29    31 32    34    36    38    40    42 43    45 46    48 49    51    53 54    56 57    59 60    62    64    66
    END
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
    
      ForArray                                                                      # Create tree
       {my ($i, $k) = @_;
        my $n = Keys($t);
        AssertEq $n, $i;                                                            # Check tree size
        my $K = Add $k, $k;
        Tally 1;
        Insert($t, $k, $K);                                                         # Insert a new node
        Tally 0;
       } $a, q(aaa);
    
    
      Iterate                                                                       # Iterate tree  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       {my ($find) = @_;                                                            # Find result
        my $k = FindResult_key($find);
        Out $k;
        my $f = Find($t, $k);                                                       # Find
        my $d = FindResult_data($f);
        my $K = Add $k, $k;
        AssertEq $K, $d;                                                            # Check result
       } $t;
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply $e->out, [1..$N];                                                   # Expected sequence
    
      is_deeply $e->tallyCount,  23612;                                             # Insertion instruction counts
    
      #say STDERR "AAAA
  ", dump($e->tallyCounts->{1});
    
      is_deeply $e->tallyCounts->{1}, {
      add => 860,
      array => 607,
      arrayIndex => 7,
      call => 107,
      dec => 7,
      free => 360,
      inc => 1044,
      jEq => 631,
      jGe => 1660,
      jLe => 461,
      jLt => 565,
      jmp => 1436,
      jNe => 1088,
      mov => 12314,
      not => 695,
      paramsGet => 321,
      paramsPut => 321,
      resize => 12,
      return => 107,
      shiftRight => 68,
      shiftUp => 300,
      subtract => 641,
    };
     }
    

# Print

Print trees horizontally.

## printTreeKeys($m)

Print the keys held in a tree.

       Parameter  Description
    1  $m         Memory

**Example:**

    if (1)                                                                           
     {my $W = 7; my $N = 165; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);
    
      for my $i(0..$N-1)
       {Insert($t, $r[$i], $r[$i]);
       }
    
      my $e = Execute(suppressOutput=>1);
    
      is_deeply printTreeKeys($e->memory),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                printTreeData($e->memory);
     }
    

## printTreeData($m)

Print the data held in a tree.

       Parameter  Description
    1  $m         Memory

**Example:**

    if (1)                                                                           
     {my $W = 7; my $N = 165; my @r = randomArray $N;
    
      Start 1;
      my $t = New($W);
    
      for my $i(0..$N-1)
       {Insert($t, $r[$i], $r[$i]);
       }
    
      my $e = Execute(suppressOutput=>1);
      is_deeply printTreeKeys($e->memory),
    
                printTreeData($e->memory);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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

4 [FindResult\_key](#findresult_key) - Get key from find result.

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
