package Type::Simple;

use 5.006;
use strict;
use warnings;

use parent 'Exporter';

use Scalar::Util qw(blessed looks_like_number);
use Carp qw(croak);

our @EXPORT_OK = qw(
  validate
  Any
  Bool
  Maybe
  Undef
  Defined
  Value
  Str
  Alpha
  Alnum
  Ascii
  Num
  Int
  Print
  Punct
  Space
  Word
  Ref
  ScalarRef
  ArrayRef
  HashRef
  HashRefWith
  CodeRef
  RegexpRef
  Object
);

=head1 NAME

Type::Simple - simple type validation system for Perl

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

*validate = \&apply;

sub apply {
    my ( $fn, $x ) = @_;

    if ( ref $fn eq 'CODE' ) {
        return $fn->($x);
    } elsif ( ref $fn eq 'Regexp' ) {
        return $x =~ $fn ? 1 : 0;
    } else {
        croak "Invalid type check $fn (expected CODE or Regexp)";
    }
}

sub AND {
    my (@fn) = @_;
    return sub {
        my ($x) = @_;
        foreach my $fn (@fn) {
            return 0 if not apply( $fn, $x );
        }
        return 1;
    };
}

sub OR {
    my (@fn) = @_;
    return sub {
        my ($x) = @_;
        foreach my $fn (@fn) {
            return 1 if apply( $fn, $x );
        }
        return 0;
    };
}

sub NOT {
    my ($fn) = @_;
    return sub {
        my ($x) = @_;
        return apply( $fn, $x ) ? 0 : 1;
    };
}

sub Any {
    return sub {1};
}

sub Bool {
    return sub {
        my ($x) = @_;

        return 1 if not defined $x;
        return 1 if $x eq '';
        return 1 if $x =~ /^[01]$/;

        return 0;
    };
}

sub Defined {
    return sub {
        my ($x) = @_;
        return defined $x ? 1 : 0;
    };
}

sub Undef {
    return NOT( Defined() );
}

sub Maybe {
    my ($fn) = @_;

    return OR( Undef(), $fn, );
}

sub Ref {
    return AND(
        Defined(),
        sub {
            my ($x) = @_;
            return ref $x ? 1 : 0;
        },
    );
}

sub Value {    # defined and not reference
    return AND( Defined(), NOT( Ref() ), );
}

sub Str {
    return Value();    # same thing as value?
}

sub Alpha {
    return AND(
        Str(),
        sub {
            my ($x) = @_;
            return $x =~ /^[[:alpha:]]+$/ ? 1 : 0;
        },
    );
}

sub Alnum {
    return AND(
        Str(),
        sub {
            my ($x) = @_;
            return $x =~ /^[[:alnum:]]+$/ ? 1 : 0;
        },
    );
}

sub Ascii {
    return AND(
        Str(),
        sub {
            my ($x) = @_;
            return $x =~ /^[[:ascii:]]+$/ ? 1 : 0;
        },
    );
}

sub Print {
    return AND(
        Str(),
        sub {
            my ($x) = @_;
            return $x =~ /^[[:print:]]+$/ ? 1 : 0;
        },
    );
}

sub Punct {
    return AND(
        Str(),
        sub {
            my ($x) = @_;
            return $x =~ /^[[:punct:]]+$/ ? 1 : 0;
        },
    );
}

sub Space {
    return AND(
        Str(),
        sub {
            my ($x) = @_;
            return $x =~ /^[[:space:]]+$/ ? 1 : 0;
        },
    );
}

sub Word {
    return AND(
        Str(),
        sub {
            my ($x) = @_;
            return $x =~ /^[[:word:]]+$/ ? 1 : 0;
        },
    );
}

sub Num {
    return AND(
        Str(),
        sub {
            my ($x) = @_;
            return looks_like_number($x) ? 1 : 0;
        },
    );
}

sub Int {
    return AND(
        Num(),
        sub {
            my ($x) = @_;
            return 1 if $x =~ /^[0-9]+$/;
            return 0;
        },
    );
}

sub ScalarRef {
    return AND(
        Ref(),
        sub {
            my ($x) = @_;
            return ref $x eq 'SCALAR' ? 1 : 0;
        },
    );
}

sub ArrayRef {
    my ($fn) = @_;

    return AND(
        Ref(),
        sub {
            my ($x) = @_;
            return 0 unless ref $x eq 'ARRAY';
            return 1 unless $fn;

            # check items
            foreach my $item ( @{$x} ) {
                return 0 unless apply( $fn, $item );
            }

            return 1;
        },
    );
}

sub HashRef {
    my ($fn) = @_;

    return AND(
        Ref(),
        sub {
            my ($x) = @_;
            return 0 unless ref $x eq 'HASH';
            return 1 unless $fn;

            # check items
            foreach my $key ( keys %{$x} ) {
                return 0 unless apply( $fn, $x->{$key} );
            }

            return 1;
        },
    );
}

sub HashRefWith {
    my (%params) = @_;

    return AND(
        HashRef(),
        sub {
            my ($x) = @_;
            foreach my $key (keys %params) {
                if ($key =~ /^CODE\(0x[0-9a-f]+\)$/) {
                    croak qq{Key "$key" should be a string, not a CODE reference (did you try to use a validation type as a key?)};
                }
                my $fn = $params{$key};
                return 0 unless apply( $fn, $x->{$key} );
            }

            return 1;
        },
    );
}

