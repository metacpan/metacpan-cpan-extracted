package Validator::Lazy;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;

    my $form = {
        first_name => 'John',
        last_name  => 'John',
        phone      => '+123456789',
        fax        => '',
        email      => 'john@site.com',
    };

    my $config = q~
        '/^(first|last)_name$/':
            - Trim: 'all'
            - Required
            - RegExp: '/^[A-Zaz]{3,64}$/'

        '[phone,fax]': Phone

        phone: Required

        email: [ 'Required', 'Email' ]

        myform:
            - Form: [ 'first_name', 'last_name', 'phone', 'fax', 'email' ]
    ~;

    my $validator = Validator::Lazy->new( $config );

    my $ok = $v->check(  myform => $form );  # true / false
    OR
    my ( $ok, $data ) = $validator->check( myform => $form );

    use Data::Dumper;
    say Dumper $v->errors;    # [ { code => any_error_code, field => field_with_error, data => { variable data for more accurate error definition } } ]
    say Dumper $v->warnings;  # [ { code => any_warn_code,  field => field_with_warn,  data => { variable data for more accurate warn  definition } } ]
    say Dumper $v->data;      # Fixed data. For example trimmed strings, corrected char case, etc...

For more details please see test files. For example t/14-int_roles-form.t can be the no.1 to see.

=head1 DESCRIPTION

Validator for different sets of data with easy and simple sets of rules.

Features:

=over 4

=item * Very simple and relatively short configuration

=item * Allows to check almost everything: small web forms as well as deep multilevel structures with intersected params.

=item * Some predefined check rules/roles ( Case, CountryCode, Email, Form, IP, IsIn, MinMax, Phone, RegExp, Required, Trim )

=item * Easy way to create your own simple rules/roles and use them as native as predefined

=item * No need to make and pass extra code to validator from caller during validation. Just a sets of rules.

=item * No intersections and relations between rules (when you fix a one field validation, your other fields are be safe)

=back

So, how it works...

=head2 Configuration/Init

    my $v = Validator::Lazy->new( $config );

$config can be a string, or text, or hashref

=over 4

=item * when config is a string, which looks like a filename,- validator will try to read configuration from this file

=item * when config is a text, validator will think, that it's a pure YAML or JSON and will try to parse it

=item * when config is a hashref, validator just will apply it without further ado

=back

In all cases, finnaly we have a hashref:

    field_definition1:
        - rule1: param1
        - rule2: param2
        ...
    field_definition2:
        ...

in case, when a field have 1 rule without params, we can give a scalar instead of Arrayref[HashRef]:

    field_definition1: rule1


B<each rule can be an internal validator role, or external role, or a key from configuration>

internal role example:

    user_phone: Phone

external/your role example:

    part_number: Where::Your::Role::IS::YourFieldRole

predefined role example:

    # Here, we predefine/declare the new field: "any_phone"
    any_phone: Phone

    # And now we can use it within other field rules:
    user_phone:
        - Required
        - any_phone

    # And here we have alias or clone for any_phone
    user_fax:  any_phone



B<each config key allows you to match more than one field of your data for checking:>

for example we need to check a web form like this:

    firstname:   'John'
    lastname:    'John'
    phone:       '+123456789'
    fax:         ''
    email:       'john@site.com'
    secretkey:   'x1x2x3x4'

at first we make a config:
firstname and lastname has equal requirements, so we put them in one key:

    '[firstname,lastname]':
        - Required
        - RegExp: '/^[A-Zaz]{3,64}$/'

    or like this

    '/^(first|last)_name$/':
        - Required
        - RegExp: '/^[A-Zaz]{3,64}$/'

phone and fax has similar requirements, but phone is required and fax is optional:

    [phone,fax]: Phone
    phone: Required

and email:

    email:
        - Required
        - Email

