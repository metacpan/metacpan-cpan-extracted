## Benchmarks

These are my results from running the benchmark.pl script with various parameters.
It compares Tree::RB, Tree::RB::XS, Tree::AVL, and AVLTree, and also Perl's sort
for an array of keys and for a hashref of keys for context.

To summarize the findings, Tree::RB::XS is by far the fastest tree module and even
30%-40% faster than building a hash and sorting its keys, as long as the tree is using
an internal comparison function and not calling back to a Perl coderef.  When calling
back to a Perl coderef for each comparison, Tree::RB::XS is only about 12% faster than
AVLTree.

### Contenders:

  - **Tree::RB**
    This is a Red/Black implementation in Pure Perl, using blessed arrayrefs.
    It's pretty fast, for pure-perl.  (though I think it could be faster if it
    used fewer method calls and had built-in comparison options instead of
    always using an anonymous sub)

  - **Tree::AVL**
    This is an AVL tree implemented in pure perl, but it doesn't use any Perl performance
    tricks, and is a bit slow as a result.  Its node design assumes that the node is both
    the key and the value unless you provide callbacks that fetch the key and value out of
    the node.

  - **AVLTree**
    This is a XS wrapper around a C library.  But, it also uses an anonymous sub for
    comparing keys.

  - **Tree::RB::XS**
    My module uses built-in key comparison functions that can be selected by ID.  As a result,
    these benchmarks have to be re-run for each type of data that might be loaded into the
    key.  The "Obj" comparison shows Tree::RB::XS performance when calling a perl coderef
    for each key comparison, which is more fair to the other modules.

### Key Types

Since Tree::RB::XS has built-in key comparison functions, I re-run the benchmark with each
potential type of key.

  - **int**
    This uses the sequence of 0..N shuffled into a random order.

  - **float**
    This uses N completely random floating values.

  - **shortstr**
    Short strings are more likely to conflict than long ones, and also faster to copy.

  - **longstr**
    Long strings are more expensive to copy and allocate nodes for in Tree::RB::XS

  - **commonstr**
    Strings with many prefix characters in common, which take longer to compare

  - **ustr**
    Strings containing higher-than-256 Unicode codepoints

  - **obj**
    Keys that are structured data and can't be optimized by Tree::RB::XS.

## "Get Min Value"

This test builds a collection of nodes, starts timing, adds all the nodes to the tree,
then looks up the minimum value, then records the elapsed time.  For comparison
to plain perl, I added tests named 'sort_keys' that builds a hashref of the key/value pairs
and then sorts the keys and then gets the value from the hashref.  For extra reference, I
added a test named 'sort' that shows what it wold be just to sort the keys from an array.

