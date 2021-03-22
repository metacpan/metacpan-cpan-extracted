package Validate::Simple;

use strict;
use warnings;

our $VERSION = 'v0.4.1';

use Carp;

use Scalar::Util qw/blessed looks_like_number/;
use Data::Types qw/:all/;

use Data::Dumper;

my $VALUES_OF_ENUM  = '__ VALUES __ OF __ ENUM __';
my $VALIDATE_OBJECT = '__ VALIDATE __ OBJECT __';

# Constructor
#
sub new {
    my ( $class, $specs, $all_errors ) = @_;

    if ( defined( $specs ) && ref( $specs ) ne 'HASH' ) {
        croak "Specification must be a hashref";
    }

    my $self = bless {
        specs      => $specs,
        all_errors => !!$all_errors,
        required   => 0,
        _errors    => [],
    }, $class;

    if ( defined( $specs ) && keys( %$specs ) ) {
        $self->validate_specs( $specs, \$self->{required} )
            || croak "Specs is not valid: " . join( ";\n", $self->errors() );
    }

    return $self;
}

# Register validation errors
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
    my @errors = $self->errors();
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
                      spec
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

my @spec_types = ( 'spec' );

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
    re         => {
        type     => 'any',
        callback => sub { ref( $_[0] ) eq 'Regexp' }
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

# Common for spec
my %spec = (
    of => {
        type     => 'hash',
        of       => {
            type => 'any',
        },
        required => 1,
        empty    => 0,
    },
    $VALIDATE_OBJECT => {
        type     => 'any',
        callback => sub {
            # Must be an object that implements method 'validate'
            return blessed( $_[0] ) && $_[0]->isa(__PACKAGE__);
        },
    },
);

# Specification of specification format
my %specs_of_specs = (
    ( map { $_ => { specs => { %any } } } qw/any code/ ),
    ( map { $_ => { specs => { %any, %number } } } @number_types ),
    ( map { $_ => { specs => { %any, %string } } } @string_types ),
    ( map { $_ => { specs => { %any, %list   } } } @list_types ),
    ( map { $_ => { specs => { %any, %enum   } } } @enum_types ),
    ( map { $_ => { specs => { %any, %spec   } } } @spec_types ),
);

for my $key ( keys %specs_of_specs ) {
    $specs_of_specs{ $key }{specs}{type} = {
        type            => 'enum',
        # Here we need both 'values' and "$VALUES_OF_ENUM"
        # to pass 'validate_specs'
        values          => [ $key ],
        $VALUES_OF_ENUM => { $key => undef },
        required        => 1,
    };
    my $required = 0;
    for my $k ( keys %{ $specs_of_specs{ $key }{specs} } ) {
        $required++
            if exists $specs_of_specs{ $key }{specs}{ $k }{required};
    }
    $specs_of_specs{ $key }{required} = $required;
}

# Validate functions per type
$specs_of_specs{any}{validate} = sub { 1; };
for my $type ( @all_types ) {
    next if $type eq 'any';
    $specs_of_specs{ $type }{validate} = sub { __PACKAGE__->$type( @_ ) };
}

# Returns specification of specification
#
sub spec_of_specs {
    return $specs_of_specs{ $_[1] };
}

# Validates parameters according to specs
#
sub validate {
    my ( $self, $params, $specs, $all_errors ) = @_;

    # Clear list of errors
    $self->delete_errors();

    $all_errors //= $self->{all_errors};
    $all_errors = !!$all_errors;
    my $req = 0;
    # If $specs is not passed, use the one created in constructor,
    # and skip specs validation
    if ( !defined( $specs ) ) {
        $specs //= $self->{specs};
        # If $specs is still not known
        # do not pass
        if ( !defined( $specs ) ) {
            croak 'No specs passed';
        }
        $req = $self->{required};
    }
    # Otherwise, validate specs first
    elsif ( !$self->validate_specs( $specs, \$req, '', $all_errors ) ) {
        croak 'Specs is not valid: ' . join( '; ', $self->errors() );
    }

    # If params are not HASHREF or undef
    # do not pass
    unless ( $self->hash( $params ) ) {
        $self->_error( "Expected a hashref for params" );
        return;
    }

    # Check parameters
    my $ret = $self->_validate( $params, $specs, \$req, $all_errors );

    return $ret;
}


# Validate specs against predefined specs
#
# Here we consider specs as params and validate
# them against rules, which are stored in %specs_of_specs
#
sub validate_specs {
    my ( $self, $specs, $req, $path_to_var, $all_errors ) = @_;

    # This variable contains path to the variable name
    $path_to_var //= '';
    $all_errors //= $self->{all_errors};
    $all_errors = !!$all_errors;

    unless ( $self->hash( $specs ) ) {
        $self->_error( "Specs MUST be a hashref" );
        return;
    }

    if ( !$req ) {
        $self->_error( "No variable to remember amount of required params" );
        return;
    }

    if ( ref( $req ) ne 'SCALAR' ) {
        $self->_error( "Scalar reference is expected" );
    }

    for my $variable ( keys %$specs ) {
        my $spec = $specs->{ $variable };
        my $p2v = "$path_to_var/$variable";
        unless ( $self->hash( $spec ) ) {
            $self->_error( "Each spec MUST be a hashref: $p2v" );
            return;
        }
        my $type = exists( $spec->{type} )
            ? $spec->{type}
            : ( $spec->{type} = 'any' );

        # Known type?
        if ( !exists $specs_of_specs{ $type }{specs} ) {
            $self->_error( "Unknown type '$type' in specs of $p2v" );
            return;
        }


        # Validate spec
        my $spec_of_spec = $specs_of_specs{ $type }{specs};
        if ( !$self->_validate( $spec, $spec_of_spec, \$specs_of_specs{ $type }{required} ) ) {
            $self->_error( "Bad spec for variable $p2v, should be " . Dumper( $spec_of_spec ) );
            return;
        }

        # Transform enum values into a hash
        if ( $type eq 'enum' ) {
            $spec->{ $VALUES_OF_ENUM }{$_} = undef
                for @{ $spec->{values} };
        }

        # Subspec
        if ( $type eq 'spec' ) {
            my $create_error;
            my $vs = eval {
                blessed( $self )->new( $spec->{of}, $all_errors );
            } or do {
                $create_error = $@ || 'Zombie error';
            };
            if ( $create_error ) {
                $self->_error( $create_error );
                return;
            }
            my @errors = $vs->delete_errors();
            if ( @errors ) {
                $self->_error( "Subspec '$p2v' is invalid: $_" )
                    for @errors;
                return;
            }
            $spec->{ $VALIDATE_OBJECT } = $vs;
        }
        elsif ( exists( $spec->{of} ) && !$self->validate_specs( { of => $spec->{of} }, \( my $r = 0), $p2v, $all_errors ) ) {
            $self->_error( "Bad 'of' spec for variable $p2v" );
            return;
        }

        # Calculate amount of rerquired params
        $$req++
            if exists( $spec->{required} ) && $spec->{required};
    }

    return 1;
}

# Actual validation of parameters
#
sub _validate {
    my ( $self, $params, $specs, $required, $all_errors ) = @_;

    my $req = $$required;
    for my $name ( keys %$params ) {
        if ( !exists $specs->{ $name } ) {
            $self->_error( "Unknown param '$name':\n"
                           . Dumper($params) . "\n"
                           . Dumper($specs)
                       );
            if ( $all_errors ) {
                next;
            }
            else {
                last;
            }
        }

        my $value = $params->{ $name };
        my $spec  = $specs->{ $name };
        $req--
            if exists( $spec->{required} ) && $spec->{required};

        my $valid = $self->validate_value( "/$name", $value, $spec, $all_errors );
        last if !$valid && !$all_errors;
    }

    # Not all required params found
    # Check, what is missing
    if ( $req ) {
        $self->required_params( $params, $specs );
    }

    return @{ $self->{_errors} } ? 0 : 1;
}

# Checks whether all required params exist
#
sub required_params {
    my ( $self, $params, $specs ) = @_;

    for my $par ( keys %$specs ) {
        my $spec = $specs->{ $par };
        if ( exists( $spec->{required} ) && $spec->{required} ) {
            if ( !exists $params->{ $par } ) {
                $self->_error( "Required param '$par' does not exist" );
            }
        }
    }

    return;
}

# Valdates value against spec
#
sub validate_value {
    my ( $self, $name, $value, $spec, $all_errors ) = @_;

    my $type = $spec->{type} || 'any';
    my $undef = exists( $spec->{undef} ) && $spec->{undef};

    # If undef value is allowed and the value is undefined
    # do not perform any furrther validation
    if ( $undef && !defined( $value ) ) {
        return 1;
    }

    my @other = ();
    # Enum
    if ( $type eq 'enum' ) {
        push @other, $spec->{ $VALUES_OF_ENUM };
    }

    # Spec
    if ( $type eq 'spec' ) {
        push @other, $spec->{ $VALIDATE_OBJECT };
    }

    # Check type
    unless ( $specs_of_specs{ $type }{validate}->( $value, @other ) ) {
        if ( $type eq 'spec' ) {
            $self->_error( $name . ( /^\// ? '' : ': ' ) . $_ )
                for $other[0]->errors();
        } else {
            my $expl = $type eq 'enum'
                ? ( ": " . Dumper( $spec->{values} ) )
                : '';
            $self->_error( "$name: >> " . ( $value // '[undef]') . " << is not of type '$type'$expl" );
        }
        return;
    }

    # Check greater than
    if ( exists $spec->{gt} ) {
        if ( $spec->{gt} >= $value ) {
            $self->_error( "$name: " . ( $value // '[undef]') . " > $spec->{gt} returns false" );
            return;
        }
    }

    # Check greater or equal
    if ( exists $spec->{ge} ) {
        if ( $spec->{ge} > $value ) {
            $self->_error( "$name: " . ( $value // '[undef]') . " >= $spec->{ge} returns false" );
            return;
        }
    }

    # Check less than
    if ( exists $spec->{lt} ) {
        if ( $spec->{lt} <= $value ) {
            $self->_error( "$name: " . ( $value // '[undef]') . " < $spec->{lt} returns false" );
            return;
        }
    }

    # Check less or equal
    if ( exists $spec->{le} ) {
        if ( $spec->{le} < $value ) {
            $self->_error( "$name: " . ( $value // '[undef]') . " <= $spec->{le} returns false" );
            return;
        }
    }

    # Check min length
    if ( exists $spec->{min_length} ) {
        if ( $spec->{min_length} > length( $value // '' ) ) {
            $self->_error( "$name: length('" . ( $value // '[undef]') . "') > $spec->{min_length} returns false" );
            return;
        }
    }

    # Check max length
    if ( exists $spec->{max_length} ) {
        if ( $spec->{max_length} < length( $value // '' ) ) {
            $self->_error( "$name: length('" . ( $value // '[undef]') . "') < $spec->{max_length} returns false" );
            return;
        }
    }

    # Check re
    if ( exists $spec->{re} ) {
        if ( $value !~ $spec->{re} ) {
            $self->_error( "$name: '$value' does not match the Regexp $spec->{re}" );
            return;
        }
    }

    # Check of
    $all_errors = !!$all_errors;
    if ( exists $spec->{of} && $type ne 'spec' ) {
        if ( $type eq 'array' ) {
            my $arr_size = $#$value;
            for ( my $i = 0; $i <= $arr_size; $i++ ) {
                my $is_valid = $self->validate_value(
                    "$name/$i",
                    $value->[$i],
                    $spec->{of},
                    $all_errors,
                );
                if ( !$is_valid && !$all_errors ) {
                    return;
                }
            }
        }
        elsif ( $type eq 'hash' ) {
            for my $key ( keys %$value ) {
                my $is_valid = $self->validate_value(
                    "$name/$key",
                    $value->{$key},
                    $spec->{of},
                    $all_errors,
                );
                if ( !$is_valid && !$all_errors ) {
                    return;
                }
            }
        }
        else {
            $self->_error( "$name: " . "Cannot set elements types for $type" );
            return;
        }

        if ( ( $type eq 'array' && !@$value )
             || ( $type eq 'hash' && !%$value ) ) {
            if ( !exists( $spec->{empty} ) || !$spec->{empty} ) {
                $self->_error( "$name: " . ucfirst( $type ) . " cannot be empty" );
                return;
            }
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
    return ref( $_[1] ) eq 'ARRAY';
}

sub hash {
    return ref( $_[1] ) eq 'HASH';
}

sub enum {
    return $_[0]->string( $_[1] ) && exists $_[2]->{$_[1]};
}

sub code {
    return ref( $_[1] ) eq 'CODE';
}

sub spec {
    return $_[2]->validate( $_[1] );
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
                'male',
                'female',
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
            },
        },
        score => {
            type => 'hash',
            of   => {
                type => 'non_negative_int',
            },
        },
        monthly_score => {
            type => 'hash',
            of   => {
                type => 'hash',
                of   => {
                    type     => 'array',
                    of => {
                        type => 'non_negative_int',
                    },
                    callback => sub {
                        @{ $_[0] } < 12;
                    },
                },
            },
        },
        address => {
            type => 'spec',
            of   => {
                country => {
                    type   => 'enum',
                    values => [ qw/ af ax al ... zw / ],
                },
                zip_code => {
                    type => 'string',
                },
                street => {
                    type => 'string',
                },
                number => {
                    type => 'spec',
                    of   => {
                        house_nr => {
                           type => 'positive_int',
                        },
                        house_ext => {
                           type => 'string',
                        },
                        apt => {
                            type => 'positive_int',
                        },
                    },
                },
            },
        },
    };

    my $vs1 = Validate::Simple->new( $specs );
    my $is_valid1 = $vs1->validate( $params );
    print join "\n", $vs1->errors()
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

    my $specs = {
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

The value of C<type> defines an expected type of a parameter. If omitted,
type C<'any'> is used. You can learn more about supported types in the
L</"Types"> section.

=head3 C<required>

When it is set to a true value, the parameter is required, and, if it is
not in the input data, the form is considered invalid. When it is set to
a false value or does not exists, the parameter is optional.

=head3 C<undef>

By default none parameters can be undefined. If you expect some values
to be undefined, you need to explicitly set this key to true.

For example, if you allow the value of the param to be literally
anything, you can do the following:

    my $specs = {
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

    my $specs = {
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

    my $specs = {
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

You can add the following constraints to a string:

=over

=item max_length

Positive integer number that defines the maximum string length allowed.

=item min_length

Positive integer number that defines the minimum string length allowed.

=item re

Regilar expression. The value will be checked aginst this regexp.

For example:

    my $specs = {
        str_re => {
            type => 'string',
            re   => qr/Valid/,
        }
    };

=back

=head3 List types

The list types B<must> have the key C<of>, which contains a spec of all
list values. For example:

    my $specs = {
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

    my $specs = {
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

=head3 spec

The value is another structure, of hashref with predefined keys and
values of different types. The type C<spec> requires the key C<of>,
which, in turn, expects another valid specification. Obviously, a
specification may contain as many nested specifications as necessary.

    my $resume_spec = {
        name => {
            type => 'string'
        },
        objective => {
            type => 'string'
        },
        experience => {
            type => 'array',
            of   => {
                type => 'spec',
                of   => {
                    company => {
                        type => 'string',
                    },
                    position => {
                        type => 'string',
                    },
                    description => {
                        type => 'string',
                    },
                    start => {
                        type => 'spec',
                        of   => {
                            year => {
                                type => 'integer',
                                gt   => 1960,
                                le   => 1900 + (localtime)[5],
                            },
                            month => {
                                type => 'positive_int',
                                lt   => 12,
                            },
                        },
                        required => 1,
                    },
                    end => {
                        type => 'spec',
                        of   => {
                            year => {
                                type => 'integer',
                                gt   => 1960,
                                le   => 1900 + (localtime)[5],
                            },
                            month => {
                                type => 'positive_int',
                                lt   => 12,
                            },
                        },
                        required => 0,
                    },
                },
            },
        },
    };

=head1 METHODS

=head2 new( \%spec[, $all_errors] )

Creates an object. The parameter is optional, though it's recomended to
pass it, because in this case it checks specs syntax only once, not on
each call of C<validate> method.

By default the module stops validation after finding the first invalid
value. If the second parameter C<$all_errors> is true, the call of the
C<validate> method will keep checking all C<\%params> and will stack all
found errors. The list of errors is returned by the C<errors> method.

=head2 validate( \%params, [\%specs[, $all_errors]] )

Does validation of the C<\%params> against C<\%specs>. If C<\%specs> is
not provided, it performs validation against the spec, given in the
C<new> method. Returns 1 if C<\%params> are valid, C<undef> otherwise.

The parameter C<$all_errors> works the same way as in the C<new()>
method.

=head2 errors

Returns the list of validation errors. The list is being emptied before
each call of the C<validate> method.

=head1 BUGS

Not reported... Yet...

=head1 SEE ALSO

=head1 AUTHOR

Andrei Pratasavitski <andreip@cpan.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
