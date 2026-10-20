package Validator::LIVR;

use v5.10;
use strict;
use warnings FATAL => 'all';

use Carp qw/croak/;

use Validator::LIVR::Rules::Common;
use Validator::LIVR::Rules::String;
use Validator::LIVR::Rules::Numeric;
use Validator::LIVR::Rules::Special;
use Validator::LIVR::Rules::Meta;
use Validator::LIVR::Rules::Modifiers;

our $VERSION = '2.1';

my %DEFAULT_RULES = (
    'required'         => \&Validator::LIVR::Rules::Common::required,
    'not_empty'        => \&Validator::LIVR::Rules::Common::not_empty,
    'not_empty_list'   => \&Validator::LIVR::Rules::Common::not_empty_list,
    'any_object'       => \&Validator::LIVR::Rules::Common::any_object,

    'one_of'           => \&Validator::LIVR::Rules::String::one_of,
    'min_length'       => \&Validator::LIVR::Rules::String::min_length,
    'max_length'       => \&Validator::LIVR::Rules::String::max_length,
    'length_equal'     => \&Validator::LIVR::Rules::String::length_equal,
    'length_between'   => \&Validator::LIVR::Rules::String::length_between,
    'like'             => \&Validator::LIVR::Rules::String::like,
    'string'           => \&Validator::LIVR::Rules::String::string,
    'eq'               => \&Validator::LIVR::Rules::String::equal,

    'integer'          => \&Validator::LIVR::Rules::Numeric::integer,
    'positive_integer' => \&Validator::LIVR::Rules::Numeric::positive_integer,
    'decimal'          => \&Validator::LIVR::Rules::Numeric::decimal,
    'positive_decimal' => \&Validator::LIVR::Rules::Numeric::positive_decimal,
    'max_number'       => \&Validator::LIVR::Rules::Numeric::max_number,
    'min_number'       => \&Validator::LIVR::Rules::Numeric::min_number,
    'number_between'   => \&Validator::LIVR::Rules::Numeric::number_between,

    'email'            => \&Validator::LIVR::Rules::Special::email,
    'equal_to_field'   => \&Validator::LIVR::Rules::Special::equal_to_field,
    'url'              => \&Validator::LIVR::Rules::Special::url,
    'iso_date'         => \&Validator::LIVR::Rules::Special::iso_date,

    'nested_object'    => \&Validator::LIVR::Rules::Meta::nested_object,
    'variable_object'  => \&Validator::LIVR::Rules::Meta::variable_object,
    'list_of'          => \&Validator::LIVR::Rules::Meta::list_of,
    'list_of_objects'  => \&Validator::LIVR::Rules::Meta::list_of_objects,
    'or'               => \&Validator::LIVR::Rules::Meta::livr_or,
    'list_of_different_objects' => \&Validator::LIVR::Rules::Meta::list_of_different_objects,


    'trim'             =>  \&Validator::LIVR::Rules::Modifiers::trim,
    'to_lc'            =>  \&Validator::LIVR::Rules::Modifiers::to_lc,
    'to_uc'            =>  \&Validator::LIVR::Rules::Modifiers::to_uc,
    'remove'           =>  \&Validator::LIVR::Rules::Modifiers::remove,
    'leave_only'       =>  \&Validator::LIVR::Rules::Modifiers::leave_only,
    'default'          =>  \&Validator::LIVR::Rules::Modifiers::default,
);

my $IS_DEFAULT_AUTO_TRIM = 0;

