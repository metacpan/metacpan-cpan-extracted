package overload::reify;

use 5.006;

# ABSTRACT: Provide named methods for inherited overloaded operators

use strict;
use warnings;

our $VERSION = '0.07';

use overload ();
use Carp ();

my %MethodNames = (

    # with_assign       => '+ - * / % ** << >> x .',
    '+'                 => 'add',
    '-'                 => 'subtract',
    '*'                 => 'multiply',
    '/'                 => 'divide',
    '%'                 => 'modulus',
    '**'                => 'pow',
    '<<'                => 'lshift',
    '>>'                => 'rshift',
    'x'                 => 'repetition',
    '.'                 => 'append',

    # assign            => '+= -= *= /= %= **= <<= >>= x= .='
    '+='                => 'add_assign',
    '-='                => 'subtract_assign',
    '*='                => 'multiply_assign',
    '/='                => 'divide_assign',
    '%='                => 'modulus_assign',
    '**='               => 'pow_assign',
    '<<='               => 'lshift_assign',
    '>>='               => 'rshift_assign',
    'x='                => 'repetition_assign',
    '.='                => 'append_assign',

    # num_comparison    => '< <= > >= == !=',
    '<'                 => 'numeric_lt',
    '<='                => 'numeric_le',
    '>'                 => 'numeric_gt',
    '>='                => 'numeric_ge',
    '=='                => 'numeric_eq',
    '!='                => 'numeric_ne',

    # '3way_comparison' => '<=> cmp',
    '<=>'               => 'numeric_cmp',
    'cmp'               => 'string_cmp',

    # str_comparison    => 'lt le gt ge eq ne',
    'lt'                => 'string_lt',
    'le'                => 'string_le',
    'gt'                => 'string_gt',
    'ge'                => 'string_ge',
    'eq'                => 'string_eq',
    'ne'                => 'string_ne',

    # binary            => '& &= | |= ^ ^= &. &.= |. |.= ^. ^.=',
    '&'                 => 'binary_and',
    '&='                => 'binary_and_assign',
    '|'                 => 'binary_or',
    '|='                => 'binary_or_assign',
    '^'                 => 'binary_xor',
    '^='                => 'binary_xor_assign',
    '&.'                => 'binary_string_and',
    '&.='               => 'binary_string_and_assign',
    '|.'                => 'binary_string_or',
    '|.='               => 'binary_string_or_assign',
    '^.'                => 'binary_string_xor',
    '^.='               => 'binary_string_xor_assign',

    # unary             => 'neg ! ~ ~.',
    'neg'               => 'neg',
    '!'                 => 'not',
    '~'                 => 'bitwise_negation',
    '~.'                => 'bitwise_string_negation',


    # mutators          => '++ --',
    '++'                => 'increment',
    '--'                => 'decrement',

    # func              => 'atan2 cos sin exp abs log sqrt int',
    'atan2'             => 'atan2',
    'cos'               => 'cos',
    'sin'               => 'sin',
    'exp'               => 'exp',
    'abs'               => 'abs',
    'log'               => 'log',
    'sqrt'              => 'sqrt',
    'int'               => 'int',

    # conversion        => 'bool "" 0+ qr',
    'bool'              => 'bool',
    '""'                => 'stringify',
    '0+'                => 'numerify',
    'qr'                => 'regexp',

    # iterators         => '<>',
    '<>'                => 'null_filehandle',

    # filetest          => '-X',
    '-X'                => 'filetest',

    # dereferencing     => '${} @{} %{} &{} *{}',
    '${}'               => 'scalar_deref',
    '@{}'               => 'array_deref',
    '%{}'               => 'hash_deref',
    '&{}'               => 'code_deref',
    '*{}'               => 'glob_deref',

    # matching          => '~~',
    '~~'                => 'smartmatch',

    # special           => 'nomethod fallback ='
    'nomethod'          => 'nomethod',
    '='                 => 'copy_constructor',
);

# get those supported on this version of Perl
my @PlatformOps = grep( $_ ne 'fallback',
                map( split( /\s+/, $_ ), values %overload::ops ) );

