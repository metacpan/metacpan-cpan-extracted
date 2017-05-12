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

our $VERSION = '2.0';

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
        validator_builders => {},
        errors             => undef,
        is_auto_trim       => ( $is_auto_trim // $IS_DEFAULT_AUTO_TRIM )
    }, $class;

    $self->register_rules(%DEFAULT_RULES);

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

    while ( my ($field, $field_rules) = each %$all_rules ) {
        $field_rules = [$field_rules] if ref($field_rules) ne 'ARRAY';

        my @validators;
        foreach my $rule (@$field_rules) {
            my ($name, $args) = $self->_parse_rule($rule);
            push @validators, $self->_build_validator($name, $args);
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

    foreach my $field_name ( keys %{ $self->{validators} } ) {
        my $validators = $self->{validators}{$field_name};
        next unless $validators && @$validators;

        my $value = $data->{$field_name};
        my $is_ok = 1;

        foreach my $v_cb (@$validators) {
            my $field_result = $result{$field_name} // $value;

            my $err_code = $v_cb->(
                exists $result{$field_name} ? $result{$field_name} : $value,
                $data,
                \$field_result
            );

            if ( $err_code ) {
                $errors{$field_name} = $err_code;
                $is_ok = 0;
                last;
            } elsif ( defined($field_result) ) {
                $result{$field_name} = $field_result;
            } elsif ( exists $data->{$field_name} && ! exists $result{$field_name}) {
                $result{$field_name} = $field_result;
            }
        }
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
        ($name) = keys %$livr_rule;

        $args = $livr_rule->{$name};
        $args = [$args] unless ref($args) eq 'ARRAY';
    } else {
        $name = $livr_rule;
        $args = [];
    }

    return ($name, $args);
}

sub _build_validator {
    my ($self, $name, $args) = @_;
    die "Rule [$name] not registered\n" unless $self->{validator_builders}->{$name};

    return $self->{validator_builders}->{$name}->( @$args, $self->get_rules() );
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

=for HTML <a href="https://travis-ci.org/koorchik/Validator-LIVR"><img src="https://travis-ci.org/koorchik/Validator-LIVR.svg?branch=master"></a>

=head1 NAME

Validator::LIVR - Lightweight validator supporting Language Independent Validation Rules Specification (LIVR)

=head1 SYNOPSIS

    # Common usage
    Validator::LIVR->default_auto_trim(1);

    my $validator = Validator::LIVR->new({
        name      => 'required',
        email     => [ 'required', 'email' ],
        gender    => { one_of => ['male', 'female'] },
        phone     => { max_length => 10 },
        password  => [ 'required', {min_length => 10} ],
        password2 => { equal_to_field => 'password' }
    });

    if ( my $valid_data = $validator->validate($user_data) ) {
       save_user($valid_data);
    } else {
       my $errors = $validator->get_errors();
       ...
    }

    # You can use modifiers separately or can combine them with validation:
    my $validator = Validator::LIVR->new({
        email => [ 'required', 'trim', 'email', 'to_lc' ]
    });

    # Feel free to register your own rules
    # You can use aliases(prefferable, syntax covered by the specification) for a lot of cases:

    my $validator = Validator::LIVR->new({
        password => ['required', 'strong_password']
    });

    $validator->register_aliased_rule({
        name  => 'strong_password',
        rules => {min_length => 6},
        error => 'WEAK_PASSWORD'
    });

    # or you can write more sophisticated rules directly

    my $validator = Validator::LIVR->new({
        password => ['required', 'strong_password']
    });

    $validator->register_rules( 'strong_password' =>  sub {
        return sub {
            my $value = shift;

            # We already have "required" rule to check that the value is present
            return if !defined($value) || $value eq '';

            return 'WEAK_PASSWORD' if length($value) < 6;
            return;
        }
    } );


    # If you want to stop on the first error
    # you can overwrite all rules with your own which use exceptions
    my $default_rules = Validator::LIVR->ger_default_rules();

    while ( my ($rule_name, $rule_builder) = each %$default_rules ) {
        Validator::LIVR->register_default_rules($rule_name => sub {
            my $rule_validator = $rule_builder->(@_);

            return sub {
                my $error = $rule_validator->(@_);
                die $error if $error;
                return;
            }
        });
    }

=head1 DESCRIPTION

L<Validator::LIVR> lightweight validator supporting Language Independent Validation Rules Specification (LIVR)

See L<http://livr-spec.org> for rules documentation.

Features:

=over 4

=item * Rules are declarative and language independent

=item * Any number of rules for each field

=item * Return together errors for all fields

=item * Excludes all fields that do not have validation rules described

=item * Has possibility to validatate complex hierarchical structures

=item * Easy to describe and undersand rules

=item * Returns understandable error codes(not error messages)

=item * Easy to add own rules

=item * Multipurpose (user input validation, configs validation, contracts programming etc)

=back

=head1 CLASS METHODS

=head2 Validator::LIVR->new( $LIVR [, $IS_AUTO_TRIM] )

Contructor creates validator objects.

$LIVR - validations rules. Rules description is available here - L<https://github.com/koorchik/LIVR>

$IS_AUTO_TRIM - asks validator to trim all values before validation. Output will be also trimmed.
if $IS_AUTO_TRIM is undef than default_auto_trim value will be used.

=head2 Validator::LIVR->register_aliased_default_rule( $ALIAS )

$ALIAS - is a hash that contains: name, rules, error (optional).

    Validator::LIVR->register_aliased_default_rule({
        name  => 'valid_address',
        rules => { nested_object => {
            country => 'required',
            city    => 'required',
            zip     => 'positive_integer'
        }}
    });

Then you can use "valid\_address" for validation:

    {
        address => 'valid_address'
    }


You can register aliases with own errors:

    Validator::LIVR->register_aliased_default_rule({
        name  => 'adult_age'
        rules => [ 'positive_integer', { min_number => 18 } ],
        error => 'WRONG_AGE'
    });

All rules/aliases for the validator are equal. The validator does not distinguish "required", "list\_of\_different\_objects" and "trim" rules. So, you can extend validator with any rules/alias you like.


=head2 Validator::LIVR->register_default_rules( RULE_NAME => \&RULE_BUILDER, ... )

&RULE_BUILDER - is a subtorutine reference which will be called for building single rule validator.


    Validator::LIVR->register_default_rules( my_rule => sub {
        my ($arg1, $arg2, $arg3, $rule_builders) =  @_;

        # $rule_builders - are rules from original validator
        # to allow you create new validator with all supported rules
        # my $validator = Validator::LIVR->new($livr)->register_rules(%$rule_builders)->prepare();

        return sub {
            my ( $value, $all_values, $output_ref ) = @_;

            if ($not_valid) {
                return "SOME_ERROR_CODE"
            }
            else {

            }

        }
    });

Then you can use "my_rule" for validation:

    {
        name1 => 'my_rule' # Call without parameters
        name2 => { 'my_rule' => $arg1 } # Call with one parameter.
        name3 => { 'my_rule' => [$arg1] } # Call with one parameter.
        name4 => { 'my_rule' => [ $arg1, $arg2, $arg3 ] } # Call with many parameters.
    }


Here is "max_number" implemenation:

    sub max_number {
        my $max_number = shift;

        return sub {
            my $value = shift;

            # We do not validate empty fields. We have "required" rule for this purpose
            return if !defined($value) || $value eq '';

            return 'TOO_HIGH' if $value > $max_number; # Return error message
            return; # returning undef means that there was no errors;
        };
    }

    Validator::LIVR->register_default_rules( max_number => \&max_number );

All rules for the validator are equal. It does not distinguish "required", "list_of_different_objects" and "trim" rules.
So, you can extend validator with any rules you like.

Just look at the existing rules implementation:

=over 4

=item * L<Validator::LIVR::Rules::Common>

=item * L<Validator::LIVR::Rules::String>;

=item * L<Validator::LIVR::Rules::Numeric>;

=item * L<Validator::LIVR::Rules::Special>;

=item * L<Validator::LIVR::Rules::Meta>;

=item * L<Validator::LIVR::Rules::Modifiers>;

=back

All rules description is available here - L<https://github.com/koorchik/LIVR>


=head2 Validator::LIVR->get_default_rules( )

returns hashref containing all default rule_builders for the validator.
You can register new rule or update existing one with "register_rules" method.

=head2 Validator::LIVR->default_auto_trim($IS_AUTO_TRIM)

Enables or disables automatic trim for input data. If is on then every new validator instance will have auto trim option enabled

=head1 OBJECT METHODS

=head2 $VALIDATOR->validate(\%INPUT)

Validates user input. On success returns $VALID_DATA (contains only data that has described validation rules). On error return false.

    my $VALID_DATA = $VALIDATOR->validate(\%INPUT)

    if ($VALID_DATA) {

    } else {
        my $errors = $VALIDATOR->get_errors();
    }

=head2 $VALIDATOR->get_errors( )

Returns errors hash.

    {
        "field1" => "ERROR_CODE",
        "field2" => "ERROR_CODE",
        ...
    }

For example:

    {
        "country"  => "NOT_ALLOWED_VALUE",
        "zip"      => "NOT_POSITIVE_INTEGER",
        "street"   => "REQUIRED",
        "building" => "NOT_POSITIVE_INTEGER"
    },

=head2 $VALIDATOR->register_rules( RULE_NAME => \&RULE_BUILDER, ... )

&RULE_BUILDER - is a subtorutine reference which will be called for building single rule validator.

See "Validator::LIVR->register_default_rules" for rules examples.

=head2 $VALIDATOR->register_aliased_rule( $ALIAS )

$ALIAS - is a composite validation rule.

See "Validator::LIVR->register_aliased_default_rule" for rules examples.

=head2 $VALIDATOR->get_rules( )

returns hashref containing all rule_builders for the validator. You can register new rule or update existing one with "register_rules" method.

=head1 AUTHOR

Viktor Turskyi, C<< <koorchik at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/koorchik/Validator-LIVR>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Validator::LIVR


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator-LIVR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Validator-LIVR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Validator-LIVR>

=item * Search CPAN

L<http://search.cpan.org/dist/Validator-LIVR/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Viktor Turskyi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

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