sub CodeRef {
    return AND(
        Ref(),
        sub {
            my ($x) = @_;
            return ref $x eq 'CODE' ? 1 : 0;
        },
    );
}

sub RegexpRef {
    return AND(
        Ref(),
        sub {
            my ($x) = @_;
            return ref $x eq 'Regexp' ? 1 : 0;
        },
    );
}

sub Object {
    return AND(
        Ref(),
        sub {
            my ($x) = @_;
            return blessed $x ? 1 : 0;
        },
    );
}

=head1 SYNOPSIS

    use Type::Simple qw(:all);

    # simple values
    validate( Int(), 123 );     # -> true
    validate( Str(), 'xyz' );   # -> false

    # array and hash references
    validate( ArrayRef(Int()), [ 1, 2, 3 ] );            # -> true
    validate( HashRef(Bool()), { foo => 1, bar => 0 } ); # -> true

    # hash references with specific keys and value types
    validate(
        HashRefWith( foo => Int(), bar => Int() ),
        { foo => 1 },
    ); # -> false, because you didn't provide key "bar"

    validate(
        HashRefWith( foo => Int(), bar => Maybe(Int()) ),
        { foo => 1 },
    ); # -> true, because "bar" is Maybe()

Check the test suite for many more examples!

You can pass your own validation functions as code references:

    my $greater_than_one = sub { $_[0] > 1  };
    my $less_than_ten    = sub { $_[0] < 10 };

    validate( $greater_than_one, 50 );   # -> true
    validate( $less_than_ten,    50 );   # -> false

It's possible to combine and modify tests using the boolean functions
C<Type::Simple::AND()>, C<Type::Simple::OR()> and C<Type::Simple::NOT()>:

    validate(
        Type::Simple::OR( CodeRef(), RegexpRef() ),
        $code_or_regexp,
    );

    validate(
        Type::Simple::AND(
            Num(),
            $greater_than_one,
            $less_than_ten
        ),
        $number
    );

    validate(
        Type::Simple::AND(
            Num(),
            Type::Simple::NOT(Int()),
        ),
        $non_integer_number
    );

=head1 DESCRIPTION

    Any
        Bool
        Maybe(`a)
        Undef
        Defined
            Value
                Str
                    Alpha
                    Alnum
                    Ascii
                    Num
                        Int
                    Print
                    Punct
                    Space
                    Word
            Ref
                ScalarRef
                ArrayRef(`a)
                HashRef(`a)
                    HashRefWith( k1 => `a, k2 => `b, ... )
                CodeRef
                RegexpRef
                Object

=head1 EXPORT

None by default.

All the subroutines below can be exported:

=head1 SUBROUTINES

=head2 validate( type, value)

Try to validate a value using a type. Example:

    validate( Num(), 123 ); # -> true
    validate( Num(), 'x' ); # -> false

The validation functions are the following:

=head2 Any()

Anything.

=head2 Bool()

Perl boolean values: C<1>, C<0>, C<''> and C<undef>.

=head2 Maybe(`a)

Type `a or C<undef>.

=head2 Undef()

C<undef>.

=head2 Defined()

Defined value. (Not C<undef>)

=head2 Value()

Number or string. (Not references)

=head2 Str()

String.

Since numbers can be stringified, it will also accept numbers.
If you want a non-numeric string, you can use:

    Type::Simple::AND(
        Str(),
        Type::Simple::NOT(Num()),
    );

=head2 Alpha()

A string of alphabetical characters (C<[A-Za-z]>).

=head2 Alnum()

A string of alphanumeric characters (C<[A-Za-z0-9]>)

=head2 Ascii()

A string of characters in the ASCII character set.

=head2 Num()

Looks like a number.

=head2 Int()

An integer.

=head2 Print()

A string of printable characters, including spaces.

=head2 Punct()

A string of non-alphanumeric, non-space characters
(C<<[-!"#$%&'()*+,./:;<=>?@[\\\]^_`{|}~]>>).

=head2 Space()

A string of whitespace characters (equivalent to C<\s>).

=head2 Word()

A string of word characters (C<[A-Za-z0-9_]>, equivalent to C<\w>).

=head2 Ref()

A reference.

=head2 ScalarRef()

A scalar reference.

=head2 ArrayRef(`a)

An array reference.

If you specify `a, the array elements should be of type `a.

=head2 HashRef(`a)

A hash reference.

If you specify `a, all values should be of type `a.

=head2 HashRefWith( k1 => `a, k2 => `b, ... )

A hash reference with a given set of keys and value types.

Attention: keys MUST be strings!

    HashRefWith( foo => Int()   );  # good
    HashRefWith( Str() => Int() );  # bad! Key should be a string, not a CODE reference

=head2 CodeRef()

A code reference.

=head2 RegexpRef()

A regexp reference.

=head2 Object()

A blessed object.

=head1 AUTHOR

Nelson Ferraz, C<< <nferraz at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/nferraz/type-simple/issues>.  I will be notified,
and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Type::Simple

You can also look for information at:

=over 4

=item * GitHub

L<http://github.com/nferraz/type-simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Type-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Nelson Ferraz.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1;    # End of Type::Simple