let's assume, that secretkey has some tricky checks, so it should be checked with external code.
We should write a role (how to do this - see far below), and now just use it:

    secretkey:
        - Required
        - Path::To::Your::Roles::SecretKey : { secretkey: param }


B<Combining all together, and we have:>

    # Config
    my $config = q~
        '/(first|last)_name/':
            - Trim: 'all'
            - Required
            - RegExp: '/^[A-Zaz]{3,64}$/'

        '[phone,fax]': Phone

        phone: Required

        email:
            - Required
            - Email

        secretkey:
            - Required
            - 'Path::To::Your::Roles::SecretKey': { secretkey: 'param' }

        myform:
            - Form:
                - first_name
                - last_name
                - phone
                - fax
                - email
                - secretkey
    ~;

    # Form to check:
    my $form = {
        first_name => 'John',
        last_name  => 'John',
        phone      => '+123456789',
        fax        => '',
        email      => 'john@site.com',
        secretkey  => 'x1x2x3x4',
    };

    my $validator = Validator::Lazy->new( $config );

    my $ok = $validator->check( $form ); # true
    or
    my ( $ok, $data ) = $validator->check( myform => $form );


=head2 Writing a roles

Let's write a role, that is required for example above:

    package Path::To::Your::Roles::SecretKey;

    use Modern::Perl;
    use Moose::Role;

    sub check {
        my ( $self, $value, $param ) = @_;

        $self;  # is a validator object
        $value; # is a value to check from form
        $param; # is a param = {secretkey:param}

        $self->add_error( ); # This will add to validator dafault error
        $self->add_error( 'CUSTOM_ERROR_CODE' );  # Custom error code will be plased instead of default
        $self->add_error( 'CUSTOM_ERROR_CODE', { some useful data } );  # Also, we can pass to error some data, and use it somwhere outside
        $self->add_error( { some useful data } );  # Default code, but some useful data

        $self->add_warning(); # All the same as with errors;

        return $value; # You should do it! Othervise you just lost your value.
    }

    # Also, you can use in check roles:
    sub before_check { similar to check }
    sub after_check { similar to check }
    # They are working exactly as check, but allow to do some code separation

    1;

=head2 Forms

Validator has a predefined "Form" role, let's, use it:

    # YAML sample:
    '/(first|last)_name/':
        - Trim: 'all'
        - Required
        - RegExp: '/^[A-Zaz]{3,64}$/'

    full_name:
        Form: [first_name, last_name ]

Corrected example from above:

    my $form = {
        full_name => {
            first_name => 'John',
            last_name  => 'Smith',
        },
        phone     => '+123456789',
        fax       => '',
        email     => 'john@site.com',
        secretkey => 'x1x2x3x4',
    };

    my $config = q~
        '/(first|last)_name/':
            - Trim: 'all'
            - Required
            - RegExp: '/^[A-Zaz]{3,64}$/'

        full_name:
            - Form: [first_name, last_name ]

        '[phone,fax]': Phone

        phone: Required

        email: Email

        secretkey:
            - Required
            - 'Path::To::Your::Roles::SecretKey': { secretkey: param }

        myform:
            - Form:
                - full_name
                - phone
                - fax
                - email
                - secretkey
    ~;

    my $validator = Validator::Lazy->new( $config );

    my $ok = $validator->check( $form ); # true

    or

    my ( $ok, $data ) = $validator->check( myform => $form );

=head2 warnings/errors/results

    $validator->check( $data ); can return 1 or 2 params;

the 1st - can be true or false - is a result of check.
the 2nd - form data, but corrected. For example, if Trim used, some strings will be trimmed from spaces.

after $validator->check() validators has:

    $validator->errors - list = [ { code => 'SOME_ERROR_CODE', field => 'some_field', data => 'some data' }, ... ]
    $validator->error_codes - list of codes = [ 'SOME_ERROR_CODE', ... ]

And all the same with warnings...

when an external role adds an error, then, by default it has a error/warning code:

    role is "Path::To::Your::Roles::SecretKey"
    default error code is PATH_TO_YOUR_ROLES_SECRETKEY_ERROR

