package Zapp::Formula;
# ABSTRACT: Formula interpreter

# "That was almost the perfect crime. But you forgot one thing: rock
# crushes scissors. But paper covers rock … and scissors cuts paper!"

#pod =head1 SYNOPSIS
#pod
#pod     my $f = Zapp::Formula->new;
#pod
#pod     # [ call => [ var => 'UPPER' ], [ binop => '&', [ string => "hello " ], [ var => "name" ] ] ]
#pod     my $tree = $f->parse( 'UPPER( "hello " & name )' );
#pod
#pod     # HELLO LEELA
#pod     my $res = $f->eval( 'UPPER( "hello " & name )', { name => 'Leela' } );
#pod
#pod     # { greeting => "HELLO LEELA" }
#pod     my $data = $f->resolve( { greeting => 'UPPER( "hello " & name )' }, { name => 'Leela' } );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module parses and evaluates formulas. Formulas are strings that
#pod begin with one C<=> and contain an expression. Formula expressions can
#pod contain strings, numbers, variables, binary operations, function calls,
#pod and array or hash literals.
#pod
#pod =head1 FORMULA SYNTAX
#pod
#pod Where possible, the formula syntax resembles the syntax from popular spreadsheet
#pod programs like Lotus 1-2-3, Excel, and Sheets, and Microsoft's Power Fx.
#pod
#pod =head2 Strings
#pod
#pod Strings are surrounded by double-quotes (C<"Professor Fisherprice
#pod Shpeekenshpell">). Double-quotes can be inserted into strings by adding
#pod a backslash (C<"The horse says \"Doctorate Denied\"">).
#pod
#pod =head2 Numbers
#pod
#pod Numbers can be integers (C<312>) or decimals (C<3.12>). Negative numbers have
#pod C<-> in front (C<-3.12>).
#pod
#pod =head2 Variables
#pod
#pod Variables start with a letter and can contain letters, numbers, and
#pod underscores (C<_>).  Variable values are defined in the context.
#pod Variables cannot be created by formulas (yet).
#pod
#pod =head2 Binary Operators
#pod
#pod =over
#pod
#pod =item Mathematical Operators
#pod
#pod     # Addition
#pod     1.2 + 3             -> 4.2
#pod
#pod     # Subtraction
#pod     4 - 2.3             -> 1.7
#pod
#pod     # Multiplication
#pod     2 * 3               -> 6
#pod
#pod     # Division
#pod     8 / 2               -> 4
#pod
#pod     # Exponentation
#pod     2 ^ 3               -> 8
#pod
#pod =item String Operators
#pod
#pod     # Concatenation
#pod     "Hello, " & "World" -> "Hello, World"
#pod
#pod =item Logical Operators
#pod
#pod     # Equality
#pod     2 = 2               -> TRUE
#pod
#pod     # Inequality
#pod     3 <> 3              -> FALSE
#pod
#pod     # Less-/Greater-than
#pod     3 < 8               -> TRUE
#pod     3 > 8               -> FALSE
#pod
#pod     # Less-/Greater-than-or-equal
#pod     3 <= 2              -> FALSE
#pod     3 >= 3              -> TRUE
#pod
#pod =back
#pod
#pod =head2 Function Calls
#pod
#pod Function calls start with the name of the function followed by empty parentheses or
#pod parentheses containing function parameters (expressions) separated by commas.
#pod
#pod     IF( name = "Leela", TRUE(), FALSE() )
#pod
#pod See L</FUNCTIONS> for a list of available functions.
#pod
#pod =head2 Arrays
#pod
#pod Arrays begin with square brackets and contain expressions separated by commas.
#pod
#pod     [ name, name = "Leela", TRUE() ]
#pod
#pod Get a value from an array using square brackets and the index of the
#pod item (0-based).
#pod
#pod     # Characters = [ "Fry", "Leela", "Bender" ]
#pod     Characters[2]       # Bender
#pod
#pod =head2 Hashes
#pod
#pod Hashes begin with curly braces and contain key/value pairs separated by commas.
#pod Keys must be strings (for now) and are separated from values with colons.
#pod
#pod     { "name": "Leela", "captain": TRUE() }
#pod
#pod Get a value from a hash using dot followed by the key.
#pod
#pod     # Employees = { "Pilot": "Leela", "Cook": "Bender", "Person": "Fry" }
#pod     Employees.Pilot     # Leela
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Zapp::Task>, L<Zapp>
#pod
#pod =cut

use Mojo::Base -base, -signatures;
use Zapp::Util qw( get_path_from_data );
use List::Util qw( any all pairs );