The benchmark was giving a large amount of deviation when I ran these sequentially in the same
Perl process (probably because of one algorithm's effects on the memory pool) so I have it
shell out to a new Perl process to run each module's test.
The benchmark script runs the test **I** times, the test runs **R** loops of the algorithm,
and the algorithm operates on **N** nodes.

### 1M nodes, one iteration per run, for one run

```
Int: 1000000 data items, 1 outer iterations, 1 inner iterations
           s/iter  tree_avl    tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl     29.7        --       -56%      -86%      -95%       -97%       -99%
tree_rb      13.2      125%         --      -69%      -88%       -92%       -98%
avltree      4.08      627%       223%        --      -62%       -75%       -93%
sort_keys    1.55     1814%       750%      163%        --       -34%       -81%
tree_rb_xs   1.02     2808%      1192%      300%       52%         --       -71%
sort        0.300     9787%      4293%     1260%      417%       240%         --

Float: 1000000 data items, 1 outer iterations, 1 inner iterations
           s/iter  tree_avl    tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl     32.4        --       -56%      -80%      -93%       -97%       -98%
tree_rb      14.2      129%         --      -53%      -84%       -93%       -96%
avltree      6.61      391%       114%        --      -67%       -85%       -92%
sort_keys    2.20     1375%       543%      200%        --       -56%       -75%
tree_rb_xs  0.960     3279%      1374%      589%      129%         --       -44%
sort        0.540     5907%      2520%     1124%      307%        78%         --

Shortstr: 1000000 data items, 1 outer iterations, 1 inner iterations
           s/iter  tree_avl    tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl     36.2        --       -69%      -71%      -94%       -96%       -97%
tree_rb      11.3      220%         --       -7%      -81%       -88%       -91%
avltree      10.5      244%         8%        --      -79%       -87%       -91%
sort_keys    2.19     1552%       416%      379%        --       -37%       -55%
tree_rb_xs   1.37     2540%       724%      666%       60%         --       -28%
sort        0.990     3554%      1040%      961%      121%        38%         --

Longstr: 1000000 data items, 1 outer iterations, 1 inner iterations
           s/iter  tree_avl    avltree   tree_rb sort_keys tree_rb_xs       sort
tree_avl     38.1        --       -63%      -69%      -90%       -94%       -96%
avltree      14.1      171%         --      -15%      -72%       -85%       -90%
tree_rb      11.9      221%        18%        --      -67%       -82%       -88%
sort_keys    3.95      866%       256%      201%        --       -45%       -64%
tree_rb_xs   2.17     1658%       548%      448%       82%         --       -35%
sort         1.42     2587%       890%      737%      178%        53%         --

Commonstr: 1000000 data items, 1 outer iterations, 1 inner iterations
           s/iter  tree_avl    tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl     36.7        --       -68%      -71%      -93%       -96%       -97%
tree_rb      11.6      217%         --       -7%      -79%       -86%       -90%
avltree      10.8      240%         7%        --      -78%       -85%       -89%
sort_keys    2.39     1434%       385%      351%        --       -32%       -51%
tree_rb_xs   1.62     2163%       615%      565%       48%         --       -28%
sort         1.16     3060%       898%      829%      106%        40%         --

Ustr: 1000000 data items, 1 outer iterations, 1 inner iterations
           s/iter  tree_avl    tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl     36.4        --       -68%      -70%      -93%       -96%       -97%
tree_rb      11.5      215%         --       -5%      -79%       -86%       -90%
avltree      10.9      233%         6%        --      -78%       -86%       -90%
sort_keys    2.37     1436%       387%      361%        --       -34%       -52%
tree_rb_xs   1.56     2233%       640%      601%       52%         --       -28%
sort         1.13     3121%       921%      867%      110%        38%         --

Obj: 1000000 data items, 1 outer iterations, 1 inner iterations
           s/iter  tree_avl    tree_rb   avltree tree_rb_xs       sort sort_keys
tree_avl     35.4        --       -48%      -78%       -80%       -92%      -93%
tree_rb      18.3       93%         --      -57%       -62%       -85%      -86%
avltree      7.84      352%       134%        --       -10%       -66%      -68%
tree_rb_xs   7.03      404%       161%       12%         --       -62%      -64%
sort         2.66     1231%       589%      195%       164%         --       -6%
sort_keys    2.50     1316%       633%      214%       181%         6%        --
```

### 100K nodes, one iteration per run, averaged over 10 runs

```
Int: 100000 data items, 10 outer iterations, 1 inner iterations
              Rate  tree_avl   tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl   0.421/s        --      -56%      -87%      -96%       -98%       -99%
tree_rb    0.948/s      125%        --      -72%      -92%       -95%       -98%
avltree     3.37/s      700%      255%        --      -71%       -84%       -94%
sort_keys   11.5/s     2630%     1113%      241%        --       -44%       -78%
tree_rb_xs  20.4/s     4747%     2053%      506%       78%         --       -61%
sort        52.6/s    12400%     5453%     1463%      358%       158%         --

Float: 100000 data items, 10 outer iterations, 1 inner iterations
              Rate  tree_avl   tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl   0.386/s        --      -58%      -81%      -94%       -98%       -99%
tree_rb    0.913/s      137%        --      -55%      -85%       -96%       -97%
avltree     2.03/s      426%      122%        --      -67%       -90%       -94%
sort_keys   6.13/s     1490%      572%      202%        --       -70%       -82%
tree_rb_xs  20.4/s     5188%     2135%      906%      233%         --       -39%
sort        33.3/s     8537%     3550%     1543%      443%        63%         --

Shortstr: 100000 data items, 10 outer iterations, 1 inner iterations
              Rate  tree_avl   tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl   0.356/s        --      -69%      -72%      -96%       -97%       -98%
tree_rb     1.16/s      227%        --       -7%      -88%       -91%       -94%
avltree     1.25/s      251%        7%        --      -87%       -90%       -94%
sort_keys   9.62/s     2603%      727%      670%        --       -23%       -52%
tree_rb_xs  12.5/s     3414%      975%      901%       30%         --       -37%
sort        20.0/s     5522%     1620%     1502%      108%        60%         --

Longstr: 100000 data items, 10 outer iterations, 1 inner iterations
              Rate  tree_avl   avltree   tree_rb sort_keys tree_rb_xs       sort
tree_avl   0.333/s        --      -65%      -70%      -90%       -95%       -97%
avltree    0.948/s      185%        --      -14%      -73%       -86%       -92%
tree_rb     1.10/s      231%       16%        --      -68%       -84%       -91%
sort_keys   3.47/s      943%      266%      215%        --       -49%       -72%
tree_rb_xs  6.76/s     1929%      613%      514%       95%         --       -45%
sort        12.2/s     3562%     1187%     1007%      251%        80%         --

Commonstr: 100000 data items, 10 outer iterations, 1 inner iterations
              Rate  tree_avl   tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl   0.350/s        --      -69%      -71%      -96%       -97%       -98%
tree_rb     1.15/s      228%        --       -6%      -87%       -90%       -93%
avltree     1.22/s      249%        6%        --      -86%       -89%       -93%
sort_keys   8.55/s     2343%      645%      600%        --       -23%       -49%
tree_rb_xs  11.1/s     3076%      869%      810%       30%         --       -33%
sort        16.7/s     4663%     1353%     1265%       95%        50%         --

Ustr: 100000 data items, 10 outer iterations, 1 inner iterations
              Rate  tree_avl   tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl   0.351/s        --      -69%      -71%      -96%       -97%       -98%
tree_rb     1.13/s      222%        --       -8%      -86%       -90%       -93%
avltree     1.23/s      250%        9%        --      -85%       -89%       -93%
sort_keys   8.33/s     2277%      638%      579%        --       -26%       -51%
tree_rb_xs  11.2/s     3106%      896%      816%       35%         --       -34%
sort        16.9/s     4736%     1402%     1281%      103%        51%         --

Obj: 100000 data items, 10 outer iterations, 1 inner iterations
              Rate  tree_avl   tree_rb   avltree tree_rb_xs       sort sort_keys
tree_avl   0.375/s        --      -49%      -81%       -84%       -95%      -95%
tree_rb    0.729/s       94%        --      -64%       -69%       -90%      -91%
avltree     2.02/s      439%      177%        --       -15%       -72%      -74%
tree_rb_xs  2.38/s      533%      226%       18%         --       -67%      -70%
sort        7.19/s     1818%      886%      256%       203%         --       -8%
sort_keys   7.81/s     1983%      971%      287%       229%         9%        --
```

### 100K nodes, 10 iterations per run, for one run

```
Int: 100000 data items, 1 outer iterations, 10 inner iterations
              Rate  tree_avl   tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl   0.378/s        --      -55%      -88%      -97%       -98%       -99%
tree_rb    0.839/s      122%        --      -74%      -93%       -95%       -98%
avltree     3.24/s      756%      286%        --      -73%       -82%       -94%
sort_keys   11.9/s     3049%     1319%      268%        --       -32%       -77%
tree_rb_xs  17.5/s     4540%     1991%      442%       47%         --       -67%
sort        52.6/s    13821%     6174%     1526%      342%       200%         --

Float: 100000 data items, 1 outer iterations, 10 inner iterations
              Rate  tree_avl   tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl   0.337/s        --      -58%      -82%      -95%       -98%       -99%
tree_rb    0.806/s      140%        --      -57%      -88%       -95%       -98%
avltree     1.89/s      461%      134%        --      -71%       -89%       -95%
sort_keys   6.54/s     1841%      710%      246%        --       -63%       -81%
tree_rb_xs  17.5/s     5111%     2075%      828%      168%         --       -49%
sort        34.5/s    10141%     4176%     1724%      428%        97%         --

Shortstr: 100000 data items, 1 outer iterations, 10 inner iterations
              Rate  tree_avl   tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl   0.320/s        --      -68%      -74%      -97%       -97%       -98%
tree_rb    0.999/s      213%        --      -18%      -89%       -91%       -94%
avltree     1.23/s      283%       23%        --      -87%       -89%       -93%
sort_keys   9.26/s     2797%      827%      656%        --       -19%       -48%
tree_rb_xs  11.4/s     3456%     1037%      827%       23%         --       -36%
sort        17.9/s     5487%     1687%     1357%       93%        57%         --

Longstr: 100000 data items, 1 outer iterations, 10 inner iterations
             s/iter  tree_avl   avltree   tree_rb sort_keys tree_rb_xs      sort
tree_avl       3.37        --      -68%      -69%      -92%       -96%      -98%
avltree        1.09      209%        --       -3%      -74%       -87%      -92%
tree_rb        1.06      219%        3%        --      -73%       -87%      -92%
sort_keys     0.282     1096%      288%      275%        --       -50%      -70%
tree_rb_xs    0.141     2293%      675%      650%      100%         --      -40%
sort       8.40e-02     3917%     1201%     1158%      236%        68%        --

Commonstr: 100000 data items, 1 outer iterations, 10 inner iterations
              Rate  tree_avl   tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl   0.316/s        --      -68%      -73%      -96%       -97%       -98%
tree_rb    0.978/s      209%        --      -17%      -87%       -91%       -94%
avltree     1.18/s      272%       20%        --      -85%       -89%       -92%
sort_keys   7.69/s     2333%      687%      554%        --       -28%       -51%
tree_rb_xs  10.8/s     3301%     1000%      814%       40%         --       -31%
sort        15.6/s     4842%     1498%     1228%      103%        45%         --

Ustr: 100000 data items, 1 outer iterations, 10 inner iterations
              Rate  tree_avl   tree_rb   avltree sort_keys tree_rb_xs       sort
tree_avl   0.322/s        --      -67%      -73%      -96%       -97%       -98%
tree_rb    0.972/s      202%        --      -18%      -87%       -91%       -94%
avltree     1.18/s      266%       21%        --      -84%       -89%       -93%
sort_keys   7.52/s     2234%      674%      537%        --       -31%       -55%
tree_rb_xs  10.9/s     3274%     1018%      821%       45%         --       -35%
sort        16.7/s     5073%     1615%     1312%      122%        53%         --

Obj: 100000 data items, 1 outer iterations, 10 inner iterations
              Rate  tree_avl   tree_rb   avltree tree_rb_xs       sort sort_keys
tree_avl   0.338/s        --      -49%      -83%       -85%       -95%      -95%
tree_rb    0.665/s       97%        --      -67%       -71%       -91%      -91%
avltree     2.02/s      499%      204%        --       -10%       -71%      -72%
tree_rb_xs  2.26/s      567%      239%       12%         --       -68%      -69%
sort        7.09/s     1997%      966%      250%       214%         --       -4%
sort_keys   7.35/s     2074%     1005%      263%       226%         4%        --
```

### 10M nodes, 1 iteration per run, 2 runs

```
Int: 10000000 data items, 2 outer iterations, 1 inner iterations
           s/iter    tree_rb    avltree  sort_keys tree_rb_xs       sort
tree_rb       175         --       -66%       -89%       -91%       -98%
avltree      58.8       197%         --       -68%       -73%       -94%
sort_keys    19.0       819%       210%         --       -18%       -81%
tree_rb_xs   15.6      1016%       276%        21%         --       -76%
sort         3.68      4642%      1498%       416%       325%         --

Float: 10000000 data items, 2 outer iterations, 1 inner iterations
           s/iter    tree_rb    avltree  sort_keys tree_rb_xs       sort
tree_rb       187         --       -60%       -88%       -92%       -96%
avltree      74.9       149%         --       -69%       -80%       -91%
sort_keys    23.2       706%       223%         --       -36%       -71%
tree_rb_xs   14.7      1167%       409%        57%         --       -54%
sort         6.79      2650%      1004%       241%       117%         --

Shortstr: 10000000 data items, 2 outer iterations, 1 inner iterations
           s/iter    tree_rb    avltree  sort_keys tree_rb_xs       sort
tree_rb       142         --       -25%       -85%       -89%       -94%
avltree       107        33%         --       -80%       -85%       -91%
sort_keys    21.6       557%       396%         --       -28%       -58%
tree_rb_xs   15.6       809%       586%        38%         --       -42%
sort         9.13      1458%      1075%       137%        71%         --

Commonstr: 10000000 data items, 2 outer iterations, 1 inner iterations
           s/iter    tree_rb    avltree  sort_keys tree_rb_xs       sort
tree_rb       146         --       -26%       -85%       -88%       -93%
avltree       108        35%         --       -79%       -84%       -91%
sort_keys    22.5       548%       379%         --       -25%       -58%
tree_rb_xs   17.0       761%       537%        33%         --       -44%
sort         9.51      1435%      1036%       137%        78%         --

Ustr: 10000000 data items, 2 outer iterations, 1 inner iterations
           s/iter    tree_rb    avltree  sort_keys tree_rb_xs       sort
tree_rb       143         --       -23%       -84%       -88%       -93%
avltree       110        30%         --       -79%       -85%       -91%
sort_keys    22.9       527%       383%         --       -27%       -57%
tree_rb_xs   16.6       765%       566%        38%         --       -41%
sort         9.73      1373%      1034%       135%        70%         --

Obj: 10000000 data items, 2 outer iterations, 1 inner iterations
           s/iter    tree_rb    avltree tree_rb_xs       sort
tree_rb       249         --       -52%       -55%       -83%
avltree       118       110%         --        -6%       -65%
tree_rb_xs    111       123%         6%         --       -62%
sort         41.9       494%       183%       166%         --
```