# and create a mapping to the method names. if a method name
# is missing, it'll result in an undef entry in the mapping,
# and it'll trigger an error in the test suite.
my %OP;
@OP{@PlatformOps} = @MethodNames{@PlatformOps};


# operator overloads are stored in the symbol table as "($op"
#
# if the overload is a coderef
#    *{$symbol}{CODE} = $coderef
#
# if the overload is a $method_name
#    *{$symbol}{CODE}   = \&overload::nil (or ::_nil)
#    *{$symbol}{SCALAR} = $method_name
#
# cribbed from Role::Tiny


sub import {

    my $class = shift;

    my %opt = (
        -redefine => 0,
        -methods => 1,
        -prefix => 'operator_',
        'HASH' eq ref $_[-1] ? %{ pop() } : (),
    );


    my $into = delete( $opt{-into} ) || caller;
    my $wrap_methods = delete $opt{-methods};
    my $method_name_prefix = delete $opt{-prefix};
    my $redefine_methods   = delete $opt{-redefine};

    Carp::croak( "unknown options: ", keys %opt ) if %opt;

    my %install;

    my @args = @_;
    while ( @args ) {

        my $arg = shift @args;

        if ( $arg eq '-not' ) {

            # if first is an exclusion, populate
            @install{ $class->_ops( ':all' ) } = 1
                if @args == @_ - 1;

            $arg = shift @args
              or Carp::croak( "missing operator after -not\n" );

            $arg = [ $arg ] unless 'ARRAY' eq ref $arg;

            delete @install{ $class->_ops( $_ ) } foreach @$arg
        }
        else {
            @install{ $class->_ops( $arg ) } = 1;
        }
    }

    # default to all if not specified, but only if no arguments were
    # passed. that way if the caller (mistakenly?) excludes everything
    # it gets what it asks for.
    @install{ $class->_ops( ':all' ) } = 1
        unless %install || @_;

    for my $op ( keys %install ) {

        my $symbol = '(' . $op;

        my $glob = overload::mycan( $into, $symbol );
        next unless defined $glob;

        my $coderef = *{$glob}{CODE};
        next unless defined $coderef;

        # method name ?
        my $original_method_name;
        if (
            ( defined &overload::nil && $coderef == \&overload::nil )
            || ( defined &overload::_nil
                && $coderef == \&overload::_nil ) )
        {
            $original_method_name = ${ *{$glob}{SCALAR} };
            # weird but possible?
            next unless defined $original_method_name;
        }

        my $new_method_name = $method_name_prefix . $OP{$op};

        # it's a real method; only rewire if requested to do so
        if ( defined $original_method_name ) {
            next unless $wrap_methods;

            # if it's the same name, we'll simply pick it up via
            # inheritance
            next if $original_method_name eq $new_method_name;

            ## no critic(ProhibitStringyEval)
            $coderef
              = eval "package $into; sub { shift()->$original_method_name(\@_) }";
        }

        _install_overload( $into, $symbol, $new_method_name, $coderef, $redefine_methods );
    }
}

sub _install_overload {

    my ( $into, $symbol, $method_name, $coderef, $redefine ) = @_;

    # if not overwriting, make sure there's nothing there
    unless ( $redefine ) {

        Carp::croak( "${into}::${_} would be redefined" )
          for grep { _is_existing_method( $into, $_ ) }
            $symbol, $method_name;
    }

    no warnings 'redefine';
    *{ _getglob( "${into}::${method_name}") } = $coderef;
    my $glob  = _getglob ("${into}::${symbol}");
    *$glob = \$method_name;
    *$glob = defined &overload::nil ? \&overload::nil : \&overload::_nil;
}

# stolen from Role::Tiny
sub _getglob {
    ## no critic( ProhibitNoStrict )
    no strict 'refs';
    \*{ $_[0] };
}


# don't create a symbol table entry if we can help it
sub _get_existing_glob {
    my ( $package, $name ) = @_;
    ## no critic( ProhibitNoStrict )
    no strict 'refs';

    exists ${"${package}::"}{$name} ? _getglob( "${package}::${name}" ) : undef;

}

