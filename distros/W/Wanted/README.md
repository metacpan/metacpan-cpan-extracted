# NAME

Wanted - Extended caller context detection

# SYNOPSIS

    use Wanted;
    sub foo :lvalue
    {
        if ( want( qw'LVALUE ASSIGN' ) )
        {
            print "We have been assigned ", want('ASSIGN');
            lnoreturn;
        }
        elsif( want('LIST') )
        {
            rreturn (1, 2, 3);
        }
        elsif( want('BOOL') )
        {
            rreturn 0;
        }
        elsif( want(qw'SCALAR !REF') )
        {
            rreturn 23;
        }
        elsif( want('HASH') )
        {
            rreturn { foo => 17, bar => 23 };
        }
        # You have to put this at the end to keep the compiler happy
        return;
    }

    foo() = 23;  # Assign context
    @x = foo();  # List context
    if( foo() )  # Boolean context
    {
        print( "Not reached\n" );
    }

Also works in threads, where the context is set at thread creation.

    require threads;
    # In scalar context
    my $thr = threads->create(sub
    {
        return( want('SCALAR') );
    });
    my $is_scalar = $thr->join; # true

    # or
    my $thr = threads->create({ context => 'scalar' }, sub
    {
        return( want('SCALAR') );
    });
    my $is_scalar = $thr->join; # true

    my( $thr ) = threads->create(sub
    {
        return( want('LIST') );
    });
    my @list_result = $thr->join;
    # $list_result[0] is true

    # or
    my $thr = threads->create({ context => 'list' }, sub
    {
        return( want('LIST') );
    });
    my @list_result = $thr->join;
    # $list_result[0] is true

    # Force the context by being explicit:
    my $thr = threads->create({ context => 'void' }, sub
    {
        return( want('VOID') ? 1 : 0 );
    });
    my $is_void = $thr_void->join; # undef

# VERSION

    v0.1.0

# DESCRIPTION