sub new {
    my ($class, $livr_rules, $is_auto_trim) = @_;

    my $self = bless {
        is_prepared        => 0,
        livr_rules         => $livr_rules,
        validators         => {},
        validator_builders => {%DEFAULT_RULES}, # checked by register_default_rules()
        errors             => undef,
        is_auto_trim       => ( $is_auto_trim // $IS_DEFAULT_AUTO_TRIM )
    }, $class;

    return $self;
}

sub register_default_rules {
    my ( $class, %rules ) = @_;

    foreach my $rule_name ( keys %rules ) {
        my $rule_builder = $rules{$rule_name};
        croak "RULE_BUILDER [$rule_name] SHOULD BE A CODEREF" unless ref($rule_builder) eq 'CODE';

        $DEFAULT_RULES{$rule_name} = $rule_builder;
    }

    return $class;
}

sub register_aliased_default_rule {
    my ( $class, $alias ) = @_;

    die 'Alias name required' unless $alias->{name};
    $DEFAULT_RULES{ $alias->{name} } = $class->_build_aliased_rule($alias);

    return $class;
}

sub get_default_rules {
    return {%DEFAULT_RULES};
}

sub default_auto_trim {
    my ($class, $is_auto_trim) = @_;
    $IS_DEFAULT_AUTO_TRIM = !!$is_auto_trim;
}

sub prepare {
    my $self = shift;

    my $all_rules = $self->{livr_rules};
    my $rule_builders = $self->get_rules();

    # Not "each": when a rule dies, it leaves the iterator in the middle of the hash,
    # and the next prepare() would skip the fields up to that rule
    foreach my $field ( keys %$all_rules ) {
        my $field_rules = $all_rules->{$field};
        $field_rules = [$field_rules] if ref($field_rules) ne 'ARRAY';

        my @validators;
        foreach my $rule (@$field_rules) {
            my ($name, $args) = $self->_parse_rule($rule);
            push @validators, $self->_build_validator($name, $args, $rule_builders);
        }
        $self->{validators}{$field} = \@validators;
    }

    $self->{is_prepared} = 1;

    return $self;
}

sub validate {
    my ($self, $data) = @_;
    $self->prepare() unless $self->{is_prepared};

    if ( ref($data) ne 'HASH' ) {
        $self->{errors} = 'FORMAT_ERROR';
        return;
    }

    $data = $self->_auto_trim($data) if $self->{is_auto_trim};

    my ( %errors, %result );
    my $all_validators = $self->{validators};

    foreach my $field_name ( keys %$all_validators ) {
        my $validators = $all_validators->{$field_name};
        next unless $validators && @$validators;

        my $value = $data->{$field_name};

        # The output of the previous rules, the same as $result{$field_name}
        my ( $has_output, $output );

        foreach my $v_cb (@$validators) {
            my $field_result = $output // $value;

            my $err_code = $v_cb->( $has_output ? $output : $value, $data, \$field_result );

            if ( $err_code ) {
                $errors{$field_name} = $err_code;
                $has_output = 0;
                last;
            } elsif ( defined($field_result) ) {
                ( $has_output, $output ) = ( 1, $field_result );
            } elsif ( !$has_output && exists $data->{$field_name} ) {
                ( $has_output, $output ) = ( 1, undef );
            }
        }

        $result{$field_name} = $output if $has_output;
    }

    if ( keys %errors ) {
        $self->{errors} = \%errors;
        return;
    } else {
        $self->{errors} = undef;
        return \%result;
    }
}

sub get_errors {
    my $self = shift;
    return $self->{errors};
}

sub register_rules {
    my ( $self, %rules ) = @_;

    foreach my $rule_name ( keys %rules ) {
        my $rule_builder = $rules{$rule_name};
        croak "RULE_BUILDER [$rule_name] SHOULD BE A CODEREF" unless ref($rule_builder) eq 'CODE';

        $self->{validator_builders}{$rule_name} = $rule_builder;
    }

    return $self;
}

sub register_aliased_rule {
    my ( $self, $alias ) = @_;

    die 'Alias name required' unless $alias->{name};
    $self->{validator_builders}{ $alias->{name} } = $self->_build_aliased_rule($alias);

    return $self;
}

sub get_rules {
    my $self = shift;

    return { %{$self->{validator_builders}} };
}

sub _parse_rule {
    my ($self, $livr_rule) = @_;

    my ($name, $args);

    if ( ref($livr_rule) eq 'HASH' ) {
        # Only the first key would be used, and the order of keys is random
        my @names = sort keys %$livr_rule;
        die 'Rule [' . join( ', ', @names ) . "] should have one name\n" if @names != 1;

        $name = $names[0];
        $args = $livr_rule->{$name};
        $args = [$args] unless ref($args) eq 'ARRAY';
    } else {
        $name = $livr_rule;
        $args = [];
    }

    return ($name, $args);
}

sub _build_validator {
    my ($self, $name, $args, $rule_builders) = @_;
    die "Rule [$name] not registered\n" unless $self->{validator_builders}->{$name};

    return $self->{validator_builders}->{$name}->( @$args, $rule_builders // $self->get_rules() );
}

sub _build_aliased_rule {
    my ($class, $alias) = @_;

    die 'Alias name required'  unless $alias->{name};
    die 'Alias rules required' unless $alias->{rules};

    my $livr = { value => $alias->{rules} };

     return sub {
        my $rule_builders = shift;
        my $validator = __PACKAGE__->new($livr)->register_rules(%$rule_builders)->prepare();

        return sub {
            my ($value, $params, $output_ref) = @_;

            my $result = $validator->validate( { value => $value } );

            if ( $result ) {
                $$output_ref = $result->{value};
                return;
            } else {
                return $alias->{error} || $validator->get_errors()->{value};
            }
        };
    };
}

sub _auto_trim {
    my ( $self, $data ) = @_;
    my $ref_type = ref($data);

    if ( !$ref_type && $data ) {
        $data =~ s/^\s+//;
        $data =~ s/\s+$//;
        return $data;
    }
    elsif ( $ref_type eq 'HASH' ) {
        my $trimmed_data = {};

        foreach my $key ( keys %$data ) {
            $trimmed_data->{$key} = $self->_auto_trim( $data->{$key} );
        }

        return $trimmed_data;
    }
    elsif ( $ref_type eq 'ARRAY' ) {
        my $trimmed_data = [];

        for ( my $i = 0; $i < @$data; $i++ ) {
            $trimmed_data->[$i] = $self->_auto_trim( $data->[$i] )
        }

        return $trimmed_data;
    }

    return $data;
}

1; # End of Validator::LIVR

=for HTML <a href="https://github.com/koorchik/Validator-LIVR/actions/workflows/test.yml"><img src="https://github.com/koorchik/Validator-LIVR/actions/workflows/test.yml/badge.svg?branch=master" alt="Tests"></a>
<a href="https://metacpan.org/dist/Validator-LIVR"><img src="https://img.shields.io/cpan/v/Validator-LIVR.svg" alt="CPAN version"></a>

=head1 NAME

Validator::LIVR - Lightweight validator supporting Language Independent Validation Rules Specification (LIVR)

=head1 SYNOPSIS

    use Validator::LIVR;

    my $validator = Validator::LIVR->new({
        name      => 'required',
        email     => [ 'required', 'email' ],
        gender    => { one_of => [ 'male', 'female' ] },
        phone     => { max_length => 10 },
        password  => [ 'required', { min_length => 10 } ],
        password2 => { equal_to_field => 'password' },
    });

    if ( my $valid_data = $validator->validate($user_data) ) {
        save_user($valid_data);
    } else {
        my $errors = $validator->get_errors();
        # { email => 'WRONG_EMAIL', password => 'TOO_SHORT' }
    }

=head1 DESCRIPTION

LIVR rules are plain data: a hash that maps field names to rules. They are
easy to read, and because the same rules work in
L<a dozen languages|https://livr-spec.org/introduction/implementations.html>,
one rule set can check a form in the browser with JavaScript and again on the
server with Perl.

This module implements L<LIVR 2.0|https://livr-spec.org> and passes the
test suite of the specification.

=over 4

=item * B<Declarative rules> that you can keep in JSON and share with other services.

=item * B<All errors at once>, not just the first one.

=item * B<Only described fields in the output.> A field without rules, such as an
unexpected C<is_admin>, never reaches your code.

=item * B<Nested data>: objects, lists, lists of objects and objects of several types.

=item * B<Error codes, not messages>, such as C<REQUIRED> or C<TOO_SHORT>. Turn them
into messages in any language you need.

=item * B<Data cleanup> with modifiers, such as C<trim>, C<to_lc> and C<default>.

=item * B<Your own rules>, as aliases of existing rules or as Perl code.

=item * B<No dependencies>: only modules that come with Perl.

=back

Use it for user input, configs, API requests and responses, or any other data
that has to have a known shape.

=head1 A QUICK TOUR

=head2 Writing rules

A rule set maps each field to its rules. A rule is written in one of these
ways:

    {
        name  => 'required',                        # a rule without arguments
        bio   => { max_length => 1000 },            # a rule with one argument
        nick  => { length_between => [ 3, 20 ] },   # a rule with several arguments
        email => [ 'required', 'email' ],           # several rules
    }

Several rules of a field are applied in order, and the field stops at its
first error. A hash is always one rule, so two rules with arguments are two
hashes: C<< [ { min_length => 3 }, { max_length => 20 } ] >>.

Most rules accept empty values: C<undef> and the empty string. So a field is
optional until you add C<required>:

    {
        age => 'positive_integer',                  # can be missing
        id  => [ 'required', 'positive_integer' ],  # must be present
    }

=head2 Validating nested data

Metarules describe the structure of the data, and errors have the same shape
as the data:

    my $validator = Validator::LIVR->new({
        order_id => [ 'required', 'positive_integer' ],
        address  => [ 'required', { nested_object => {
            country => [ 'required', { one_of => [ 'Ukraine', 'USA' ] } ],
            city    => 'required',
            zip     => 'positive_integer',
        } } ],
        products => [ 'required', 'not_empty_list', { list_of_objects => {
            product_id => [ 'required', 'positive_integer' ],
            quantity   => [ 'required', { min_number => 1 } ],
        } } ],
        tags => { list_of => [ 'string', { max_length => 10 } ] },
    });

For an order with an unknown country, a second product with a quantity of 0
and a second tag that is too long, C<get_errors> returns:

    {
        address  => { country => 'NOT_ALLOWED_VALUE' },
        products => [ undef, { quantity => 'TOO_LOW' } ],
        tags     => [ undef, 'TOO_LONG' ],
    }

=head2 Cleaning data

Modifiers change the value for the next rules and for the output:

    my $validator = Validator::LIVR->new({
        email => [ 'trim', 'required', 'email', 'to_lc' ],
        phone => { leave_only => '0123456789' },
        role  => [ { default => 'user' }, { one_of => [ 'user', 'admin' ] } ],
    });

    $validator->validate({ email => '  John@Example.COM ', phone => '+38 (050) 123-45-67' });
    # { email => 'john@example.com', phone => '380501234567', role => 'user' }

To trim every string of the input before validation, turn on auto trim for
one validator with C<< Validator::LIVR->new( $rules, 1 ) >>, or for all new
validators with C<< Validator::LIVR->default_auto_trim(1) >>.

=head2 Sharing rules with other languages

Rules are plain data, so they can live in a JSON file:

    {
        "email":    [ "required", "email" ],
        "password": [ "required", { "min_length": 10 } ]
    }

    use JSON::PP qw(decode_json);

    my $validator = Validator::LIVR->new( decode_json($json_rules) );

The same file works with L<livr|https://www.npmjs.com/package/livr> in
JavaScript, and with the
L<implementations|https://livr-spec.org/introduction/implementations.html> for
PHP, Python, Go, Java, Ruby, Erlang, Lua, Raku and Swift. You can try rules in
the L<playground|https://livr-spec.org/playground.html>.

=head2 Adding your own rules

The simplest way is an alias: a new name for a combination of rules, with its
own error code. Aliases are a part of the specification, so other
implementations understand them too.

    Validator::LIVR->register_aliased_default_rule({
        name  => 'adult_age',
        rules => [ 'positive_integer', { min_number => 18 } ],
        error => 'WRONG_AGE',
    });

    my $validator = Validator::LIVR->new({ age => [ 'required', 'adult_age' ] });

For anything else, write the rule in Perl, see L</WRITING RULES IN PERL>.

=head1 RULES

The built-in rules, grouped as in the specification. Each group links to its
page in the specification, which has the details and edge cases.

A rule that expects a string or a number returns C<FORMAT_ERROR> for a hash or
a list. A rule that expects a hash or a list returns C<FORMAT_ERROR> for
anything else.

=head2 Common rules

L<Specification|https://livr-spec.org/validation-rules/common-rules.html>

=over 4

=item C<required>

The field is present and not empty: not C<undef> and not C<''>.
Error: C<REQUIRED>.

=item C<not_empty>

The field can be missing, but when it is there, it is not C<''>.
Error: C<CANNOT_BE_EMPTY>.

=item C<not_empty_list>

The field is a list with at least one item.
Errors: C<CANNOT_BE_EMPTY>, C<FORMAT_ERROR>.

=item C<any_object>

The field is a hash with any content.
Error: C<FORMAT_ERROR>.

=back

=head2 String rules

L<Specification|https://livr-spec.org/validation-rules/string-rules.html>

=over 4

=item C<string>

Any string or number.
Error: C<FORMAT_ERROR>.

=item C<< { eq => $value } >>

The value is equal to C<$value>.
Error: C<NOT_ALLOWED_VALUE>.

=item C<< { one_of => [ @values ] } >>

The value is equal to one of C<@values>.
Error: C<NOT_ALLOWED_VALUE>.

=item C<< { min_length => $length } >>

The value has at least C<$length> characters.
Error: C<TOO_SHORT>.

=item C<< { max_length => $length } >>

The value has at most C<$length> characters.
Error: C<TOO_LONG>.

=item C<< { length_equal => $length } >>

The value has exactly C<$length> characters.
Errors: C<TOO_SHORT>, C<TOO_LONG>.

=item C<< { length_between => [ $min, $max ] } >>

The value has from C<$min> to C<$max> characters.
Errors: C<TOO_SHORT>, C<TOO_LONG>.

=item C<< { like => $regex } >>, C<< { like => [ $regex, 'i' ] } >>

The value matches the regular expression. The C<i> flag makes it case
insensitive.
Error: C<WRONG_FORMAT>.

The rule is experimental in the specification. The syntax of regular
expressions differs between languages, so stick to the common features when
you share rules.

=back

=head2 Numeric rules

L<Specification|https://livr-spec.org/validation-rules/numeric-rules.html>

=over 4

=item C<integer>

An integer, such as C<-5> or C<42>.
Error: C<NOT_INTEGER>.

=item C<positive_integer>

An integer greater than zero.
Error: C<NOT_POSITIVE_INTEGER>.

=item C<decimal>

A number, such as C<-1.5> or C<42>.
Error: C<NOT_DECIMAL>.

=item C<positive_decimal>

A number greater than zero.
Error: C<NOT_POSITIVE_DECIMAL>.

=item C<< { min_number => $min } >>

A number that is not less than C<$min>.
Errors: C<NOT_NUMBER>, C<TOO_LOW>.

=item C<< { max_number => $max } >>

A number that is not greater than C<$max>.
Errors: C<NOT_NUMBER>, C<TOO_HIGH>.

=item C<< { number_between => [ $min, $max ] } >>

A number from C<$min> to C<$max>.
Errors: C<NOT_NUMBER>, C<TOO_LOW>, C<TOO_HIGH>.

=back

=head2 Special rules

L<Specification|https://livr-spec.org/validation-rules/special-rules.html>

=over 4

=item C<email>

An email address, such as C<john.smith@example.com>, without a name, comments
or spaces around it. The domain has a TLD or is an IP address in brackets.
Error: C<WRONG_EMAIL>.

=item C<url>

An C<http> or C<https> URL, such as C<https://example.com/path?query#fragment>.
The host is a domain name, such as C<example.com> or C<intranet>, or an IPv4
address. Domain names in other languages work in decoded strings, not in UTF-8
bytes.
Error: C<WRONG_URL>.

=item C<iso_date>

A date as C<YYYY-MM-DD> that exists in the calendar: C<2024-02-29> is valid,
C<2025-02-29> is not.
Error: C<WRONG_DATE>.

=item C<< { equal_to_field => $field } >>

The value is equal to the value of another field, such as a password
confirmation.
Error: C<FIELDS_NOT_EQUAL>.

=back

=head2 Metarules

L<Specification|https://livr-spec.org/validation-rules/metarules.html>

Metarules validate nested data with their own rule sets. Their errors are
nested too: a hash of errors for an object, and a list for a list, with
C<undef> for the valid items.

=over 4

=item C<< { nested_object => \%rules } >>

A hash validated with C<\%rules>.

=item C<< { list_of => \@rules } >>, C<< { list_of => $rule } >>

A list, each item validated with the rules.

=item C<< { list_of_objects => \%rules } >>

A list of hashes, each validated with C<\%rules>.

=item C<< { variable_object => [ $selector, { $type => \%rules, ... } ] } >>

A hash validated with the rules for the value of its C<$selector> field. The
error is C<FORMAT_ERROR> when the hash has no rules for that value.

    payment => [ 'required', { variable_object => [ type => {
        card => {
            type        => 'required',
            card_number => [ 'required', { length_equal => 16 } ],
        },
        iban => {
            type => 'required',
            iban => 'required',
        },
    } ] } ],

=item C<< { list_of_different_objects => [ $selector, { $type => \%rules, ... } ] } >>

A list of hashes, each validated as in C<variable_object>.

=item C<< { or => [ $rules1, $rules2, ... ] } >>

The value passes at least one of the rule sets. Each rule set is a rule or a
list of rules. When all of them fail, the error is the error of the last one.

    id => { or => [ 'email', 'positive_integer' ] },

=back

=head2 Modifiers

L<Specification|https://livr-spec.org/validation-rules/modifiers.html>

Modifiers change the value and never fail.

=over 4

=item C<trim>

Removes the spaces at the start and at the end.

=item C<to_lc>

Converts to lower case.

=item C<to_uc>

Converts to upper case.

=item C<< { remove => $chars } >>

Removes each of the characters in C<$chars>, so C<< { remove => ' -()' } >>
turns C<(050) 123-45-67> into C<0501234567>.

=item C<< { leave_only => $chars } >>

Removes all characters except the ones in C<$chars>.

=item C<< { default => $value } >>

Sets C<$value> when the field is missing or empty.

=back

=head1 CLASS METHODS

=head2 new

    my $validator = Validator::LIVR->new( \%rules );
    my $validator = Validator::LIVR->new( \%rules, $is_auto_trim );

Creates a validator. With a true C<$is_auto_trim>, it trims all strings of the
input, the nested ones too, before validation, so the output is trimmed as
well. When C<$is_auto_trim> is C<undef>, the value set with
L</default_auto_trim> is used.

=head2 register_default_rules

    Validator::LIVR->register_default_rules(
        my_rule    => \&my_rule_builder,
        other_rule => \&other_rule_builder,
    );

Adds rules or replaces existing ones for all validators created after the call.
See L</WRITING RULES IN PERL> for how to write a rule builder.

=head2 register_aliased_default_rule

    Validator::LIVR->register_aliased_default_rule({
        name  => 'valid_address',
        rules => { nested_object => {
            country => 'required',
            city    => 'required',
            zip     => 'positive_integer',
        } },
        error => 'WRONG_ADDRESS',  # optional
    });

Adds an alias for all validators created after the call. Then the alias works
as any other rule:

    { address => [ 'required', 'valid_address' ] }

Without C<error>, the alias returns the error of its rules.

=head2 get_default_rules

    my $rule_builders = Validator::LIVR->get_default_rules();

Returns a hashref that maps rule names to the rule builders that new validators
get.

=head2 default_auto_trim

    Validator::LIVR->default_auto_trim(1);

Turns auto trim on or off for validators created after the call. See L</new>.

=head1 OBJECT METHODS

=head2 validate

    my $valid_data = $validator->validate( \%input );

Returns a hashref with the valid data: only the fields that have rules, with
the changes made by modifiers. On errors returns C<undef>, and L</get_errors>
returns the errors.

=head2 get_errors

    my $errors = $validator->get_errors();

Returns the errors of the last L</validate> call, or C<undef> when it passed.
The errors are a hashref that maps fields to error codes, with nested errors for
metarules:

    {
        email    => 'WRONG_EMAIL',
        address  => { zip => 'NOT_POSITIVE_INTEGER' },
        products => [ undef, { quantity => 'TOO_LOW' } ],
    }

When the input is not a hashref, the errors are the string C<FORMAT_ERROR>.

=head2 register_rules

    $validator->register_rules( my_rule => \&my_rule_builder, ... );

Adds rules or replaces existing ones, as L</register_default_rules> does, for
this validator only. Returns the validator, so the call can be chained.

=head2 register_aliased_rule

    $validator->register_aliased_rule({
        name  => 'strong_password',
        rules => { min_length => 12 },
        error => 'WEAK_PASSWORD',
    });

Adds an alias, as L</register_aliased_default_rule> does, for this validator
only. Returns the validator.

=head2 get_rules

    my $rule_builders = $validator->get_rules();

Returns a hashref that maps rule names to the rule builders of this validator.

=head2 prepare

    my $validator = Validator::LIVR->new($rules)->prepare();

Builds the validators of all rules and returns the validator. L</validate> does
it on the first call, so you need C<prepare> only to find mistakes early. It
dies with C<Rule [name] not registered> when a rule is unknown, and with
C<Rule [name1, name2] should have one name> when a hash has several rules.
Register your rules before C<prepare> or the first L</validate>.

=head1 WRITING RULES IN PERL

A rule is a builder: a sub that gets the arguments of the rule and returns a
validator sub. The builder is called once, when the validator is prepared. The
validator sub is called for every value.

Here is how C<max_number> could be written:

    use Scalar::Util qw(looks_like_number);

    Validator::LIVR->register_default_rules( max_number => sub {
        my ( $max_number, $rule_builders ) = @_;

        return sub {
            my ( $value, $all_values, $output_ref ) = @_;

            # Empty values are the job of "required"
            return if !defined($value) || $value eq '';

            return 'FORMAT_ERROR' if ref($value);
            return 'NOT_NUMBER'   if !looks_like_number($value);
            return 'TOO_HIGH'     if $value > $max_number;
            return;
        };
    });

The builder gets the arguments of the rule, then a hashref of all rule builders
of the validator:

    'my_rule'                         # ( $rule_builders )
    { my_rule => $arg }               # ( $arg, $rule_builders )
    { my_rule => [ $arg ] }           # ( $arg, $rule_builders )
    { my_rule => [ $arg1, $arg2 ] }   # ( $arg1, $arg2, $rule_builders )

The validator sub gets:

=over 4

=item C<$value>

The value of the field, as the previous rules of the field left it.

=item C<$all_values>

The hash that has the field, to compare it with other fields, as
C<equal_to_field> does. Inside C<list_of>, C<or> and aliases, rules check the
value on its own, so this hash has no other fields.

=item C<$output_ref>

A reference to the output value. Assign to it to change the value, as
modifiers do.

=back

It returns nothing when the value is valid, and an error code when it is not.

A modifier sets the output and returns nothing:

    Validator::LIVR->register_default_rules( to_ucfirst => sub {
        return sub {
            my ( $value, undef, $output_ref ) = @_;
            return if !defined($value) || ref($value) || $value eq '';

            $$output_ref = ucfirst($value);
            return;
        };
    });

With C<$rule_builders>, a rule can validate nested data with the same rules,
as metarules do:

    my $validator = Validator::LIVR->new($rules)->register_rules(%$rule_builders)->prepare();

The built-in rules are short and make good examples:
L<Validator::LIVR::Rules::Common>, L<Validator::LIVR::Rules::String>,
L<Validator::LIVR::Rules::Numeric>, L<Validator::LIVR::Rules::Special>,
L<Validator::LIVR::Rules::Meta> and L<Validator::LIVR::Rules::Modifiers>.

=head1 SEE ALSO

=over 4

=item * L<The LIVR specification|https://livr-spec.org>, with all rules,
L<aliases|https://livr-spec.org/rules-aliasing.html> and a
L<playground|https://livr-spec.org/playground.html>.

=item * L<The LIVR repository|https://github.com/koorchik/LIVR>, with the
specification and its test suite.

=item * L<LIVR implementations|https://livr-spec.org/introduction/implementations.html>
in other languages.

=back

=head1 BUGS AND SUPPORT

Please report bugs and ideas in
L<GitHub Issues|https://github.com/koorchik/Validator-LIVR/issues>. The source
is at L<https://github.com/koorchik/Validator-LIVR>.

You can read this documentation with C<perldoc Validator::LIVR>, or on
L<MetaCPAN|https://metacpan.org/pod/Validator::LIVR>.

=head1 AUTHOR

Viktor Turskyi, C<< <koorchik at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2026 Viktor Turskyi.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License (2.0). You may obtain a
copy of the full license at:

L<https://www.perlfoundation.org/artistic-license-20.html>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
