package Validate::Simple;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp;

use Scalar::Util qw/looks_like_number/;
use Data::Types qw/:all/;

use Data::Dumper;

my $VALUES_OF_ENUM = '__ VALUES __ OF __ ENUM __';

# Constructor
#
sub new {
    my ( $class, $specs ) = @_;

    if ( defined $specs && ref $specs ne 'HASH' ) {
        croak "Specification must be a hashref";
    }

    my $self = bless {
        specs => $specs,
        _errors => [],
    }, $class;

    if ( defined $specs && keys %$specs ) {
        $self->validate_specs( $specs );
    }

    return $self;
}

# Registe validation error
#
# Pushes an error to the list of errors
#
sub _error {
    my ( $self, $error ) = @_;

    if ( $error ) {
        push @{ $self->{_errors} }, $error;
    }

    return;
}


# List of validatioon errors
#
sub errors {
    return wantarray ? @{ $_[0]->{_errors} } : $_[0]->{_errors};
}

# Deletes all collected errors and returns them
#
sub delete_errors {
    my ( $self ) = @_;
    my @errors = $self->_error();
    $self->{_errors} = [];
    return @errors;
}



# Specifications of specification

my @all_types = qw/
                      any
                      number
                      positive
                      non_negative
                      negative
                      non_positive
                      integer
                      positive_int
                      non_negative_int
                      negative_int
                      non_positive_int
                      string
                      array
                      hash
                      enum
                      code
                  /;

my @number_types = qw/
                         number
                         positive
                         non_negative
                         negative
                         non_positive
                         integer
                         positive_int
                         non_negative_int
                         negative_int
                         non_positive_int
                     /;

my @string_types = ( 'string' );

my @list_types = qw/
                       array
                       hash
                   /;

my @enum_types = ( 'enum' );

# Common for all
my %any = (
    required => {
        type  => 'any',
    },
    undef => {
        type => 'any',
    },
    callback => {
        type => 'code',
    },
);

# Common for numbers
my %number = (
    gt => {
        type => 'number',
    },
    ge => {
        type => 'number',
    },
    lt => {
        type => 'number',
    },
    le => {
        type => 'number',
    },
);

# Common for strings
my %string = (
    min_length => {
        type => 'positive_int',
    },
    max_length => {
        type => 'positive_int',
    },
);

# Common for lists
my %list = (
    empty => {
        type => 'any',
    },
    of => {
        type     => 'hash',
        of       => {
            type => 'any',
        },
        required => 1,
    },
);

# Common for enums
my %enum = (
    values => {
        type     => 'array',
        of       => {
            type => 'string',
        },
        required => 1,
    },
    $VALUES_OF_ENUM => {
        type => 'hash',
        of => {
            type => 'string',
            undef => 1,
        },
        empty => 1,
    },
);

# Specification of specification format
my %specs_of_specs = (
    any        => { %any },
    ( map { $_ => { %any, %number } } @number_types ),
    ( map { $_ => { %any, %string } } @string_types ),
    ( map { $_ => { %any, %list   } } @list_types ),
    ( map { $_ => { %any, %enum   } } @enum_types ),
);

for my $key ( keys %specs_of_specs ) {
    $specs_of_specs{ $key }{type} = {
        type     => 'enum',
        values   => [ $key ],
        required => 1,
    };
}

# Validate functions per type
my %validate = ( any => sub { 1; } );
for my $type ( @all_types ) {
    next if $type eq 'any';
    $validate{ $type } = sub { __PACKAGE__->$type( @_ ) };
}

# Returns specification of specification
#
sub spec_of_specs {
    return $specs_of_specs{ $_[1] };
}

