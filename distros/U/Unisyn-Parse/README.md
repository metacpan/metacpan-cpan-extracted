# Unisyn expressions.

![Test](https://github.com/philiprbrenan/UnisynParse/workflows/Test/badge.svg)

Once there were many different character sets that were unified by [Unicode](https://en.wikipedia.org/wiki/Unicode). 
Today we have many different programming languages, each with a slightly
different syntax from all the others. The multiplicity of such syntaxes imposes
unnecessary burdens on users and language designers.  [UniSyn](https://github.com/philiprbrenan/UnisynParse) is proposed as a
common syntax that can be used by many different programming languages.

Advantages of having one uniform language syntax:

- less of a burden on users to recall which of the many syntax schemes in
current use is the relevant one for the programming language they are currently
programming in.  Rather like having all your electrical appliances work from
the same voltage electricity rather than different voltages.

- programming effort can be applied globally to optimize the parsing [process](https://en.wikipedia.org/wiki/Process_management_(computing)) to
produce the fastest possible parser with the best diagnostics.

## Special features

- Expressions in Unisyn can be parsed in situ - it is not necessary to reparse
the entire source [file](https://en.wikipedia.org/wiki/Computer_file) to syntax check changes made to the [file](https://en.wikipedia.org/wiki/Computer_file). Instead
changes can be checked locally at the point of modification.

- Expressions in [UniSyn](https://github.com/philiprbrenan/UnisynParse) can be parsed using [SIMD](https://www.officedaytime.com/simd512e/) instructions to make parsing
faster than otherwise.

## Dyadic operator priorities
 [UniSyn](https://github.com/philiprbrenan/UnisynParse) has only three levels of dyadic operator priority which makes it easier
to learn. Conversely: [Perl](http://www.perl.org/) has 25 levels of operator priority.  Can we really
expect users to learn such a long list?

Even three levels of priority are enough to [parse](https://en.wikipedia.org/wiki/Parsing) subroutine declarations, for
loops and if statements with nested expressions:

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

The priority of a dyadic operator is determined by the [Unicode Mathematical Alphanumeric Symbols](https://en.wikipedia.org/wiki/Mathematical_Alphanumeric_Symbols) that is used to
encode it.

The new operators provided by the [Unicode](https://en.wikipedia.org/wiki/Unicode) standard allows us to offer users a
wider range of operators and brackets with which to express their intentions
clearly within the three levels of operator precedence provided.

## Other languages
 [Lisp](https://en.wikipedia.org/wiki/Lisp), [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)), [Tcl](https://en.wikipedia.org/wiki/Tcl) are well known, successful languages that use generic syntaxes.


For documentation see: [CPAN](https://metacpan.org/pod/Unisyn::Parse)