This XS module generalises the mechanism of the [wantarray](https://metacpan.org/pod/perlfunc#wantarray) function, allowing a function to determine in detail how its return value is going to be used.

It is a fork from the module [Want](https://metacpan.org/pod/Want), by Robin Houston, that is not updated anymore since 2016, and that throws a segmentation fault when called from the last line of a thread, or from a tie method, or from the last line of a mod\_perl handler, when there is a lack of context.

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## Top-level contexts:

The three kinds of top-level context are well known:

- **VOID**

    The return value is not being used in any way. It could be an entire statement like `foo();`, or the last component of a compound statement which is itself in void context, such as `$test || foo();`n. Be warned that the last statement of a subroutine will be in whatever context the subroutine was called in, because the result is implicitly returned.

- **SCALAR**

    The return value is being treated as a scalar value of some sort:

        my $x = foo();
        $y += foo();
        print "123" x foo();
        print scalar foo();
        warn foo()->{23};
        # ...etc...

- **LIST**

    The return value is treated as a list of values:

        my @x = foo();
        my ($x) = foo();
        () = foo();           # even though the results are discarded
        print foo();
        bar(foo());           # unless the bar subroutine has a prototype
        print @hash{foo()};   # (hash slice)
        # ...etc...

## Lvalue subroutines:

The introduction of **lvalue subroutines** in Perl 5.6 has created a new type of contextual information, which is independent of those listed above. When an lvalue subroutine is called, it can either be called in the ordinary way (so that its result is treated as an ordinary value, an **rvalue**); or else it can be called so that its result is considered updatable, an **lvalue**.

These rather arcane terms (lvalue and rvalue) are easier to remember if you know why they are so called. If you consider a simple assignment statement `left = right`, then the **l**eft-hand side is an **l**value and the **r**ight-hand side is an **r**value.

So (for lvalue subroutines only) there are two new types of context:

- **RVALUE**

    The caller is definitely not trying to assign to the result:

        foo();
        my $x = foo();
        # ...etc...

    If the sub is declared without the `:lvalue` attribute, then it will _always_ be in RVALUE context.

    If you need to return values from an lvalue subroutine in RVALUE context, you should use the `rreturn` function rather than an ordinary `return`. Otherwise you will probably get a compile-time error in perl 5.6.1 and later.

- **LVALUE**

    Either the caller is directly assigning to the result of the sub call:

        foo() = $x;
        foo() = (1, 1, 2, 3, 5, 8);

    or the caller is making a reference to the result, which might be assigned to later:

          my $ref = \(foo());   # Could now have: $$ref = 99;
        
          # Note that this example imposes LIST context on the sub call.
          # So we are taking a reference to the first element to be
          # returned _in list context_.
          # If we want to call the function in scalar context, we can
          # do it like this:
          my $ref = \(scalar foo());

    or else the result of the function call is being used as part of the argument list for _another_ function call:

        bar(foo());   # Will *always* call foo in lvalue context,
                      # (provided that foo is an C<:lvalue> sub)
                      # regardless of what bar actually does.

    The reason for this last case is that bar might be a sub which modifies its arguments. They are rare in contemporary Perl code, but perfectly possible:

        sub bar {
            $_[0] = 23;
        }

    (This is really a throwback to Perl 4, which did not support explicit references.)

## Assignment context:

The commonest use of lvalue subroutines is with the assignment statement:

    size() = 12;
    (list()) = (1..10);

A useful motto to remember when thinking about assignment statements is _context comes from the left_. Consider code like this:

    my ($x, $y, $z);
    sub list () :lvalue { ($x, $y, $z) }
    list = (1, 2, 3);
    print "\$x = $x; \$y = $y; \$z = $z\n";

This prints `$x = ; $y = ; $z = 3`, which may not be what you were expecting. The reason is that the assignment is in scalar context, so the comma operator is in scalar context too, and discards all values but the last. You can fix it by writing `(list) = (1,2,3);` instead.

If your lvalue subroutine is used on the left of an assignment statement, it is in **ASSIGN** context. If ASSIGN is the only argument to `want()`, then it returns a reference to an array of the value(s) of the right-hand side.

In this case, you should return with the `lnoreturn` function, rather than an ordinary [return](https://metacpan.org/pod/perlfunc#return). 

This makes it very easy to write lvalue subroutines which do clever things:

       use Wanted;
       use strict;
       sub backstr :lvalue {
           if (want(qw'LVALUE ASSIGN')) {
               my ($a) = want('ASSIGN');
               $_[0] = reverse $a;
               lnoreturn;
           }
           elsif (want('RVALUE')) {
               rreturn scalar reverse $_[0];
           }
           else {
               carp("Not in ASSIGN context");
           }
           return
       }
    
       print "foo -> ", backstr("foo"), "\n";        # foo -> oof
       backstr(my $robin) = "nibor";
       print "\$robin is now $robin\n";              # $robin is now robin

Notice that you need to put a (meaningless) return statement at the end of the function, otherwise you will get the
error _Can't modify non-lvalue subroutine call in lvalue subroutine return_.

The only way to write that `backstr` function without using Want is to return a tied variable which is tied to a custom class.

## Reference context:

Sometimes in scalar context the caller is expecting a reference of some sort to be returned:

    print foo()->();     # CODE reference expected
    print foo()->{bar};  # HASH reference expected
    print foo()->[23];   # ARRAY reference expected
    print ${foo()};      # SCALAR reference expected
    print foo()->bar();  # OBJECT reference expected
    
    my $format = *{foo()}{FORMAT} # GLOB reference expected

You can check this using conditionals like `if (want('CODE'))`.
There is also a function `wantref()` which returns one of the strings `CODE`, `HASH`, `ARRAY`, `GLOB`, `SCALAR` or `OBJECT`; or the empty string if a reference is not expected.

Because `want('SCALAR')` is already used to select ordinary scalar context, you have to use `want('REFSCALAR')` to find out if a SCALAR reference is expected. Or you could use `want('REF') eq 'SCALAR'` of course.

Be warned that `want('ARRAY')` is a **very** different thing from `wantarray()`.

## Item count

Sometimes in list context the caller is expecting a particular number of items to be returned:

    my ($x, $y) = foo(); # foo is expected to return two items

If you pass a number to the `want` function, then it will return true or false according to whether at least that many items are wanted. So if we are in the definition of a sub which is being called as above, then:

    want(1) returns true
    want(2) returns true
    want(3) returns false

Sometimes there is no limit to the number of items that might be used:

    my @x = foo();
    do_something_with( foo() );

In this case, `want(2)`, `want(100)`, `want(1E9)` and so on will all return true; and so will `want('Infinity')`.

The `howmany` function can be used to find out how many items are wanted.
If the context is scalar, then `want(1)` returns true and `howmany()` returns 1.
If you want to check whether your result is being assigned to a singleton list, you can say `if (want('LIST', 1)) { ... }`.

## Boolean context

Sometimes the caller is only interested in the truth or falsity of a function's return value:

    if (everything_is_okay()) {
        # Carry on
    }

    print (foo() ? "ok\n" : "not ok\n");
    

In the following example, all subroutine calls are in BOOL context:

    my $x = ( (foo() && !bar()) xor (baz() || quux()) );

Boolean context, like the reference contexts above, is considered to be a subcontext of `SCALAR`.

# FUNCTIONS

## want(SPECIFIERS)

This is the primary interface to this module, and should suffice for most purposes. You pass it a list of context specifiers, and the return value is true whenever all of the specifiers hold.

    want('LVALUE', 'SCALAR');   # Are we in scalar lvalue context?
    want('RVALUE', 3);          # Are at least three rvalues wanted?
    want('ARRAY');              # Is the return value used as an array ref?

You can also prefix a specifier with an exclamation mark to indicate that you **do not** want it to be true

    want(2, '!3');              # Caller wants exactly two items.
    want(qw'REF !CODE !GLOB');  # Expecting a reference that is not a CODE or GLOB ref.
    want(100, '!Infinity');     # Expecting at least 100 items, but there is a limit.

If the _REF_ keyword is the only parameter passed, then the type of reference will be returned. This is just a synonym for the `wantref` function: it is included because you might find it useful if you do not want to pollute your namespace by importing several functions, and to conform to [Damian Conway's suggestion in RFC 21](http://dev.perl.org/rfc/21.html).

Finally, the keyword `COUNT` can be used, provided that it is the only keyword you pass. Mixing `COUNT` with other keywords is an error. This is a synonym for the ["howmany"](#howmany) function.

A full list of the permitted keyword is in the ["ARGUMENTS"](#arguments) section below.

## rreturn

Use this function instead of [return](https://metacpan.org/pod/perlfunc#return) from inside an lvalue subroutine when you know that you are in `RVALUE` context. If you try to use a normal [return](https://metacpan.org/pod/perlfunc#return), you will get a compile-time error in Perl 5.6.1 and above unless you return an lvalue. (Note: this is no longer true in Perl 5.16, where an ordinary return will once again work.)

## lnoreturn

Use this function instead of `return` from inside an lvalue subroutine when you are in `ASSIGN` context and you have used `want('ASSIGN')` to carry out the appropriate action.

If you use ["rreturn"](#rreturn) or ["lnoreturn"](#lnoreturn), then you have to put a bare `return;` at the very end of your lvalue subroutine, in order to stop the Perl compiler from complaining. Think of it as akin to the `1;` that you have to put at the end of a module. (Note: this is no longer true in Perl 5.16.)

## howmany()

Returns the _expectation count_, i.e. the number of items expected. If the expectation count is undefined, that indicates that an unlimited number of items might be used (e.g. the return value is being assigned to an array). In void context the expectation count is zero, and in scalar context it is one.

The same as `want('COUNT')`.

## wantref()

Returns the type of reference which the caller is expecting, or the empty string if the caller is not expecting a reference immediately.

The same as `want('REF')`.

## context

- `context()`

    Returns a string representing the current calling context, such as `VOID`, `SCALAR`, `LIST`, `BOOL`, `CODE`, `HASH`, `ARRAY`, `GLOB`, `REFSCALAR`, `ASSIGN`, or `OBJECT`. This function provides a convenient way to determine the context without manually checking multiple conditions using ["want"](#want).

    - Arguments

        None.

    - Returns

        A string indicating the current context, such as `VOID`, `SCALAR`, `LIST`, `BOOL`, `CODE`, `HASH`, `ARRAY`, `GLOB`, `REFSCALAR`, `ASSIGN`, or `OBJECT`. Returns `VOID` if the context cannot be determined.

    - Example

            sub test_context
            {
                my $ctx = context();
                print "Current context: $ctx\n";
            }

            test_context();         # Prints: Current context: VOID
            my $x = test_context(); # Prints: Current context: SCALAR
            my @x = test_context(); # Prints: Current context: LIST

# INTERNAL FUNCTIONS

The following functions are internal to `Wanted` and are not intended for public use. They are documented here for reference but should not be relied upon in user code, as their behaviour or availability may change in future releases.

## wantassign

- `wantassign($uplevel)`

    Checks if the current context is an lvalue assignment context (`ASSIGN`) at the specified `$uplevel` in the call stack. Returns an array reference containing the values being assigned if in `ASSIGN` context, or `undef` if not. In boolean
    context (e.g., when `want('BOOL')` is true), it returns a boolean indicating whether an assignment is occurring.

    This function is used internally by `want('ASSIGN')` to handle lvalue assignments in subroutines marked with the `:lvalue` attribute.

    - Arguments
        - `$uplevel`

            An integer specifying how many levels up the call stack to check the context.
            Typically set to 1 to check the immediate caller.
    - Returns
        - In list or scalar context: An array reference containing the values from the right-hand side of the assignment, or `undef` if not in `ASSIGN` context.
        - In boolean context: A boolean indicating whether the context is an `ASSIGN` context.
    - Example

            sub assign_test :lvalue
            {
                if( want('LVALUE', 'ASSIGN') )
                {
                    my $values = wantassign(1);
                    print "Assigned: @$values\n";
                    lnoreturn;
                }
                return;
            }

            assign_test() = 42; # Prints: Assigned: 42

## want\_assign

- `want_assign($level)`

    A low-level XS function that retrieves the values being assigned in an lvalue assignment context (`ASSIGN`) at the specified `$level` in the call stack.

    Returns an array reference containing the values from the right-hand side of the assignment, or `undef` if not in an `ASSIGN` context.

    This function is used internally by ["wantassign"](#wantassign) to fetch assignment values, which [wantassign](#wantassign) then processes based on the caller's context (e.g., scalar, list, or boolean context). It supports `want('ASSIGN')` indirectly through [wantassign](#wantassign).

    - Arguments
        - `$level`

            An integer specifying how many levels up the call stack to check the context.
    - Returns
        - An array reference containing the values from the right-hand side of the assignment, or `undef` if not in an `ASSIGN` context.
    - Example

        This function is typically called by ["wantassign"](#wantassign), but for illustrative purposes:

            sub assign_test :lvalue
            {
                if( want('LVALUE', 'ASSIGN') )
                {
                    my $values = want_assign( bump_level(1) );
                    print "Assigned: @$values\n";
                    lnoreturn;
                }
                return;
            }

            assign_test() = 42; # Prints: Assigned: 42

## want\_boolean

- `want_boolean($level)`

    Checks if the context at the specified `$level` in the call stack is a boolean context (`BOOL`). Returns true if the caller is evaluating the return value as a boolean (e.g., in conditionals like `if`, `while`, or with logical operators like `&&` or `||`).

    This function is used internally to support `want('BOOL')`.

    - Arguments
        - `$level`

            An integer specifying how many levels up the call stack to check the context.
    - Returns
        - A boolean (true or false) indicating whether the context is a boolean context.
    - Example

            sub bool_test
            {
                if( want_boolean(1) )
                {
                    print "In boolean context\n";
                    return(1);
                }
                return(0);
            }

            if( bool_test() )
            {
                # Prints: In boolean context
            }

## want\_count

- `want_count($level)`

    Returns the number of items expected by the caller at the specified `$level` in the call stack. Used internally to support `want('COUNT')` and ["howmany"](#howmany).

    - Arguments
        - `$level`

            An integer specifying how many levels up the call stack to check the context.
    - Returns
        - An integer representing the number of items expected, or `-1` if an unlimited number of items is expected (e.g., in list context with no fixed limit).
    - Example

            sub count_test
            {
                my $count = want_count(1);
                print "Caller expects $count items\n";
            }

            my( $a, $b ) = count_test(); # Prints: Caller expects 2 items

## want\_lvalue

- `want_lvalue($uplevel)`

    Checks if the context at the specified `$uplevel` in the call stack is an lvalue context for a subroutine marked with the `:lvalue` attribute. Returns true if the subroutine is called in a context where its return value can be assigned to.

    This function is used internally to support `want('LVALUE')` and `want('RVALUE')`.

    - Arguments
        - `$uplevel`

            An integer specifying how many levels up the call stack to check the context.
    - Returns
        - A boolean (true or false) indicating whether the context is an lvalue context.
    - Example

            sub lvalue_test :lvalue
            {
                if( want_lvalue(1) )
                {
                    print "In lvalue context\n";
                }
                my $var;
            }

            lvalue_test() = 42; # Prints: In lvalue context

# EXAMPLES

    use Wanted 'howmany';
    sub numbers
    {
        my $count = howmany();
        die( "Cannot make an infinite list" ) if( !defined( $count ) );
        return( 1..$count );
    }
    my( $one, $two, $three ) = numbers();

    use Wanted 'want';
    sub pi ()
    {
        if( want('ARRAY') )
        {
            return( [3, 1, 4, 1, 5, 9] );
        }
        elsif( want('LIST') )
        {
            return( 3, 1, 4, 1, 5, 9 );
        }
        else
        {
            return(3);
        }
    }
    print pi->[2];      # prints 4
    print ((pi)[3]);    # prints 1

# ARGUMENTS

The permitted arguments to the [want](#want) function are listed below.
The list is structured so that sub-contexts appear below the context that they are part of.

- VOID
- SCALAR
    - REF
        - REFSCALAR
        - CODE
        - HASH
        - ARRAY
        - GLOB
        - OBJECT
    - BOOL
- LIST
    - COUNT
    - &lt;number>
    - Infinity
- LVALUE
    - ASSIGN
- RVALUE

# EXPORT

The ["want"](#want) and ["rreturn"](#rreturn) functions are exported by default.

The ["wantref"](#wantref) and/or ["howmany"](#howmany) functions can also be imported:

    use Wanted qw( want howmany );

If you do not import these functions, you must qualify their names as (e.g.) `Wanted::wantref`.

# SUBTLETIES

There are two different levels of **BOOL** context. _Pure_ boolean context occurs in conditional expressions, and the operands of the `xor` and `!`/`not` operators.

Pure boolean context also propagates down through the `&&` and `||` operators.

However, consider an expression like `my $x = foo() && "yes"`. The subroutine is called in _pseudo_-boolean context - its return value is not **entirely** ignored, because the undefined value, the empty string and the integer `0` are all false.

At the moment `want('BOOL')` is true in either pure or pseudo boolean context.

# CREDITS

Robin Houston, <robin@cpan.org> wrote the original module [Want](https://metacpan.org/pod/Want) on which this is based.

Also, credits to Grok from [xAI](https://x.ai) for its support in updating the XS code, providing unit tests, and helping resolve several bugs from the original [Want](https://metacpan.org/pod/Want) module.

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

["wantarray" in perlfunc](https://metacpan.org/pod/perlfunc#wantarray), [Perl6 RFC 21, by Damian Conway](http://dev.perl.org/rfc/21.html)

[Contextual::Call](https://metacpan.org/pod/Contextual%3A%3ACall), [Contextual::Diag](https://metacpan.org/pod/Contextual%3A%3ADiag), [Contextual::Return](https://metacpan.org/pod/Contextual%3A%3AReturn)

# COPYRIGHT & LICENSE

Copyright(c) 2025 DEGUEST Pte. Ltd.

Portions copyright (c) 2001-2016, Robin Houston.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
