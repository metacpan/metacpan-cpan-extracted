# NAME

Validate::Tiny - Minimalistic data validation

# SYNOPSIS

Filter and validate user input from forms, etc.

    use Validate::Tiny ':all';

    my $rules = {

        # List of fields to look for
        fields => [qw/name email pass pass2 gender/],

        # Filters to run on all fields
        filters => [

            # Remove spaces from all
            qr/.+/ => filter(qw/trim strip/),

            # Lowercase email
            email => filter('lc'),

            # Remove non-alphanumeric symbols from
            # both passwords
            qr/pass?/ => sub {
                $_[0] =~ s/\W/./g;
                $_[0];
            },
        ],

        # Checks to perform on all fields
        checks => [

            # All of these are required
            [qw/name email pass pass2/] => is_required(),

            # pass2 must be equal to pass
            pass2 => is_equal('pass'),

            # custom sub validates an email address
            email => sub {
                my ( $value, $params ) = @_;
                return if Email::Valid->address($value);
                return 'Invalid email';
            },

            # custom sub to validate gender
            gender => sub {
                my ( $value, $params ) = @_;
                return if $value eq 'M' || $value eq 'F';
                return 'Invalid gender';
            }

        ]
    };

    # Validate the input agains the rules
    my $result = validate( $input, $rules );

    if ( $result->{success} ) {
        my $values_hash = $result->{data};
        ...
    }
    else {
        my $errors_hash = $result->{error};
        ...
    }

Or if you prefer an OOP approach:

    use Validate::Tiny;

    my $v = Validate::Tiny->new( %args );
    $v->check( $input, $rules );

    if ( $v->success ) {
        my $values_hash = $v->data;
        my $name        = $v->data('name');
        my $email       = $v->data('email');
        ...;
    }
    else {
        my $errors_hash = $v->error;
        my $name_error  = $v->error('name');
        my $email_error = $v->error('email');
    }

# DESCRIPTION