# XXX: binops, functions, and grammar should all be attributes so that
# they can be configured per-instance
our %BINOPS = (
    '+' => sub { $_[0] + $_[1] },
    '-' => sub { $_[0] - $_[1] },
    '*' => sub { $_[0] * $_[1] },
    '/' => sub { $_[0] / $_[1] },
    '^' => sub { $_[0] ** $_[1] },
    '&' => sub { $_[0] . $_[1] },
    # XXX: Logical binops need to detect numbers vs. strings and change
    # comparisons
    '=' => sub { $_[0] eq $_[1] },
    '>' => sub { $_[0] gt $_[1] },
    '<' => sub { $_[0] lt $_[1] },
    '>=' => sub { $_[0] ge $_[1] },
    '<=' => sub { $_[0] le $_[1] },
    '<>' => sub { $_[0] ne $_[1] },
);

our %FUNCTIONS = (
    ### Logic functions
    TRUE => \&_func_true,
    FALSE => \&_func_false,
    NOT => \&_func_not,
    IF => \&_func_if,
    IFS => \&_func_ifs,
    AND => \&_func_and,
    OR => \&_func_or,
    XOR => \&_func_xor,
    EVAL => \&_func_eval,
    ### Text functions
    # Case manipulation
    LOWER => sub( $f, $str ) { lc $str },
    UPPER => sub( $f, $str ) { uc $str },
    PROPER => sub( $f, $str ) { ( lc $str ) =~ s/(?:^|[^a-zA-Z'])([a-z])/uc $1/er },
    # Substrings
    LEFT => sub( $f, $str, $len ) { substr $str, 0, $len },
    RIGHT => sub( $f, $str, $len ) { substr $str, -$len },
);

my ( @result, @term, @args, @binop, @call, @array, @hash, @var, $depth, $expected, $failed_at );
our $GRAMMAR = qr{
    (?(DEFINE)
        (?<EXPR>
            # Expressions can recurse, so we need to use a stack. When
            # we recurse, we must take the result off the stack and save
            # it until we can put it back on the stack (somewhere)
            (?{ $depth++ })(?>
            \s*
            (?:
                # Terminator first, to escape infinite loops
                (?> (?&TERM) ) (?! (?&OP) | \( ) \s*
                (*COMMIT) (?{ push @result, pop @term })
                # If there is more to match, it must've been an attempt
                # at an operator
                (?{ $expected = 'Expected operator'; $failed_at = pos() })
            |
                (?> (?&CALL) ) (?! (?&OP) ) \s*
                (*COMMIT) (?{ push @result, [ call => @{ pop @call } ] })
                # If there is more to match, it must've been an attempt
                # at an operator
                (?{ $expected = 'Expected operator'; $failed_at = pos() })
            |
                (?> (?&ARRAY) ) (?! (?&OP) )
                (*COMMIT) (?{ push @result, [ array => @{ pop @array } ] })
            |
                (?> (?&HASH) ) (?! (?&OP) )
                (*COMMIT) (?{ push @result, [ hash => @{ pop @hash } ] })
            |
                (?{ push @binop, [] })
                (?>
                    (?> (?&CALL) )
                    (?{ push @{ $binop[-1] }, [ call => @{ pop @call } ] })
                |
                    (?> (?&TERM) )
                    (?{ push @{ $binop[-1] }, [ @{ pop @term } ] })
                )
                (*COMMIT) (?{ $expected = 'Expected operator'; $failed_at = pos() })
                (?<op> (?&OP) ) \s*
                (*COMMIT) (?{ $expected = 'Expected expression'; $failed_at = pos() })
                (?> (?&EXPR) )
                (?{ push @result, [ binop => $+{op}, @{ pop @binop }, pop @result ] })
            |
                # Characters that cannot be used to start a term, call,
                # array, or hash
                [^a-zA-Z0-9\."\-\[\{]
                (*FAIL)
            )
            )(?{ $depth-- })
        )
        (?<OP>(?> @{[ join '|', map quotemeta, keys %BINOPS ]} ))
        (?<CALL>(?>
            (?&VAR)
            (?{ push @call, [ [ var => @var ] ]; @var = () })
            \s* \( \s*
                (?>
                    (?{ push @args, [] })
                    (?>
                        (?&EXPR)
                        (?{ push @{ $args[-1] }, pop @result })
                    )?
                    (?:
                        \s* , \s* (?> (?&EXPR) )
                        (?{ push @{ $args[-1] }, pop @result })
                    )*
                )
                \s* (*COMMIT)
                (?{ $expected = 'Could not find end parenthesis'; $failed_at = pos() })
            \) \s*
            (?{ push $call[-1]->@*, @{ pop @args } })
        ))
        (?<ARRAY>(?>
            \[ \s*
                (?{ push @array, [] })
                (?:
                    (?> (?&EXPR) ) \s* ,? \s*
                    (?{ push @{ $array[-1] }, pop @result })
                )*
            \] \s*
        ))
        (?<HASH>(?>
            \{ \s*
                (?{ push @hash, [] })
                (?:
                    (?> (?<key> (?&STRING) ) ) \s* : \s*
                    (?> (?&EXPR) ) \s* ,? \s*
                    (?{ push @{ $hash[-1] }, [ $+{'key'}, pop @result ] })
                )*
            \} \s*
        ))
        (?<TERM>(?>
            (?:
                (?<string> (?&STRING) )
                (?{ push @term, [ %+{'string'} ] })
            |
                (?<number> (?&NUMBER) )
                (?{ push @term, [ %+{'number'} ] })
            |
                (?&VAR)
                (?{ push @term, [ var => @var ]; @var = () })
            )
            \s*
        ))
        (?<VAR>
            (?<word> [a-zA-Z][a-zA-Z0-9_]+ ) \s*
            (?{ push @var, $+{word} })
            (?: \. \s* (?&VAR) )*+
        )
        (?<STRING>
            "
            (?>
                [^"\\]*+  (?: \\" [^"\\]*+ )*+
            )
            (*COMMIT) (?{ $expected = 'Could not find closing quote for string'; $failed_at = pos() })
            "
        )
        (?<NUMBER> -? \d+ %? | -? \d* \. \d+ %? )
    )
}xms;

has _context => sub { {} };

# XXX: Strings that look like money amounts can be coerced into numbers
# XXX: Strings that look like dates can be coerced into dates
#       ... Or maybe not, since that's one of the biggest complaints
#       about Excel. Though, that might just refer to the
#       auto-formatting thing, which we will not be doing.

#pod =method parse
#pod
#pod     my $tree = $f->parse( $formula )
#pod
#pod Parse the given formula (without C<=> prefix) and return an abstract
#pod syntax tree that can be evaluated.
#pod
#pod =cut

# Does not expect `=` prefix
sub parse( $self, $expr ) {
    @result = ();
    $depth = 0;
    $expected = '';
    $failed_at = 0;
    unless ( $expr =~ /${GRAMMAR}^(?&EXPR)$/ ) {
        # XXX: Parse error handling. DCONWAY has numerous
        # (?{ $expected = '...'; $failed_at = pos() }) in his
        # Keyword::Declare grammar. If parsing stops, the last value in
        # those vars is used to show an error message.
        $failed_at = 'end of input' if $failed_at >= length $expr;
        die "Syntax error: $expected at $failed_at.\n";
    }
    return $result[0];
}

#pod =method eval
#pod
#pod     my $value = $f->eval( $formula, $context );
#pod
#pod Parse and execute the given formula (without C<=> prefix) using the given context as
#pod values for any variables.
#pod
#pod =cut

# Does not expect `=` prefix
sub eval( $self, $expr, $context={} ) {
    $self->_context( $context );
    my $tree = $self->parse( $expr );
    my $handle = sub( $tree ) {
        if ( $tree->[0] eq 'string' ) {
            # XXX: strip slashes
            my $string = substr $tree->[1], 1, -1;
            $string =~ s/\\(?!\\)//g;
            return $string;
        }
        if ( $tree->[0] eq 'number' ) {
            return $tree->[1];
        }
        if ( $tree->[0] eq 'var' ) {
            my $var = join '.', $tree->@[1..$#$tree];
            my $context = $self->_context;
            return ref $context eq 'CODE' ? $context->( $var )
                : get_path_from_data( $var, $context )
                ;
        }
        if ( $tree->[0] eq 'call' ) {
            my $name = join '.', $tree->[1]->@[1..$tree->[1]->$#*];
            my @args = map { __SUB__->( $_ ) } @{$tree}[2 .. $#{$tree}];
            return $FUNCTIONS{ $name }->( $self, @args );
        }
        if ( $tree->[0] eq 'binop' ) {
            my $op = $tree->[1];
            my $left = __SUB__->( $tree->[2] );
            my $right = __SUB__->( $tree->[3] );
            return $BINOPS{ $op }->( $left, $right );
        }
        die "Unknown parse result: $tree->[0]";
    };
    my $result = $handle->( $tree );
    return $result;
}

#pod =method resolve
#pod
#pod     my $data = $f->resolve( $data, $context );
#pod
#pod Resolve all formulas in the data structure C<$data> and return a new data structure
#pod with the resolved values. Formulas are strings that begin with C<=>. Use C<==> to escape
#pod parsing.
#pod
#pod     # { val => 1, str => '=num' }
#pod     $f->resolve( { val => '=num', str => '==num' }, { num => 1 } );
#pod
#pod =cut

sub resolve( $self, $data, $context={} ) {
    return ref $data eq 'ARRAY' ? [ map { $self->resolve( $_, $context ) } @$data ]
        : ref $data eq 'HASH' ? { map { $_ => $self->resolve( $data->{ $_ }, $context ) } keys %$data }
        : !ref $data && $data =~ /^=(?!=)/ ? $self->eval( substr( $data, 1 ), $context )
        : $data =~ s/^==/=/r;
}

#pod =head1 FUNCTIONS
#pod
#pod =cut

# XXX: Add real-world examples of usage of all functions
# NOTE: Arrange all functions in alphabetical order inside their
# category

#pod =head2 Logic/Control Functions
#pod
#pod =head3 AND
#pod
#pod     =AND( <expression>... )
#pod
#pod Returns C<TRUE> if all expressions are true.
#pod
#pod =cut

sub _func_and( $f, @exprs ) {
    return ( all { !!$_ } @exprs ) ? _func_true($f) : _func_false($f);
}

#pod =head3 EVAL
#pod
#pod     =EVAL( <string> )
#pod
#pod Evaluate the string as a formula and return the result. The string must
#pod not begin with an C<=>.
#pod
#pod =cut

sub _func_eval( $f, $expr ) {
    # XXX: This context attribute is a bad way of doing things, but we
    # need some way for functions to get the context, or values from the
    # context...
    return $f->eval( $expr, $f->_context );
}

#pod =head3 FALSE
#pod
#pod     =FALSE()
#pod
#pod Returns a false value.
#pod
#pod =cut

sub _func_false( $f ) {
    return Mojo::JSON->false;
}

#pod =head3 IF
#pod
#pod     =IF( <expression>, <true_result>, <false_result> )
#pod
#pod Evaluate the expression in C<expression> and return C<true_result> if
#pod the condition is true, or C<false_result> if the condition is false.
#pod
#pod =cut

sub _func_if( $f, $expr, $true_result, $false_result ) {
    return $expr ? $true_result : $false_result;
}

#pod =head3 IFS
#pod
#pod     =IFS( <expression>, <result>, ..., <default_result> )
#pod
#pod Evaluate each expression and return its corresponding result if the
#pod expression is true. Return C<default_result> if no condition is true.
#pod
#pod =cut

sub _func_ifs( $f, @args ) {
    my $default = pop @args;
    for my $pair ( pairs @args ) {
        return $pair->[1] if $pair->[0];
    }
    return $default;
}

#pod =head3 NOT
#pod
#pod     =NOT( <expression> )
#pod
#pod Returns C<TRUE> if the expression is true, C<FALSE> otherwise.
#pod
#pod =cut

sub _func_not( $f, $expr ) {
    return !!$expr ? _func_false($f) : _func_true($f);
}

#pod =head3 OR
#pod
#pod     =OR( <expression>... )
#pod
#pod Returns C<TRUE> if one expression is true.
#pod
#pod =cut

sub _func_or( $f, @exprs ) {
    return ( any { !!$_ } @exprs ) ? _func_true($f) : _func_false($f);
}

#pod =head3 TRUE
#pod
#pod     =TRUE()
#pod
#pod Returns a true value.
#pod
#pod =cut

sub _func_true( $f ) {
    return Mojo::JSON->true;
}

#pod =head3 XOR
#pod
#pod     =XOR( <expression>... )
#pod
#pod Returns C<TRUE> if one and only one expression is true.
#pod
#pod =cut

sub _func_xor( $f, @exprs ) {
    return ( grep { !!$_ } @exprs ) == 1 ? _func_true($f) : _func_false($f);
}

#=head2 Text Functions

#=cut

#=head2 Date/Time Functions

#=cut

1;

__END__

=pod

=head1 NAME

Zapp::Formula - Formula interpreter

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    my $f = Zapp::Formula->new;

    # [ call => [ var => 'UPPER' ], [ binop => '&', [ string => "hello " ], [ var => "name" ] ] ]
    my $tree = $f->parse( 'UPPER( "hello " & name )' );

    # HELLO LEELA
    my $res = $f->eval( 'UPPER( "hello " & name )', { name => 'Leela' } );

    # { greeting => "HELLO LEELA" }
    my $data = $f->resolve( { greeting => 'UPPER( "hello " & name )' }, { name => 'Leela' } );

=head1 DESCRIPTION

This module parses and evaluates formulas. Formulas are strings that
begin with one C<=> and contain an expression. Formula expressions can
contain strings, numbers, variables, binary operations, function calls,
and array or hash literals.

=head1 METHODS

=head2 parse

    my $tree = $f->parse( $formula )

Parse the given formula (without C<=> prefix) and return an abstract
syntax tree that can be evaluated.

=head2 eval

    my $value = $f->eval( $formula, $context );

Parse and execute the given formula (without C<=> prefix) using the given context as
values for any variables.

=head2 resolve

    my $data = $f->resolve( $data, $context );

Resolve all formulas in the data structure C<$data> and return a new data structure
with the resolved values. Formulas are strings that begin with C<=>. Use C<==> to escape
parsing.

    # { val => 1, str => '=num' }
    $f->resolve( { val => '=num', str => '==num' }, { num => 1 } );

=head1 FORMULA SYNTAX

Where possible, the formula syntax resembles the syntax from popular spreadsheet
programs like Lotus 1-2-3, Excel, and Sheets, and Microsoft's Power Fx.

=head2 Strings

Strings are surrounded by double-quotes (C<"Professor Fisherprice
Shpeekenshpell">). Double-quotes can be inserted into strings by adding
a backslash (C<"The horse says \"Doctorate Denied\"">).

=head2 Numbers

Numbers can be integers (C<312>) or decimals (C<3.12>). Negative numbers have
C<-> in front (C<-3.12>).

=head2 Variables

Variables start with a letter and can contain letters, numbers, and
underscores (C<_>).  Variable values are defined in the context.
Variables cannot be created by formulas (yet).

=head2 Binary Operators

=over

=item Mathematical Operators

    # Addition
    1.2 + 3             -> 4.2

    # Subtraction
    4 - 2.3             -> 1.7

    # Multiplication
    2 * 3               -> 6

    # Division
    8 / 2               -> 4

    # Exponentation
    2 ^ 3               -> 8

=item String Operators

    # Concatenation
    "Hello, " & "World" -> "Hello, World"

=item Logical Operators

    # Equality
    2 = 2               -> TRUE

    # Inequality
    3 <> 3              -> FALSE

    # Less-/Greater-than
    3 < 8               -> TRUE
    3 > 8               -> FALSE

    # Less-/Greater-than-or-equal
    3 <= 2              -> FALSE
    3 >= 3              -> TRUE

=back

=head2 Function Calls

Function calls start with the name of the function followed by empty parentheses or
parentheses containing function parameters (expressions) separated by commas.

    IF( name = "Leela", TRUE(), FALSE() )

See L</FUNCTIONS> for a list of available functions.

=head2 Arrays

Arrays begin with square brackets and contain expressions separated by commas.

    [ name, name = "Leela", TRUE() ]

Get a value from an array using square brackets and the index of the
item (0-based).

    # Characters = [ "Fry", "Leela", "Bender" ]
    Characters[2]       # Bender

=head2 Hashes

Hashes begin with curly braces and contain key/value pairs separated by commas.
Keys must be strings (for now) and are separated from values with colons.

    { "name": "Leela", "captain": TRUE() }

Get a value from a hash using dot followed by the key.

    # Employees = { "Pilot": "Leela", "Cook": "Bender", "Person": "Fry" }
    Employees.Pilot     # Leela

=head1 SEE ALSO

L<Zapp::Task>, L<Zapp>

=head1 FUNCTIONS

=head2 Logic/Control Functions

=head3 AND

    =AND( <expression>... )

Returns C<TRUE> if all expressions are true.

=head3 EVAL

    =EVAL( <string> )

Evaluate the string as a formula and return the result. The string must
not begin with an C<=>.

=head3 FALSE

    =FALSE()

Returns a false value.

=head3 IF

    =IF( <expression>, <true_result>, <false_result> )

Evaluate the expression in C<expression> and return C<true_result> if
the condition is true, or C<false_result> if the condition is false.

=head3 IFS

    =IFS( <expression>, <result>, ..., <default_result> )

Evaluate each expression and return its corresponding result if the
expression is true. Return C<default_result> if no condition is true.

=head3 NOT

    =NOT( <expression> )

Returns C<TRUE> if the expression is true, C<FALSE> otherwise.

=head3 OR

    =OR( <expression>... )

Returns C<TRUE> if one expression is true.

=head3 TRUE

    =TRUE()

Returns a true value.

=head3 XOR

    =XOR( <expression>... )

Returns C<TRUE> if one and only one expression is true.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