sub _is_existing_method {

    my ( $package, $name ) = @_;

    my $glob = _get_existing_glob( $package, $name );

    return defined $glob ? defined *{$glob}{CODE} : 0;
}

#pod =method tag_to_ops
#pod
#pod   @ops = overload::reify->tag_to_ops( $tag );
#pod
#pod Return a list of operators correspond to the passed tag.  A tag is a string which
#pod is either
#pod
#pod =over
#pod
#pod =item *
#pod
#pod an operator, e.g. C<'++'>; or
#pod
#pod =item *
#pod
#pod a string (in the form C<:>I<class>) representing a class
#pod of operators. A class may be any of the keys accepted by the
#pod L<overload|overload/Overloadable Operations> pragma, as well as the
#pod special class C<all>, which consists of all operators.
#pod
#pod =back
#pod
#pod =cut

sub tag_to_ops {

    my ( $class, $op ) = @_;

    return $op if defined $OP{$op};
    return keys %OP if $op eq ':all';

    my ( $tag ) = $op =~ /^:(.*)$/;

    Carp::croak( "couldn't parse \$op:  $op\n" )
      if ! defined $tag;

    return grep( $_ ne 'fallback', split( /\s+/, $overload::ops{$tag} ) )
      if defined $overload::ops{$tag};

    return;
}

sub _ops {

    my ( $class, $op ) = @_;

    my @ops = $class->tag_to_ops( $op );

    Carp::croak( "unknown operator or tag: $op\n" )
      unless @ops;

    return @ops;
}

#pod =method method_names
#pod
#pod   # from the command line:
#pod   perl -Ilib -MData::Dumper -Moverload::reify \
#pod      -e 'print Dumper overload::reify->method_names()'
#pod
#pod   # in code
#pod   $hashref = overload::reify->method_names( ?@ops, ?\%options );
#pod
#pod This class method returns the mapping between operators and generated
#pod method names.  Supplied operators are first run through
#pod L</tag_to_ops>.  If no operators are passed, a map for all of the
#pod supported ones is returned.
#pod
#pod The map is returned a hashref whose keys are operators and whose
#pod values are the names of generated methods. The available options are:
#pod
#pod =over
#pod
#pod =item C<-prefix>
#pod
#pod The prefix for the names of the generated method names.  It defaults to
#pod C<operator_>.
#pod
#pod =back
#pod
#pod =cut

sub method_names {

    my $class = shift;

    my %opt = ( -prefix => 'operator_',
                'HASH' eq ref $_[-1] ? %{ pop() } : (),
              );

    my @ops = @_ ? map $class->tag_to_ops( $_ ), @_ : keys %OP;

    return { map +($_ => $opt{-prefix} . $OP{$_}), @ops };
};

1;

#
# This file is part of overload-reify
#
# This software is copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

=pod

=head1 NAME

overload::reify - Provide named methods for inherited overloaded operators

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  { package Parent;
    use overload
      '+=' => 'plus_equals',
      '++' => sub { ... };

    # ...

    sub plus_equals { ... }
  }

  { package Child1;

    use Parent;

    use overload::reify;

    # this creates new methods:
    #
    #  operator_increment()
    #    performs the ++ operation
    #
    #  operator_add_assign()
    #    comparable to plus_equals(), but modifying
    #    it won't modify plus_equals

  }

  { package Child2;

    use Parent;

    # don't create methods for overloads with method names
    use overload::reify { -methods => 0 };

    # this creates new methods:
    #
    #  operator_increment()
    #    performs the ++ operation
  }

=head1 DESCRIPTION

This pragma creates named methods for inherited operator overloads.
The child may then modify them using such packages as L<Moo>,
L<Moose>, or L<Class::Method::Modifers>.

=head2 Background

When a package overloads an operator it provides either a method
name or a code reference, e.g.

  overload
    '++' => 'plus_plus',
    '--' => sub { ..., }

In the latter case, the overloaded subroutine cannot be modified via
e.g., the B<around> subroutine in
L<Class::Method::Modifiers|Class::Method::Modifiers/around> (or
L<Moo|Moo/around> or L<Moose|Moose/around>) as it has no named symbol
table entry.

