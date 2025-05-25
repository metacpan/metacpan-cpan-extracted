##----------------------------------------------------------------------------
## Wanted - ~/lib/Wanted.pm
## Version v0.1.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/05/16
## Modified 2025/05/24
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Wanted;
use strict;
use warnings;
require Exporter;
require DynaLoader;
our @ISA = qw( Exporter DynaLoader );
our @EXPORT = qw( want rreturn lnoreturn );
our @EXPORT_OK = qw( context howmany wantref );
our $VERSION = 'v0.1.0';
our $DEBUG;

bootstrap Wanted $VERSION;

my %reftype = (
    ARRAY  => 1,
    HASH   => 1,
    CODE   => 1,
    GLOB   => 1,
    OBJECT => 1,
);

sub bump_level
{
    my( $level ) = @_;
    for(;;)
    {
        my( $p, $r ) = parent_op_name( $level + 1 );
        if( !defined( $p ) )
        {
            # Return undef if parent_op_name fails (outside subroutine)
            return;
        }
        if( $p eq 'return' || 
            $p eq '(none)' && $r =~ /^leavesub(lv)?$/ )
        {
            ++$level
        }
        else
        {
            return( $level );
        }
    }
}

sub context
{
    my $gimme = wantarray_up(1);
    return( 'VOID' ) unless( defined( $gimme ) );
    my $ref_type = wantref(2);
    if( $ref_type )
    {
        return( $ref_type eq 'SCALAR' ? 'REFSCALAR' : $ref_type );
    }
    # Boolean must come before scalar
    elsif( want_boolean( bump_level(1) ) )
    {
        return('BOOL');
    }
    elsif( !!wantassign(2) )
    {
        return( 'ASSIGN' );
    }
    elsif( $gimme )
    {
        return( 'LIST' );
    }
    elsif( $gimme == 0 )
    {
        return( 'SCALAR' );
    }
    # Should not happen
    else
    {
        return( '' );
    }
}

sub double_return :lvalue;

sub howmany ()
{
    my $level = bump_level( @_, 1 );
    # Return undef if bump_level fails
    return unless( defined( $level ) );
    my $count = want_count( $level );
    return( $count < 0 ? undef : $count );
}

sub want
{
    if( @_ == 1 && $_[0] eq 'ASSIGN' )
    {
        @_ = (1);
        goto &wantassign;
    }
    want_uplevel( 1, @_ );
}

sub want_uplevel
{
    my( $level, @args ) = @_;

    if( 1 == @args )
    {
        @_ = ( 1 + $level );
        goto &wantref    if( $args[0] eq 'REF' );
        goto &howmany    if( $args[0] eq 'COUNT' );
        goto &wantassign if( $args[0] eq 'ASSIGN' );
    }

    for my $arg ( map split, @args )
    {
        my $is_neg = substr( $arg, 0, 1 ) eq '!';
        if( substr( $arg, 0, 1 ) eq '!' )
        {
            $is_neg = 1;
            $arg = substr( $arg, 1 );
        }
        my $result = _wantone( 2 + $level, $arg );
        # Return undef if context is invalid
        return unless( defined( $result ) );
        return(0) if( ( !$is_neg && !$result ) || ( $is_neg && $result ) );
    }
    return(1);
}