# Validates parameters according to specs
#
sub validate {
    my ( $self, $params, $specs ) = @_;

    # If $specs is not passed, use the one created in constructor,
    # and skip specs validation
    my $skip_specs_validation = 1;
    if ( !defined $specs ) {
        $specs //= $self->{specs};
        $skip_specs_validation = 0;
    }

    # If specs are not known
    # do not pass
    return if !defined $specs;

    # Clear list of errors
    $self->delete_errors();

    # If params are not HASHREF or undef
    # do not pass
    unless ( $self->hash( $params ) ) {
        $self->_error("Expected a hashref for params");
        return;
    }

    # Check parameters
    my $ret = $self->_validate( $params, $specs, $skip_specs_validation );

    return $ret;
}


# Validate specs against predefined specs
#
# Here we consider specs as params and validate
# them against rules, which are stored in %specs_of_specs
#
sub validate_specs {
    my ( $self, $specs, $path_to_var ) = @_;

    # This variable contains path to the variable name
    $path_to_var //= '';

    unless ( $self->hash( $specs ) ) {
        $self->_error( "Specs MUST be a hashref" );
        return;
    }

    while ( my ( $variable, $spec ) = each %$specs ) {
        my $p2v = "$path_to_var/$variable";
        unless ( $self->hash( $spec ) ) {
            $self->_error( "Each spec MUST be a hashref: $p2v" );
            return;
        }
        my $type = exists $spec->{type}
            ? $spec->{type}
            : ( $spec->{type} = 'any' );

        # Known type?
        if ( !exists $specs_of_specs{ $type } ) {
            $self->_error( "Unknown type '$type' in specs of $p2v" );
            return;
        }

        # Validate spec
        my $spec_of_spec = $specs_of_specs{ $type };
        if ( !$self->_validate( $spec, $spec_of_spec, 'skip_specs_validation' ) ) {
            $self->_error( "Bad spec for variable $p2v, should be " . Dumper( $spec_of_spec ) );
            return;
        }

        # Check spec of 'of'
        if ( exists $spec->{of} && !$self->validate_specs( { of => $spec->{of} }, $p2v ) ) {
            return;
        }
    }

    return 1;
}

# Actual validation of parameters
#
sub _validate {
    my ( $self, $params, $specs, $skip_specs_validation ) = @_;

    # Check mandatory params
    return
        unless $self->required_params( $params, $specs );

    # Check unknown params
    return
        unless $self->unknown_params( $params, $specs );

    if ( !$skip_specs_validation && !$self->validate_specs( $specs ) ) {
        return;
    }

    while( my ( $name, $value ) = each %$params ) {
        if ( !exists $specs->{ $name } ) {
            $self->_error( "Can't find specs for $name" );
            return;
        }
        my $spec = $specs->{ $name };

        my $valid = $self->validate_value( $value, $spec );
        return unless $valid;
    }

    return 1;
}

# Checks whether all required params exist
#
sub required_params {
    my ( $self, $params, $specs ) = @_;

    my $ret = 1;
    for my $par ( keys %$specs ) {
        my $spec = $specs->{ $par };
        if ( exists $spec->{required} && $spec->{required} ) {
            if ( !exists $params->{ $par } ) {
                $self->_error( "Required param '$par' does not exist" );
                $ret = 0;
            }
        }
    }

    return $ret;
}

# Check whether unknown params exist
#
sub unknown_params {
    my ( $self, $params, $specs ) = @_;

    my $ret = 1;
    for my $par ( keys %$params ) {
        if ( !exists $specs->{ $par } ) {
            $self->_error("Unknown param '$par'");
            $ret = 0;
        }
    }

    return $ret;
}