B<overload::reify> installs named methods for overloaded operators
into a package's symbol table. The method names are constructed by
concatenating a prefix (provided by the C<-prefix> option) and a
standardized operator name (see L</method_names>). An existing method
with the same name will be quietly replaced, unless the L</-redefine> option
is true.

For operators overloaded with a method name which is different from
the new method name, a wrapper which calls the original method by its
name is installed.  If the original and new method names are the same,
nothing is installed.

For operators overloaded with a code reference, an alias to the code
reference is installed.

By default named methods are constructed for I<all> overloaded
operators, regardless of how they are implemented (providing the child
class a uniform naming scheme). If this is not desired, set the
C<-methods> option to false.

=head2 Usage

The pragma is invoked with the following template:

  use overload::reify @operators, ?\%options;

where C<@operators> is a list of strings, each of which may contain:

=over

=item *

an operator to be considered, e.g. C<'++'>;

=item *

a tag (in the form C<:>I<class>) representing a class
of operators. A class may be any of the keys accepted by the
L<overload|overload/Overloadable Operations> pragma, as well as the
special class C<all>, which consists of all operators.

=item *

the token C<-not>, indicating that the next operator is to be excluded
from consideration.  If C<-not> is the first element in the list of
operators, the list is pre-seeded with all of the operators.

=back

and C<%options> is a hash with one or more of the following keys:

=over

=item C<-into>

The package into which the methods will be installed.  This defaults
to the calling package.

=item C<-redefine>

A boolean which if true will cause an exception to be thrown if
installing the new method would replace an existing one of the same
name in the package specified by L</-into>.  Defaults to false.

=item C<-methods>

A boolean indicating whether or not wrappers will be generated for overloaded operators with named methods.  This defaults to I<true>.

=item C<-prefix>

The prefix for the names of the generated method names.  It defaults to
C<operator_>.

=back

=head1 METHODS

=head2 tag_to_ops

  @ops = overload::reify->tag_to_ops( $tag );

Return a list of operators correspond to the passed tag.  A tag is a string which
is either

=over

=item *

an operator, e.g. C<'++'>; or

=item *

a string (in the form C<:>I<class>) representing a class
of operators. A class may be any of the keys accepted by the
L<overload|overload/Overloadable Operations> pragma, as well as the
special class C<all>, which consists of all operators.

=back

=head2 method_names

  # from the command line:
  perl -Ilib -MData::Dumper -Moverload::reify \
     -e 'print Dumper overload::reify->method_names()'

  # in code
  $hashref = overload::reify->method_names( ?@ops, ?\%options );

This class method returns the mapping between operators and generated
method names.  Supplied operators are first run through
L</tag_to_ops>.  If no operators are passed, a map for all of the
supported ones is returned.

The map is returned a hashref whose keys are operators and whose
values are the names of generated methods. The available options are:

=over

=item C<-prefix>

The prefix for the names of the generated method names.  It defaults to
C<operator_>.

=back

=head1 SEE ALSO

L<Class::Method::Modfiers>, L<Moo>, L<Moose>.

=head1 CONTRIBUTORS

Thanks to

=over

=item *

L<MSTROUT|https://metacpan.org/author/MSTROUT> for the
suggestion to house this code in its own module and for the module name.

=item *
L<HAARG|https://metacpan.org/author/HAARG> for reviewing
an initial version of this code.

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