sub wantassign
{
    my $uplevel = shift( @_ );
    return unless( want_lvalue( $uplevel ) );
    my $r = want_assign( bump_level( $uplevel ) );
    if( want('BOOL') )
    {
        return( defined( $r ) && $r != 0 );
    }
    else
    {
        return( $r ? ( want('SCALAR') ? $r->[ $#$r ] : @$r ) : () );
    }
}

sub wantref
{
    my $level = bump_level( @_, 1 );
    # Return undef if bump_level fails
    return unless( defined( $level ) );
    my $n = parent_op_name( $level );
    return unless( defined( $n ) );
    if( $n eq 'rv2av' )
    {
        return( 'ARRAY' );
    }
    elsif( $n eq 'rv2hv' )
    {
        return( 'HASH' );
    }
    elsif( $n eq 'rv2cv' || $n eq 'entersub' )
    {
        return( 'CODE' );
        # Address issue No 47963: want() Confused by Prototypes (Jul 17, 2009)
        # Not working... Need to modify the XS code.
    }
    elsif( $n eq 'rv2gv' || $n eq 'gelem' )
    {
        return( 'GLOB' );
    }
    elsif( $n eq 'rv2sv' )
    {
        return( 'SCALAR' );
    }
    elsif( $n eq 'method_call' )
    {
        return( 'OBJECT' );
    }
    elsif( $n eq 'multideref' )
    {
        if( $] >= 5.022000 )
        {
            return( first_multideref_type( $level ) );
        }
        return( '' );
    }
    else
    {
        return( '' );
    }
}

sub rreturn(@)
{
    if( want_lvalue(1) )
    {
        die( "Can't rreturn in lvalue context" );
    }

    {
        return( double_return( @_ ) );
    }
}

sub lnoreturn () : lvalue
{
    if( !want_lvalue(1) || !want_assign(1) )
    {
        die( "Can't lnoreturn except in ASSIGN context" );
    }

    if( $] >= 5.019 )
    {
        return( double_return( disarm_temp( my $undef ) ) );
    }
    return( double_return( disarm_temp( my $undef ) ) );
}

sub _wantone
{
    my( $uplevel, $arg ) = @_;
    
    my $wantref = wantref( $uplevel + 1 );
    if( $arg =~ /^\d+$/ )
    {
        my $want_count = want_count( $uplevel );
        return( $want_count == -1 || $want_count >= $arg );
    }
    elsif( lc( $arg ) eq 'infinity' )
    {
        return( want_count( $uplevel ) == -1 );
    }
    elsif( $arg eq 'REF' )
    {
        return( $wantref );
    }
    elsif( $reftype{ $arg } )
    {
        no warnings; # If $wantref is undef
        return( $wantref eq $arg );
    }
    elsif( $arg eq 'REFSCALAR' )
    {
        no warnings; # If $wantref is undef
        return( $wantref eq 'SCALAR' );
    }
    elsif( $arg eq 'LVALUE' )
    {
        return( want_lvalue( $uplevel ) );
    }
    elsif( $arg eq 'RVALUE' )
    {
        return( !want_lvalue( $uplevel ) );
    }
    elsif( $arg eq 'VOID' )
    {
        return( !defined( wantarray_up( $uplevel ) ) );
    }
    elsif( $arg eq 'SCALAR' )
    {
        my $gimme = wantarray_up( $uplevel );
        # Return undef if context is invalid
        return unless( defined( $gimme ) );
        return( $gimme == 0 );
    }
    elsif( $arg eq 'BOOL' || $arg eq 'BOOLEAN' )
    {
        return( want_boolean( bump_level( $uplevel ) ) );
    }
    elsif( $arg eq 'LIST' )
    {
        my $gimme = wantarray_up( $uplevel );
        # Return undef if context is invalid
        return unless( defined( $gimme ) );
        return( $gimme );
    }
    elsif( $arg eq 'COUNT' )
    {
        die( "want: COUNT must be the *only* parameter" );
    }
    elsif( $arg eq 'ASSIGN' )
    {
        return( !!wantassign( $uplevel + 1 ) );
    }
    else
    {
        die( "want: Unrecognised specifier $arg" );
    }
}

*_wantref = \&wantref;

*_wantassign = \&wantassign;

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Wanted - Extended caller context detection

=head1 SYNOPSIS

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
    my $is_void = $thr->join; # true

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This XS module generalises the mechanism of the L<wantarray|perlfunc/wantarray> function, allowing a function to determine in detail how its return value is going to be used.

It is a fork from the module L<Want>, by Robin Houston, that is not updated anymore since 2016, and that throws a segmentation fault when called from the last line of a thread, or from a tie method, or from the last line of a mod_perl handler, when there is a lack of context.

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head2 Top-level contexts:

The three kinds of top-level context are well known:

=over 4

=item B<VOID>

The return value is not being used in any way. It could be an entire statement like C<foo();>, or the last component of a compound statement which is itself in void context, such as C<$test || foo();>n. Be warned that the last statement of a subroutine will be in whatever context the subroutine was called in, because the result is implicitly returned.

=item B<SCALAR>

The return value is being treated as a scalar value of some sort:

    my $x = foo();
    $y += foo();
    print "123" x foo();
    print scalar foo();
    warn foo()->{23};
    # ...etc...

=item B<LIST>

The return value is treated as a list of values:

    my @x = foo();
    my ($x) = foo();
    () = foo();           # even though the results are discarded
    print foo();
    bar(foo());           # unless the bar subroutine has a prototype
    print @hash{foo()};   # (hash slice)
    # ...etc...

=back

=head2 Lvalue subroutines:

The introduction of B<lvalue subroutines> in Perl 5.6 has created a new type of contextual information, which is independent of those listed above. When an lvalue subroutine is called, it can either be called in the ordinary way (so that its result is treated as an ordinary value, an B<rvalue>); or else it can be called so that its result is considered updatable, an B<lvalue>.

These rather arcane terms (lvalue and rvalue) are easier to remember if you know why they are so called. If you consider a simple assignment statement C<left = right>, then the B<l>eft-hand side is an B<l>value and the B<r>ight-hand side is an B<r>value.

So (for lvalue subroutines only) there are two new types of context:

=over 4

=item B<RVALUE>

The caller is definitely not trying to assign to the result:

    foo();
    my $x = foo();
    # ...etc...

If the sub is declared without the C<:lvalue> attribute, then it will I<always> be in RVALUE context.

If you need to return values from an lvalue subroutine in RVALUE context, you should use the C<rreturn> function rather than an ordinary C<return>. Otherwise you will probably get a compile-time error in perl 5.6.1 and later.

=item B<LVALUE>

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

or else the result of the function call is being used as part of the argument list for I<another> function call:

    bar(foo());   # Will *always* call foo in lvalue context,
                  # (provided that foo is an C<:lvalue> sub)
                  # regardless of what bar actually does.

The reason for this last case is that bar might be a sub which modifies its arguments. They are rare in contemporary Perl code, but perfectly possible:

    sub bar {
        $_[0] = 23;
    }

(This is really a throwback to Perl 4, which did not support explicit references.)

=back

=head2 Assignment context:

The commonest use of lvalue subroutines is with the assignment statement:

    size() = 12;
    (list()) = (1..10);

A useful motto to remember when thinking about assignment statements is I<context comes from the left>. Consider code like this:

    my ($x, $y, $z);
    sub list () :lvalue { ($x, $y, $z) }
    list = (1, 2, 3);
    print "\$x = $x; \$y = $y; \$z = $z\n";

This prints C<$x = ; $y = ; $z = 3>, which may not be what you were expecting. The reason is that the assignment is in scalar context, so the comma operator is in scalar context too, and discards all values but the last. You can fix it by writing C<(list) = (1,2,3);> instead.

If your lvalue subroutine is used on the left of an assignment statement, it is in B<ASSIGN> context. If ASSIGN is the only argument to C<want()>, then it returns a reference to an array of the value(s) of the right-hand side.

In this case, you should return with the C<lnoreturn> function, rather than an ordinary L<return|perlfunc/return>. 

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
error I<Can't modify non-lvalue subroutine call in lvalue subroutine return>.

The only way to write that C<backstr> function without using Want is to return a tied variable which is tied to a custom class.

=head2 Reference context:

Sometimes in scalar context the caller is expecting a reference of some sort to be returned:

    print foo()->();     # CODE reference expected
    print foo()->{bar};  # HASH reference expected
    print foo()->[23];   # ARRAY reference expected
    print ${foo()};      # SCALAR reference expected
    print foo()->bar();  # OBJECT reference expected
    
    my $format = *{foo()}{FORMAT} # GLOB reference expected

You can check this using conditionals like C<if (want('CODE'))>.
There is also a function C<wantref()> which returns one of the strings C<CODE>, C<HASH>, C<ARRAY>, C<GLOB>, C<SCALAR> or C<OBJECT>; or the empty string if a reference is not expected.

Because C<want('SCALAR')> is already used to select ordinary scalar context, you have to use C<want('REFSCALAR')> to find out if a SCALAR reference is expected. Or you could use C<want('REF') eq 'SCALAR'> of course.

Be warned that C<want('ARRAY')> is a B<very> different thing from C<wantarray()>.

=head2 Item count

Sometimes in list context the caller is expecting a particular number of items to be returned:

    my ($x, $y) = foo(); # foo is expected to return two items

If you pass a number to the C<want> function, then it will return true or false according to whether at least that many items are wanted. So if we are in the definition of a sub which is being called as above, then:

    want(1) returns true
    want(2) returns true
    want(3) returns false

Sometimes there is no limit to the number of items that might be used:

    my @x = foo();
    do_something_with( foo() );

In this case, C<want(2)>, C<want(100)>, C<want(1E9)> and so on will all return true; and so will C<want('Infinity')>.

The C<howmany> function can be used to find out how many items are wanted.
If the context is scalar, then C<want(1)> returns true and C<howmany()> returns 1.
If you want to check whether your result is being assigned to a singleton list, you can say C<if (want('LIST', 1)) { ... }>.

=head2 Boolean context

Sometimes the caller is only interested in the truth or falsity of a function's return value:

    if (everything_is_okay()) {
        # Carry on
    }

    print (foo() ? "ok\n" : "not ok\n");
    
In the following example, all subroutine calls are in BOOL context:

    my $x = ( (foo() && !bar()) xor (baz() || quux()) );

Boolean context, like the reference contexts above, is considered to be a subcontext of C<SCALAR>.

=head1 FUNCTIONS

=head2 want(SPECIFIERS)

This is the primary interface to this module, and should suffice for most purposes. You pass it a list of context specifiers, and the return value is true whenever all of the specifiers hold.

    want('LVALUE', 'SCALAR');   # Are we in scalar lvalue context?
    want('RVALUE', 3);          # Are at least three rvalues wanted?
    want('ARRAY');              # Is the return value used as an array ref?

You can also prefix a specifier with an exclamation mark to indicate that you B<do not> want it to be true

    want(2, '!3');              # Caller wants exactly two items.
    want(qw'REF !CODE !GLOB');  # Expecting a reference that is not a CODE or GLOB ref.
    want(100, '!Infinity');     # Expecting at least 100 items, but there is a limit.

If the I<REF> keyword is the only parameter passed, then the type of reference will be returned. This is just a synonym for the C<wantref> function: it is included because you might find it useful if you do not want to pollute your namespace by importing several functions, and to conform to L<Damian Conway's suggestion in RFC 21|http://dev.perl.org/rfc/21.html>.

Finally, the keyword C<COUNT> can be used, provided that it is the only keyword you pass. Mixing C<COUNT> with other keywords is an error. This is a synonym for the L</howmany> function.

A full list of the permitted keyword is in the L</ARGUMENTS> section below.

=head2 rreturn

Use this function instead of L<return|perlfunc/return> from inside an lvalue subroutine when you know that you are in C<RVALUE> context. If you try to use a normal L<return|perlfunc/return>, you will get a compile-time error in Perl 5.6.1 and above unless you return an lvalue. (Note: this is no longer true in Perl 5.16, where an ordinary return will once again work.)

B<C<rreturn> inside C<eval>:> In Perl 5.36 and later, C<rreturn> may fail to detect lvalue context inside an C<eval> block due to a Perl core limitation (see L</Detection of Lvalue Context Inside C<eval>>). This can lead to incorrect behaviour, as the necessary stack context is not properly propagated. For example:

    eval { lvalue_sub() = 42 };  # lvalue context not detected, rreturn may not die as expected

B<Recommendation:> Avoid using C<rreturn> inside an C<eval> block when the subroutine is in lvalue context. Instead, move the lvalue operation outside the C<eval> or explicitly handle the context in your subroutine logic.

=head2 lnoreturn

Use this function instead of C<return> from inside an lvalue subroutine when you are in C<ASSIGN> context and you have used C<want('ASSIGN')> to carry out the appropriate action.

If you use L</rreturn> or L</lnoreturn>, then you have to put a bare C<return;> at the very end of your lvalue subroutine, in order to stop the Perl compiler from complaining. Think of it as akin to the C<1;> that you have to put at the end of a module. (Note: this is no longer true in Perl 5.16.)

=head2 howmany()

Returns the I<expectation count>, i.e. the number of items expected. If the expectation count is undefined, that indicates that an unlimited number of items might be used (e.g. the return value is being assigned to an array). In void context the expectation count is zero, and in scalar context it is one.

The same as C<want('COUNT')>.

=head2 wantref()

Returns the type of reference which the caller is expecting, or the empty string if the caller is not expecting a reference immediately.

The same as C<want('REF')>.

=head2 context

=over 4

=item * C<context()>

Returns a string representing the current calling context, such as C<VOID>, C<SCALAR>, C<LIST>, C<BOOL>, C<CODE>, C<HASH>, C<ARRAY>, C<GLOB>, C<REFSCALAR>, C<ASSIGN>, or C<OBJECT>. This function provides a convenient way to determine the context without manually checking multiple conditions using L</want>.

=over 4

=item * Arguments

None.

=item * Returns

A string indicating the current context, such as C<VOID>, C<SCALAR>, C<LIST>, C<BOOL>, C<CODE>, C<HASH>, C<ARRAY>, C<GLOB>, C<REFSCALAR>, C<ASSIGN>, or C<OBJECT>. Returns C<VOID> if the context cannot be determined.

=item * Example

    sub test_context
    {
        my $ctx = context();
        print "Current context: $ctx\n";
    }

    test_context();         # Prints: Current context: VOID
    my $x = test_context(); # Prints: Current context: SCALAR
    my @x = test_context(); # Prints: Current context: LIST

=back

=back

=head1 INTERNAL FUNCTIONS

The following functions are internal to C<Wanted> and are not intended for public use. They are documented here for reference but should not be relied upon in user code, as their behaviour or availability may change in future releases.

=head2 wantassign

=over 4

=item * C<wantassign($uplevel)>

Checks if the current context is an lvalue assignment context (C<ASSIGN>) at the specified C<$uplevel> in the call stack. Returns an array reference containing the values being assigned if in C<ASSIGN> context, or C<undef> if not. In boolean
context (e.g., when C<want('BOOL')> is true), it returns a boolean indicating whether an assignment is occurring.

This function is used internally by C<want('ASSIGN')> to handle lvalue assignments in subroutines marked with the C<:lvalue> attribute.

=over 4

=item * Arguments

=over 4

=item * C<$uplevel>

An integer specifying how many levels up the call stack to check the context.
Typically set to 1 to check the immediate caller.

=back

=item * Returns

=over 4

=item * In list or scalar context: An array reference containing the values from the right-hand side of the assignment, or C<undef> if not in C<ASSIGN> context.

=item * In boolean context: A boolean indicating whether the context is an C<ASSIGN> context.

=back

=item * Example

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

=back

=back

=head2 want_assign

=over 4

=item * C<want_assign($level)>

A low-level XS function that retrieves the values being assigned in an lvalue assignment context (C<ASSIGN>) at the specified C<$level> in the call stack.

Returns an array reference containing the values from the right-hand side of the assignment, or C<undef> if not in an C<ASSIGN> context.

This function is used internally by L</wantassign> to fetch assignment values, which L<wantassign|/wantassign> then processes based on the caller's context (e.g., scalar, list, or boolean context). It supports C<want('ASSIGN')> indirectly through L<wantassign|/wantassign>.

=over 4

=item * Arguments

=over 4

=item * C<$level>

An integer specifying how many levels up the call stack to check the context.

=back

=item * Returns

=over 4

=item * An array reference containing the values from the right-hand side of the assignment, or C<undef> if not in an C<ASSIGN> context.

=back

=item * Example

This function is typically called by L</wantassign>, but for illustrative purposes:

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

=back

=back

=head2 want_boolean

=over 4

=item * C<want_boolean($level)>

Checks if the context at the specified C<$level> in the call stack is a boolean context (C<BOOL>). Returns true if the caller is evaluating the return value as a boolean (e.g., in conditionals like C<if>, C<while>, or with logical operators like C<&&> or C<||>).

This function is used internally to support C<want('BOOL')>.

=over 4

=item * Arguments

=over 4

=item * C<$level>

An integer specifying how many levels up the call stack to check the context.

=back

=item * Returns

=over 4

=item * A boolean (true or false) indicating whether the context is a boolean context.

=back

=item * Example

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

=back

=back

=head2 want_count

=over 4

=item * C<want_count($level)>

Returns the number of items expected by the caller at the specified C<$level> in the call stack. Used internally to support C<want('COUNT')> and L</howmany>.

=over 4

=item * Arguments

=over 4

=item * C<$level>

An integer specifying how many levels up the call stack to check the context.

=back

=item * Returns

=over 4

=item * An integer representing the number of items expected, or C<-1> if an unlimited number of items is expected (e.g., in list context with no fixed limit).

=back

=item * Example

    sub count_test
    {
        my $count = want_count(1);
        print "Caller expects $count items\n";
    }

    my( $a, $b ) = count_test(); # Prints: Caller expects 2 items

=back

=back

=head2 want_lvalue

=over 4

=item * C<want_lvalue($uplevel)>

Checks if the context at the specified C<$uplevel> in the call stack is an lvalue context for a subroutine marked with the C<:lvalue> attribute. Returns true if the subroutine is called in a context where its return value can be assigned to.

This function is used internally to support C<want('LVALUE')> and C<want('RVALUE')>.

=over 4

=item * Arguments

=over 4

=item * C<$uplevel>

An integer specifying how many levels up the call stack to check the context.

=back

=item * Returns

=over 4

=item * A boolean (true or false) indicating whether the context is an lvalue context.

=back

=item * Example

    sub lvalue_test :lvalue
    {
        if( want_lvalue(1) )
        {
            print "In lvalue context\n";
        }
        my $var;
    }

    lvalue_test() = 42; # Prints: In lvalue context

=back

=back

=head1 EXAMPLES

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

=head1 ARGUMENTS

The permitted arguments to the L<want|/want> function are listed below.
The list is structured so that sub-contexts appear below the context that they are part of.

=over 4

=item * VOID

=item * SCALAR

=over 4

=item * REF

=over 4

=item * REFSCALAR

=item * CODE

=item * HASH

=item * ARRAY

=item * GLOB

=item * OBJECT

=back

=item * BOOL

=back

=item * LIST

=over 4

=item * COUNT

=item * E<lt>numberE<gt>

=item * Infinity

=back

=item * LVALUE

=over 4

=item * ASSIGN

=back

=item * RVALUE

=back

=head1 EXPORT

The L</want> and L</rreturn> functions are exported by default.

The L</wantref> and/or L</howmany> functions can also be imported:

    use Wanted qw( want howmany );

If you do not import these functions, you must qualify their names as (e.g.) C<Wanted::wantref>.

=head1 SUBTLETIES

There are two different levels of B<BOOL> context. I<Pure> boolean context occurs in conditional expressions, and the operands of the C<xor> and C<!>/C<not> operators.

Pure boolean context also propagates down through the C<&&> and C<||> operators.

However, consider an expression like C<my $x = foo() && "yes">. The subroutine is called in I<pseudo>-boolean context - its return value is not B<entirely> ignored, because the undefined value, the empty string and the integer C<0> are all false.

At the moment C<want('BOOL')> is true in either pure or pseudo boolean context.

=head1 LIMITATIONS

=head2 Detection of Lvalue Context Inside C<eval>

Due to a known limitation in Perl's core behaviour, lvalue context cannot be reliably detected from within an C<eval> block in modern Perl versions (5.36 and later).

For example, the following will NOT be detected as lvalue context:

    eval { lvalue_sub() = 42 };

This occurs because Perl does not propagate lvalue context into the internal call frame used for C<eval>. As a result, C<want_lvalue()> will return false even though the subroutine is used in an lvalue assignment.

This limitation affects all XS-based context-detection modules, including L<Want>, and is not specific to C<Wanted>. It is a change in Perl's internals introduced in versions after 5.16, where the original L<Want> module was last updated.

B<Recommendation:> Avoid relying on lvalue context detection inside C<eval> blocks. Instead, move the assignment outside the C<eval>, or handle lvalue semantics explicitly in the subroutine logic. For example:

    my $result = lvalue_sub();
    $result = 42;  # Perform assignment outside eval

=head2 Code Reference Detection with Prototypes in Scalar Context

In scalar context, C<want('CODE')> may incorrectly return true when the caller does not expect a code reference, particularly when the subroutine has a prototype (e.g., C<sub foo($)>). This is a known issue (RT#47963) from the original L<Want> module, which has not been resolved in C<Wanted>.

For example:

    sub foo($) { sub { } }  # Prototype forces scalar context
    my $x = foo();          # Scalar context, but want('CODE') returns true

In this case, C<want('CODE')> should return false because the caller does not expect a code reference, but it returns true due to limitations in context detection.

B<Recommendation:> Be cautious when using C<want('CODE')> in scalar context with prototyped subroutines. If necessary, explicitly check the context using C<want('SCALAR')> or avoid prototypes in such cases.

=head1 CREDITS

Robin Houston, E<lt>robin@cpan.orgE<gt> wrote the original module L<Want> on which this is based.

Grok from L<xAI|https://x.ai> for its contribution on some XS code, providing unit tests to tackle edge cases, and help resolving several bugs from the original L<Want> module.

Albert (OpenAI) for its contribution on some XS code.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perlfunc/wantarray>, L<Perl6 RFC 21, by Damian Conway|http://dev.perl.org/rfc/21.html>

L<Contextual::Call>, L<Contextual::Diag>, L<Contextual::Return>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2025 DEGUEST Pte. Ltd.

Portions copyright (c) 2001-2016, Robin Houston.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