when a subform adds an error, then default field name is generated as form_name + '_' + field_name:

    myform:
        - Form:
            - full_name
                - Required

when full_name is absent, we have an error:

        { code => 'REQUIRED_ERROR', field => 'myform_full_name', data => {} }


=head2 Contestants

There are huge amount of other validators on CPAN.

All of them have their pros and cons, but all are very different.

I do not wish to write here detailed review of each, so let's just list them all:

https://metacpan.org/pod/Data::Validator

https://metacpan.org/pod/Validator::LIVR

https://metacpan.org/pod/QBit::Validator

https://metacpan.org/pod/Input::Validator

https://metacpan.org/pod/MojoX::Validator

https://metacpan.org/pod/Kossy::Validator

https://metacpan.org/pod/FormValidator::Tiny

https://metacpan.org/pod/FormValidator::LazyWay


=head1 METHODS

=head2 C<check>
    $validator->check( $data );

=head1 SUPPORT AND DOCUMENTATION

    After installing, you can find documentation for this module with the perldoc command.

    perldoc Validator::Lazy

    You can also look for information at:

        RT, CPAN's request tracker (report bugs here)
            http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator-Lazy

        AnnoCPAN, Annotated CPAN documentation
            http://annocpan.org/dist/Validator-Lazy

        CPAN Ratings
            http://cpanratings.perl.org/d/Validator-Lazy

        Search CPAN
            http://search.cpan.org/dist/Validator-Lazy/


=head1 AUTHOR

ANTONC <antonc@cpan.org>

=head1 LICENSE

    This program is free software; you can redistribute it and/or modify it
    under the terms of the the Artistic License (2.0). You may obtain a
    copy of the full license at:

    L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

use v5.14.0;
use utf8;
use Modern::Perl;

use ExtUtils::Installed;
use YAML::XS;

use Moose;

with 'Validator::Lazy::Role::Composer'; # get_field_roles
with 'Validator::Lazy::Role::Check';
with 'Validator::Lazy::Role::Notifications';

# my $validator = Validator::Lazy->new( config => $config );
# $validator->check( %data );
around BUILDARGS => sub {
    my ( $orig, $class, @param ) = @_;

    my %param;

    # We are too lazy to write word "config"
    # But it's ok! :)
    if ( scalar @param == 1 ) {

        my $p = $param[0];

        confess 'param should contain something'  unless $p;

        $param{config} = $p;
    }
    else {
        %param = @param;
    };

    my $cfg = $param{config};

    # Oh! we are more lazy than we not lazy to imagine...
    if ( $cfg  &&  !ref $cfg ) {
        # File detected!
        if ( $cfg !~ /\n/  &&  $cfg =~ /\.(yaml|yml|json)$/ai ) {

            confess "File not found: $cfg"  unless -f $cfg;

            $param{config} = LoadFile( $cfg );
        }
        # Try to parse as YAML
        else {
            $param{config} = Load( $cfg );
        };
    };

    return $class->$orig( %param );
};

has config => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
    default  => sub {{}},
);


# scalar, that contains current field name which is now under a check
has current_field => (
    is       => 'rw',
    isa      => 'Str',
    init_arg => undef,
);


# list of all nested forms above current, exept the very first form, from which all check began
has form_stack => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    default  => sub{ [] },
);


# list of all nested forms above current, exept the very first form, from which all check began
has data => (
    is       => 'rw',
    isa      => 'HashRef',
);

# full name of current field which is now under checking with all form prefixes attached
# Using for generating field names for errors and notifications, also for uniqueness for all checking process
sub get_full_current_field_name {
    my ( $self ) = @_;

    my @stack = @{ $self->form_stack // [] };
    shift @stack;

    return join '_', ( @stack, $self->current_field );
}

__PACKAGE__->meta->make_immutable;