# Valdates value against spec
#
sub validate_value {
    my ( $self, $value, $spec ) = @_;

    my $type = $spec->{type} || 'any';
    my $undef = exists $spec->{undef} && $spec->{undef};

    # If undef value is allowed and the value is undefined
    # do not perform any furrther validation
    if ( $undef && !defined $value ) {
        return 1;
    }

    my @other = ();
    # Enum
    if ( $type eq 'enum' ) {
        # Create a hash
        if ( !exists $spec->{ $VALUES_OF_ENUM } ) {
            $spec->{ $VALUES_OF_ENUM }{$_} = undef
                for @{ $spec->{values} };
        }
        push @other, $spec->{ $VALUES_OF_ENUM };
    }

    # Check type
    unless ( $validate{ $type }->( $value, @other ) ) {
        $self->_error( ( $value // '[undef]') . " is not of type '$type'" );
        return;
    }

    # Check greater than
    if ( exists $spec->{gt} ) {
        if ( $spec->{gt} >= $value ) {
            $self->_error( ( $value // '[undef]') . " > $spec->{gt} return false" );
            return;
        }
    }

    # Check greater or equal
    if ( exists $spec->{ge} ) {
        if ( $spec->{ge} > $value ) {
            $self->_error( ( $value // '[undef]') . " >= $spec->{ge} returns false" );
            return;
        }
    }

    # Check less than
    if ( exists $spec->{lt} ) {
        if ( $spec->{lt} <= $value ) {
            $self->_error( ( $value // '[undef]') . " < $spec->{lt} returns false" );
            return;
        }
    }

    # Check less or equal
    if ( exists $spec->{le} ) {
        if ( $spec->{le} < $value ) {
            $self->_error( ( $value // '[undef]') . " <= $spec->{le} returns false" );
            return;
        }
    }

    # Check min length
    if ( exists $spec->{min_length} ) {
        if ( $spec->{min_length} > length( $value // '' ) ) {
            $self->_error( 'length(' . ( $value // '[undef]') . " > $spec->{min_length} returns false" );
            return;
        }
    }

    # Check max length
    if ( exists $spec->{max_length} ) {
        if ( $spec->{max_length} < length( $value // '' ) ) {
            $self->_error( 'length(' . ( $value // '[undef]') . " < $spec->{max_length} returns false" );
            return;
        }
    }

    # Check of
    if ( exists $spec->{of} ) {
        my @values;
        if ( $type eq 'array' ) {
            @values = @$value;
        }
        elsif ( $type eq 'hash' ) {
            @values = values %$value;
        }
        else {
            $self->_error( "Cannot set elements types for $type" );
            return;
        }

        if ( !@values ) {
            if ( !exists $spec->{empty} || !$spec->{empty} ) {
                $self->_error( ucfirst( $type ) . " cannot be empty" );
                return;
            }
        }

        for my $v ( @values ) {
            return
                unless $self->validate_value( $v, $spec->{of} );
        }
    }

    # Check code
    if ( exists $spec->{callback} ) {
        if ( !$spec->{callback}->( $value, @other ) ) {
            $self->_error("Callback returned false");
            return;
        }
    }
    return 1;
}



# Primitives
# ==========
sub number {
    return looks_like_number( $_[1] );
}

sub positive {
    return $_[0]->number( $_[1] ) && $_[1] > 0;
}

sub non_negative {
    return $_[0]->number( $_[1] ) && $_[1] >= 0;
}

sub negative {
    return $_[0]->number( $_[1] ) && $_[1] < 0;
}

sub non_positive {
    return $_[0]->number( $_[1] ) && $_[1] <= 0;
}

sub integer {
    return is_int( $_[1] );
}

sub positive_int {
    return is_count( $_[1] );
}

sub non_negative_int {
    return is_whole( $_[1] );
}

sub negative_int {
    return $_[0]->integer( $_[1] ) && $_[1] < 0;
}

sub non_positive_int {
    return $_[0]->integer( $_[1] ) && $_[1] <= 0;
}

sub string {
    return is_string( $_[1] );
}

sub array {
    return ref $_[1] eq 'ARRAY';
}

sub hash {
    return ref $_[1] eq 'HASH';
}

sub enum {
    return $_[0]->string( $_[1] ) && exists $_[2]->{$_[1]};
}

sub code {
    return ref $_[1] eq 'CODE';
}

1;


__END__

=head1 NAME

Validate::Simple - (Relatively) Simple way to validate input parameters

=head1 SYNOPSIS

    use Validate::Simple;

    my $specs = {
        username => {
            type     => 'string',
            required => 1,
        },
        first_name => {
            type     => 'string',
            required => 1,
        },
        last_name => {
            type => 'string',
        },
        age => {
            type => 'integer',
            gt   => 18,
        },
        gender => {
            type   => 'enum',
            values => [
                'mail',
                'femaile',
                'id_rather_not_to_say',
            ],
        },
        tags => {
            type => 'array',
            of   => {
                type => 'string',
            },
        },
        hobbies => {
            type => 'array',
            of   => {
                type =>'enum',
                values => [ qw/hiking travelling surfing laziness/ ],
            }
        },
        score => {
            type => 'hash',
            of   => 'non_negative_int',
        },
        monthly_score => {
            type => 'hash',
            of   => {
                type => 'hash',
                of   => {
                    type     => 'arrray',
                    callback => sub {
                        @{ $_[0] } < 12;
                    },
                }
            },
        }
    };

    my $vs1 = Validate::Simple->new( $specs );
    my $is_valid1 = $vs1->validate( $params );
    print join "\n", $$vs1->errors()
        if !$is_valid1;

    # Or

    my $vs2 = Validate::Simple->new();
    my $is_valid2 = $vs2->validate( $params, $specs );
    print join "\n", $vs2->errors()
        if !$is_valid2;

=head1 DESCRIPTION

The module validates parameters against specifications.

=head1 LOGIC

The general use case is the like this.

You have a from handler or a handler of an API endpoint. It receives a
hashref as a parameter. You want to make sure that the input hashref
has all the required keys, you do not have unknown keys, and all the
values satisfy certain criterias: type, size and other constraints...

C<Validate::Simple> allows you to specify criterias for each input
parameter in a (relatively) simple form and validate user input against
your specification as many times as you need. A specification is just a
hashref. The keys repeat parameters names, the values define criterias.

For example:

    my $spec = {
        username => {
            type       => 'string',
            required   => 1,
            min_length => 1,
            max_length => 255,
        },
        password => {
            type       => 'string',
            required   => 1,
            min_length => 12,
        },
        subscriptions => {
            type  => 'array',
            empty => 0,
            of    => {
                type => 'positive_int',
            },
        }
    };

This specification can be used to validate a sign up form. Validation
passes only if user enters a non-empty username no longer than 255
character, a password no shorter than 12 characters and chooses 0 or more
subscriptions (which are supposed to be provided as a list of IDs, i.e.
positive integers. The list of subscriptions may absent (no C<required>
key in the rule), but if it exists, it cannot be empty (because of the
value of the C<empty> key is set to C<0>).

If input data contains a key C<'remember_me'>, validation fails, because
specification does not define rules for this key.

=head1 EXPORT

This module does not export anything. It is supposed to be used in OOP
approach only.

=head1 SPECIFICATIONS (SPECS)

Specifications are the rules that describe which parameters are expected,
their types and constraints (like lengths of strings or signs of
numbers). Specification is just a hashref, the keys are parameters names,
and the values describe criterias.

Every description B<must> have a C<type> key, and B<may> have the keys
C<required>, C<undef> and C<callback>.

=head2 Common specs keys

=head3 C<type>

The value of C<type> defines an expected type of a parameter. You can
learn more about supported types in the L</"Types"> section.

=head3 C<required>

When it is set to a true value, the parameter is required, and, if it is
not in the input data, the form is considered invalid. When it is set to
a false value or does not exists, the parameter is optional.

=head3 C<undef>

By default none parameters can be undefined. If you expect some values
to be undefined, you need to explicitly set this key to true.

For example, if you allow the value of the param to be literally
anything, you can do the following:

    my $spec = {
        whatever => {
            type  => 'any',
            undef => 1,
        }
    };

=head3 C<callback>

If you have some special constraints to a value that does not fit to any
of supported L<types|/"Types">, you can specify your own validation
function and pass it to C<callback> key as a coderef. The function should
receive the value as a first parameter and returns true or false.

For example, if you need to check whether a value is an even positive
integer, you can do the following:

    my $spec = {
        even_positive => {
            type     => "positive_int",
            callback => sub { !( $_[0] % 2 ) },
        },
    };

In case of the L</"enum"> type, the second parameter is the hashref with
the keys of allowed enum values.

The callback function is called B<after> checking the type and
constraints.

=head2 Types

=head3 any

The value can be of any type (including array or hash), except C<undef>.

=head3 Number types

All number types support the following keys:

=over

=item gt

Greater than.

=item ge

Greater than or equal to.

=item lt

Less than.

=item le

Less than or equal to.

=back

For example, the following spec checks whether it's a valid month number:

    my $spec = {
        month => {
            type => 'positive_int',
            le   => 12,
        },
    };

=head4 number

The value is a valid number. On the backstage it simply performs
L<looks_like_number|Scalar::Util/looks_like_number> from
L<Scalar::Util>.

=head4 positive

Same as L</number>, and checks whether it's greater than 0.

=head4 non_negative

Same as L</number>, and checks whether it's greater than or equal to 0.

=head4 negative

Same as L</number>, and checks whether it's greater than 0.

=head4 non_positive

Same as L</number>, and checks whether it's less than or equal to 0.

=head4 integer

The value is an integer. It performs L<is_int|Data::Types/is_int> from
L<Data::Types>.

=head4 positive_int

The value is a positive integer. It performs
L<is_count|Data::Types/is_count> from L<Data::Types>.

=head4 non_negative_int

The value is a non-negative integer. It performs
L<is_whole|Data::Types/is_whole> from L<Data::Types>.

=head4 negative_int

The value is a negative integer.

=head4 non_positive_int

The value is a non-positive integer.

=head3 string

The value is a string. It performs L<is_string|Data::Types/is_string>
from L<Data::Types>.

B<NOTE:> Any number is a valid string, so both
C<$params1 = { string_param =E<gt> 5 };> and
C<$params1 = { string_param =E<gt> "5" };> will pass.

You can add constraints to the string length, by adding keys
C<max_length> and C<min_length>. Either key must be a positive integer.

=head3 List types

The list types B<must> have the key C<of>, which contains a spec of all
list values. For example:

    my $spec = {
        ids => {
            type => 'array',
            of   => {
                type => 'positive_int',
            },
        },
        placeholders => {
            type => 'hash',
            of   => {
                type => 'string',
            },
        },
    };

As long as the C<of> key expects another specification, you can easily
validate complex structures, like array of arrays of strings, hash of
arrays of hashes of enums, arrays of hashes of arrays of arrays of any,
and so on.

By default lists cannot be empty. If you expect an empty list, you
should add a key C<empty> and set it to a true value.

=head4 array

The value is an arrayref.

=head4 hash

The value is a hashref.

=head3 enum

The value is one of the predefined list.

Enum type always contains a string. The list of predefined strings is
provided in the C<values> key, which is B<required> for enums:

    my $spec = {
        data_types => {
            type   => 'enum',
            values => [
                qw/
                      any
                      number
                      positive
                      non_negative
                      negative
                      non_positive
                      integer
                      positive_int
                      non_negative_int
                      negative_int
                      non_positive_int
                      string
                      array
                      hash
                      enum
                      code
                /
            ],
        }
    };

=head3 code

The value is a coderef. L<Validate::Simple> only checks the type, it
B<does not> run the code and B<does not> check its result.

=head1 METHODS

=head2 new( \%spec )

Creates an object. The parameter is optional, though it's recomended to
pass it, because in this case it checks specs syntax only once, not on
each call of C<validate> method.

=head2 validate( \%params, \%specs )

Does validation of the C<\%params> against C<\%specs>. If C<\%specs> is
not provided, it performs validation against the spec, given in the
C<new> method.

=head2 errors

Returns the list of validation errors.

=head1 BUGS

Not reported... Yet...

=head1 SEE ALSO

=head1 AUTHOR

Andrei Pratasavitski <andreip@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