#pod =head1 SYNOPSIS
#pod
#pod   { package Parent;
#pod     use overload
#pod       '+=' => 'plus_equals',
#pod       '++' => sub { ... };
#pod
#pod     # ...
#pod
#pod     sub plus_equals { ... }
#pod   }
#pod
#pod   { package Child1;
#pod
#pod     use Parent;
#pod
#pod     use overload::reify;
#pod
#pod     # this creates new methods:
#pod     #
#pod     #  operator_increment()
#pod     #    performs the ++ operation
#pod     #
#pod     #  operator_add_assign()
#pod     #    comparable to plus_equals(), but modifying
#pod     #    it won't modify plus_equals
#pod
#pod   }
#pod
#pod   { package Child2;
#pod
#pod     use Parent;
#pod
#pod     # don't create methods for overloads with method names
#pod     use overload::reify { -methods => 0 };
#pod
#pod     # this creates new methods:
#pod     #
#pod     #  operator_increment()
#pod     #    performs the ++ operation
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This pragma creates named methods for inherited operator overloads.
#pod The child may then modify them using such packages as L<Moo>,
#pod L<Moose>, or L<Class::Method::Modifers>.
#pod
#pod =head2 Background
#pod
#pod When a package overloads an operator it provides either a method
#pod name or a code reference, e.g.
#pod
#pod   overload
#pod     '++' => 'plus_plus',
#pod     '--' => sub { ..., }
#pod
#pod In the latter case, the overloaded subroutine cannot be modified via
#pod e.g., the B<around> subroutine in
#pod L<Class::Method::Modifiers|Class::Method::Modifiers/around> (or
#pod L<Moo|Moo/around> or L<Moose|Moose/around>) as it has no named symbol
#pod table entry.
#pod
#pod B<overload::reify> installs named methods for overloaded operators
#pod into a package's symbol table. The method names are constructed by
#pod concatenating a prefix (provided by the C<-prefix> option) and a
#pod standardized operator name (see L</method_names>). An existing method
#pod with the same name will be quietly replaced, unless the L</-redefine> option
#pod is true.
#pod
#pod For operators overloaded with a method name which is different from
#pod the new method name, a wrapper which calls the original method by its
#pod name is installed.  If the original and new method names are the same,
#pod nothing is installed.
#pod
#pod For operators overloaded with a code reference, an alias to the code
#pod reference is installed.
#pod
#pod By default named methods are constructed for I<all> overloaded
#pod operators, regardless of how they are implemented (providing the child
#pod class a uniform naming scheme). If this is not desired, set the
#pod C<-methods> option to false.
#pod
#pod =head2 Usage
#pod
#pod The pragma is invoked with the following template:
#pod
#pod   use overload::reify @operators, ?\%options;
#pod
#pod where C<@operators> is a list of strings, each of which may contain:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod an operator to be considered, e.g. C<'++'>;
#pod
#pod =item *
#pod
#pod a tag (in the form C<:>I<class>) representing a class
#pod of operators. A class may be any of the keys accepted by the
#pod L<overload|overload/Overloadable Operations> pragma, as well as the
#pod special class C<all>, which consists of all operators.
#pod
#pod =item *
#pod
#pod the token C<-not>, indicating that the next operator is to be excluded
#pod from consideration.  If C<-not> is the first element in the list of
#pod operators, the list is pre-seeded with all of the operators.
#pod
#pod =back
#pod
#pod and C<%options> is a hash with one or more of the following keys:
#pod
#pod =over
#pod
#pod =item C<-into>
#pod
#pod The package into which the methods will be installed.  This defaults
#pod to the calling package.
#pod
#pod =item C<-redefine>
#pod
#pod A boolean which if true will cause an exception to be thrown if
#pod installing the new method would replace an existing one of the same
#pod name in the package specified by L</-into>.  Defaults to false.
#pod
#pod =item C<-methods>
#pod
#pod A boolean indicating whether or not wrappers will be generated for overloaded operators with named methods.  This defaults to I<true>.
#pod
#pod =item C<-prefix>
#pod
#pod The prefix for the names of the generated method names.  It defaults to
#pod C<operator_>.
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Class::Method::Modfiers>, L<Moo>, L<Moose>.
#pod
#pod =head1 CONTRIBUTORS
#pod
#pod Thanks to
#pod
#pod =over
#pod
#pod =item *
#pod
#pod L<MSTROUT|https://metacpan.org/author/MSTROUT> for the
#pod suggestion to house this code in its own module and for the module name.
#pod
#pod =item *
#pod L<HAARG|https://metacpan.org/author/HAARG> for reviewing
#pod an initial version of this code.
#pod
#pod =back
#pod