This module provides a simple, light and minimalistic way of validating
user input. Except perl core modules and some test modules it has no other
dependencies, which is why it does not implement any complicated checks
and filters such as email and credit card matching. The basic idea of this
module is to provide the validation functionality, and leave it up to the
user to write their own data filters and checks. If you need a complete
data validation solution that comes with many ready features, I recommend
you to take a look at [Data::FormValidator](https://metacpan.org/pod/Data::FormValidator). If your validation logic is
not too complicated or your form is relatively short, this module is a
decent candidate for your project.

# LOGIC

The basic principle of data/form validation is that any user input must be
sanitized and checked for errors before used in the logic of the program.
Validate::Tiny breaks this process in three steps:

1. Specify the fields you want to work with via ["fields"](#fields).  All others will
be disregarded.
2. Filter the fields' values using ["filters"](#filters). A filter can be as simple as
changing to lower case or removing excess white space, or very complicated
such as parsing and removing HTML tags.
3. Perform a series of ["checks"](#checks) on the filtered values, to make sure they
match the requirements. Again, the checks can be very simple as in
checking if the value was defined, or very complicated as in checking if
the value is a valid credit card number.

The validation returns a hash ref which contains `success` => 1|0,
`data` and `error` hashes. If success is 1, `data` will contain the
filtered values, otherwise `error` will contain the error messages for
each field.

# EXPORT

This module does not automatically export anything. You can optionally
request any of the below subroutines or use ':all' to export all.

# RULES

Rules provide the specifications for the three step validation
process.  They are represented as a hash, containing references to the
following three arrays: ["fields"](#fields), ["filters"](#filters) and ["checks"](#checks).

    my %rules = (
        fields  => \@field_names,
        filters => \@filters_array,
        checks  => \@checks_array
    );

## fields

An array containing the names of the fields that must be filtered, checked
and returned. All others will be disregarded. As of version 0.981 you can
use an empty array for `fields`, which will work on all input fields.

    my @field_names = qw/username email password password2/;

or

    my @field_names = ();   # Use all input fields

## filters

An array containing name matches and filter subs. The array must have an
even number of elements. Each _odd_ element is a field name match and
each _even_ element is a reference to a filter subroutine or a chain of
filter subroutines. A filter subroutine takes one parameter - the value to
be filtered, and returns the modified value.

    my @filters_array = (
        email => sub { return lc $_[0] },    # Lowercase the email
        password =>
          sub { $_[0] =~ s/\s//g; $_[0] }    # Remove spaces from password
    );

The field name is matched with the perl smart match operator, so you could
have a regular expression or a reference to an array to match several
fields:

    my @filters_array = (
        qr/.+/ => sub { lc $_[0] },    # Lowercase ALL

        [qw/password password2/] => sub {    # Remove spaces from both
            $_[0] =~ s/\s//g;                # password and password2
            $_[0];
        }
    );

Instead of a single filter subroutine, you can pass an array of
subroutines to provide a chain of filters:

    my @filters_array = (
        qr/.+/ => [ sub { lc $_[0] }, sub { ucfirst $_[0] } ]
    );

The above example will first lowercase the value then uppercase its first
letter.

Some simple text filters are provided by the ["filter()"](#filter) subroutine.

    use Validate::Tiny qw/validate :util/;

    my @filters_array = (
        name => filter(qw/strip trim lc/)
    );

### Adding custom filters

This module exposes `our %FILTERS`, a hash containing available filters.
To add a filter, add a new key-value to this hash:

    $Validate::Tiny::FILTERS{only_digits} = sub {
        my $val = shift // return;
        $val =~ s/\D//g;
        return $val;
    };

### Filter Support Routines

#### filter

    filter( $name1, $name2, ... );

Provides a shortcut to some basic text filters. In reality, it returns a
list of anonymous subs, so the following:

    my $rules = {
        filters => [
            email => filter('lc', 'ucfirst')
        ]
    };

is equivalent to this:

    my $rules = {
        filters => [
            email => [ sub{ lc $_[0] }, sub{ ucfirst $_[0] } ]
        ]
    };

It provides a shortcut for the following filters:

- trim

    Removes leading and trailing white space.

- strip

    Shrinks two or more white spaces to one.

- lc

    Lower case.

- uc

    Upper case.

- ucfirst

    Upper case first letter

## checks

An array ref containing name matches and check subs. The array must have
an even number of elements. Each _odd_ element is a field name match and
each _even_ element is a reference to a check subroutine or a chain of
check subroutines.

A check subroutine takes three parameters - the value to be checked, a
reference to the filtered input hash and a scalar with the name of the
checked field.

**Example:**

    checks => [
        does_exist => sub {
            my ( $value, $params, $keys ) = @_;
            return "Key doesn't exist in input data"
              unless exists( $params->{$key} );
        }
    ]

A check subroutine must return undef if the check passes or a scalar containing
an error message if the check fails.  The message is not interpreted by
Validate::Tiny, so may take any form, e.g. a string, a reference to
an error object, etc.

**Example:**

    # Make sure the password is good
    sub is_good_password {
        my ( $value, $params ) = @_;

        if ( !defined $value or $value eq '' ) {
            return;
        }

        if ( length($value) < 6 ) {
            return "The password is too short";
        }

        if ( length($value) > 40 ) {
            return "The password is too long";
        }

        if ( $value eq $params->{username} ) {
            return "Your password can not be the same as your username";
        }

        # At this point we're happy with the password
        return;
    }

    my $rules = {
        fields => [qw/username password/],
        checks => [
            password => \&is_good_password
        ]
    };

It may be a bit counter-intuitive for some people to return undef when the
check passes and an error message when it fails. If you have a huge problem with
this concept, then this module may not be right for you.

**Important!** Notice that in the beginning of `is_good_password` we check
if `$value` is defined and return undef if it is not. This is because it
is not the job of `is_good_password` to check if `password` is required.
Its job is to determine if the password is good. Consider the following
example:

    # Password is required and it must pass the check for good password
    #
    my $rules = {
        fields => [qw/username password/],
        checks => [
            password => [ is_required(), \&is_good_password ]
        ]
    };

and this one too:

    # Password is not required, but if it's provided then
    # it must pass the is_good_password constraint.
    #
    my $rules = {
        fields => [qw/username password/],
        checks => [
            username => is_required(),
            password => \&is_good_password
        ]
    };

The above examples show how we make sure that `password` is defined and
not empty before we check if it is a good password.  Of course we can
check if `password` is defined inside `is_good_password`, but it would
be redundant. Also, this approach will fail if `password` is not
required, but must pass the rules for a good password if provided.

### Chaining

The above example also shows that chaining check subroutines is available
in the same fashion as chaining filter subroutines.  The difference
between chaining filters and chaining checks is that a chain of filters
will always run **all** filters, and a chain of checks will exit after the
first failed check and return its error message.  This way the
`$result->{error}` hash always has a single error message per field.

### Using closures

When writing reusable check subroutines, sometimes you will want to be
able to pass arguments. Returning closures (anonymous subs) is the
recommended approach:

    sub is_long_between {
        my ( $min, $max ) = @_;
        return sub {
            my $value = shift;
            return if length($value) >= $min && length($value) <= $max;
            return "Must be between $min and $max symbols";
        };
    }

    my $rules = {
        fields => qw/password/,
        checks => [
            password => is_long_between( 6, 40 )
        ]
    };

### Check Support Routines

Validate::Tiny provides a number of predicates to simplify writing
rules.  They may be passed an optional error message.  Like those
returned by custom check routines, the message is not interpreted by
Validate::Tiny, so may take any form, e.g. a string, a reference to an
error object, etc.

#### is\_required

    is_required( $optional_error_message );

`is_required` provides a shortcut to an anonymous subroutine that
checks if the matched field is defined and it is not an empty
string.
Optionally, you can provide a custom error message. The default is the string,  _Required_.

#### is\_required\_if

    is_required_if( $condition, $optional_error_message );

Require a field conditionally. The condition can be either a scalar or a
code reference that returns true/false value. If the condition is a code
reference, it will be passed the `$params` hash with all filtered fields.
Optionally, you can provide a custom error message. The default is the string,  _Required_.

Example:

    my $rules = {
        fields => [qw/country state/],
        checks => [
            country => is_required(),
            state   => is_required_if(
                sub {
                    my $params = shift;
                    return $params->{country} eq 'USA';
                },
                "Must select a state if you're in the USA"
            )
        ]
    };

Second example:

    our $month = 'October';
    my $rules = {
        fields => ['mustache'],
        checks => [
            mustache => is_required_if(
                $month eq 'October',
                "You must grow a mustache this month!"
            )
        ]
    };

#### is\_existing

    is_existing( $optional_error_message );

Much like `is_required`, but checks if the field contains any value, even an
empty string and `undef`.
Optionally, you can provide a custom error message. The default is the string,  _Must be defined_.

#### is\_equal

    is_equal( $other_field_name, $optional_error_message );

`is_equal` checks if the value of the matched field is the same as the
value of another field within the input hash.
Optionally, you can provide a custom error message. The default is the string,  _Invalid value_.

Example:

    my $rules = {
        checks => [
            password2 => is_equal("password", "Passwords don't match")
        ]
    };

#### is\_long\_between

    is_long_between( $min, $max, $optional_error_message );

Checks if the length of the value is >= `$min` and <= `$max`. Optionally
you can provide a custom error message. The default is the string,  _Invalid value_.

Example:

    my $rules = {
        checks => [
            username => is_long_between( 6, 25, 'Bad username' )
        ]
    };

#### is\_long\_at\_least

    is_long_at_least( $length, $optional_error_message );

Checks if the length of the value is >= `$length`. Optionally you can
provide a custom error message. The default is the string,  _Must be at least %i
symbols_.

Example:

    my $rules = {
        checks => [
            zip_code => is_long_at_least( 5, 'Bad zip code' )
        ]
    };

#### is\_long\_at\_most

    is_long_at_most( $length, $optional_error_message );

Checks if the length of the value is <= `$length`. Optionally you can
provide a custom error message. The default is the string,  _Must be at the most %i
symbols_.

Example:

    my $rules = {
        checks => [
            city_name => is_long_at_most( 40, 'City name is too long' )
        ]
    };

#### is\_a

    is_a ( $class, $optional_error_message );

Checks if the value is an instance of a class. This can be particularly
useful, when you need to parse dates or other user input that needs to get
converted to an object. Since the filters get executed before checks, you
can use them to instantiate the data, then use `is_a` to check if you got
a successful object.
Optionally you can provide a custom error message. The default is the string,  _Invalid value_.

Example:

    use DateTime::Format::Natural;
    use Try::Tiny;

    my $parser = DateTime::Format::Natural->new;

    my $rules = {
        fields  => ['date'],

        filters => [
            date => sub {
                try {
                    $parser->parse_datetime( $_[0] );
                }
                catch {
                    $_[0]
                }
            }
        ],

        checks => [
            date => is_a("DateTime", "Ivalid date")
        ]
    };

#### is\_like

    is_like ( $regexp, $optional_error_message );

Checks if the value matches a regular expression.
Optionally you can provide a custom error message. The default is the string,  _Invalid value_.

Example:

    my $rules = {
        checks => [
            username => is_like( qr/^[a-z0-9_]{6,20}$/, "Bad username" )
        ]
    };

#### is\_in

    is_in ( $arrayref, $optional_error_message );

Checks if the value matches a set of values.
Optionally you can provide a custom error message. The default is the string,  _Invalid value_.

    Example:

    my @cities = qw/Alchevsk Kiev Odessa/;
    my $rules = {
        checks => [
            city => is_in( \@cities, "We only deliver to " . join(',', @cities))
        ]
    };

# PROCEDURAL INTERFACE

## validate

    use Validate::Tiny qw/validate/;

    my $result = validate( \%input, \%rules );

Validates user input against a set of rules. The input is expected to be a
reference to a hash.

### Return value

`validate` returns a hash ref with three elements:

    my $result = validate(\%input, \%rules);

    # Now $result looks like this
    $result = {
        success => 1,       # or 0 if checks didn't pass
        data    => \%data,
        error   => \%error
    };

If `success` is 1 all of the filtered input will be in `%data`,
otherwise the error messages will be stored in `%error`. If `success` is
0, `%data` may or may not contain values, but its use is not recommended.

# OBJECT INTERFACE

## new( %args )

At this point the only argument you can use in `%args` is `filters`,
which should be a hashref with additional filters to be added to the
`%FILTERS` hash.

    my $v = Validate::Tiny->new(
        filters => {
            only_digits => sub {
                my $val = shift // return;
                $val =~ s/\D//g;
                return $val;
            }
        }
    );

## check( \\%input, %rules )

Checks the input agains the rules and initalized internal result state.

    my %input = ( bar => 'abc' );
    my %rules = ( fields => ['bar'], filters => filter('uc') );
    $v->check( \%input, \%rules );

    if ( $v->success ) {
        ...;
    }

## success

Returns a true value if the input passed all the rules.

## data

Returns a hash reference to all filtered fields. If called with a
parameter, it will return the value of that field or croak if there is no
such field defined in the fields array.

    my $all_fields = $result->data;
    my $email      = $result->data('email');

## error

Returns a hash reference to all error messages. If called with a
parameter, it will return the error message of that field, or croak if
there is no such field.

    my $errors = $result->error;
    my $email = $result->error('email');

## to\_hash

Return a result hash, much like using the procedural interface. See the
output of ["validate"](#validate) for more information.

# I18N

A check function is considered failing if it returns a value. In the above
examples we showed you how to return error strings. If you want to
internationalize your errors, you can make your check closures return
[Locale::Maketext](https://metacpan.org/pod/Locale::Maketext) functions, or any other i18n values.

# SEE ALSO

[Data::FormValidator](https://metacpan.org/pod/Data::FormValidator)

# BUGS

Bug reports and patches are welcome. Reports which include a failing
Test::More style test are helpful and will receive priority.

You may also fork the module on Github:
https://github.com/naturalist/Validate--Tiny

# AUTHOR

    Stefan G. (cpan: MINIMAL) - minimal@cpan.org

# CONTRIBUTORS

    Viktor Turskyi (cpan: KOORCHIK) - koorchik@cpan.org
    Ivan Simonik (cpan: SIMONIKI) - simoniki@cpan.org
    Daya Sagar Nune (cpan: DAYANUNE) - daya.webtech@gmail.com
    val - valkoles@gmail.com
    Patrice Clement (cpan: MONSIEURP) - monsieurp@gentoo.org
    Graham Ollis (cpan: PLICEASE)
    Diab Jerius (cpan DJERIUS)

# LICENCE

This program is free software; you can redistribute it and/or modify it
under the terms as perl itself.
