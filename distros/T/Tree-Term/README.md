# Create a parse tree from an array of terms representing an expression.

![Test](https://github.com/philiprbrenan/TreeTerm/workflows/Test/badge.svg)

Parse the expression:

```
  v_sub a_is v_array as
    v1 d_== v2 a_then v3 d_plus v4 a_else
    v5 d_== v6 a_then v7 d_minus v8 a_else
    v9 d_times b v10 a_+ v11 B

```

to get:

```
     is
 sub          as
        array             then
                    ==                    else
                 v1    v2         plus                  then
                               v3      v4         ==                     else
                                               v5    v6         minus            times
                                                             v7       v8      v9           +
                                                                                       v10   v11
```

For full documentation see: [CPAN](https://metacpan.org/pod/Tree::Term)


For documentation see: [CPAN](https://metacpan.org/pod/Tree::Term)