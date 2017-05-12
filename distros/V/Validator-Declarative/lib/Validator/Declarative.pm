#!/usr/bin/env perl
use strict;
use warnings;

package Validator::Declarative;
{
  $Validator::Declarative::VERSION = '1.20130722.2105';
}

# ABSTRACT: Declarative parameters validation

use Error qw/ :try /;
use Module::Load;
use Readonly;

Readonly my $RULE_CONSTRAINT => 'constraint';
Readonly my $RULE_CONVERTER  => 'converter';
Readonly my $RULE_TYPE       => 'type';

sub register_constraint { _register_rules( $RULE_CONSTRAINT => \@_ ) }
sub register_converter  { _register_rules( $RULE_CONVERTER  => \@_ ) }
sub register_type       { _register_rules( $RULE_TYPE       => \@_ ) }

sub validate {
    my $params      = shift;
    my $definitions = shift;

    throw Error::Simple('invalid "params"')
        if ref($params) ne 'ARRAY';

    throw Error::Simple('invalid rules definitions')
        if ref($definitions) ne 'ARRAY';

    throw Error::Simple('count of params does not match count of rules definitions')
        if scalar(@$params) * 2 != scalar(@$definitions);

    throw Error::Simple('extra parameters')
        if @_;

    # one-level copy to not harm input parameters
    $params      = [@$params];
    $definitions = [@$definitions];

    my ( @errors, @output );
    while (@$params) {
        my $value = shift @$params;
        my $name  = shift @$definitions;
        my $rules = shift @$definitions;

        try {
            my $normalized_rules = _normalize_rules($rules);
            my $is_optional = _check_constraints( $value, $normalized_rules->{constraints} );
            $value = _run_convertors( $value, $normalized_rules->{converters}, $is_optional );
            _check_types( $value, $normalized_rules->{types} ) if defined($value) && !$is_optional;
            push @output, $value;
        }
        catch Error with {
            my $error             = shift;
            my $stringified_value = $value;
            $stringified_value = '<undef>' if !defined($stringified_value);
            $stringified_value = 'empty string' if $stringified_value eq '';
            $stringified_value =~ s/[^[:print:]]/./g;
            push @errors, sprintf( '%s: %s %s', $name, $stringified_value, $error->{-text} );
            push @output, undef;
        };
    }

    throw Error::Simple( join "\n" => @errors ) if @errors;

    return @output;
}

#
# INTERNALS
#
my $registered_rules        = {};
my $registered_name_to_kind = {};

# stubs for successful/unsuccesfull validations
sub _validate_pass { my ($input) = @_; return $input; }
sub _validate_fail { throw Error::Simple('failed permanently'); }

sub _normalize_rules {
    my $rules = shift;

    my $types       = {};
    my $converters  = {};
    my $constraints = {};

    # if there were only one rule - normalize to arrayref anyway
    $rules = [$rules] if ref($rules) ne 'ARRAY';

    #
    # each rule can be string (name of simple rule) or arrayref/hashref (parametrized rule)
    # let's normalize them - convert everything to arrayrefs
    # hashrefs should not contain more than one key/value pair
    #
    # validator parameters (all items in resulting arrayref, except first one) should
    # left intact, i.e. if parameter was scalar, it should be saved as scalar,
    # arrayref as arrayref, and so on - there is no place for any conversion
    #
    foreach my $rule (@$rules) {
        my $result;

        if ( ref($rule) eq 'ARRAY' ) {
            $result = $rule;
        }
        elsif ( ref($rule) eq 'HASH' ) {
            throw Error::Simple('hashref rule should have exactly one key/value pair')
                if keys %$rule > 1;
            $result = [%$rule];
        }
        elsif ( ref($rule) ) {
            throw Error::Simple( 'rule definition can\'t be reference to ' . ref($rule) );
        }
        else {
            ## should be plain string, so this is name of simple rule
            $result = [$rule];
        }

        my $name   = $result->[0];
        my $params = $result->[1];

        throw Error::Simple("rule $name is not registered")
            if !exists $registered_name_to_kind->{$name};

        throw Error::Simple("rule $name can accept not more than one parameter")
            if @$result > 2;

        my $rule_kind = $registered_name_to_kind->{$name};

        if ( $rule_kind eq $RULE_TYPE ) {
            $types->{$name} = $params;
        }
        elsif ( $rule_kind eq $RULE_CONVERTER ) {
            $converters->{$name} = $params;
        }
        elsif ( $rule_kind eq $RULE_CONSTRAINT ) {
            $constraints->{$name} = $params;
        }
        else {
            ## we should never pass here
            die("internal error: rule $name is registered as $rule_kind");
        }
    }

    return {
        types       => $types,
        converters  => $converters,
        constraints => $constraints,
    };
}

sub _check_constraints {
    my ( $value, $constraints ) = @_;

    # check for built-in constraints (required/optional/not_empty)
    my $is_required = exists $constraints->{required};
    my $is_optional = exists $constraints->{optional};

    throw Error::Simple('both required and optional are specified')
        if $is_required && $is_optional;

    if ($is_optional) {
        delete $constraints->{optional};
        ## there is nothing else to do
    }
    else {
        delete $constraints->{required};

        throw Error::Simple('parameter is required')
            if !defined($value);

        # check for all non-built-in constraints
        while ( my ( $rule_name, $rule_params ) = each %$constraints ) {
            my $code = $registered_rules->{$RULE_CONSTRAINT}{$rule_name};
            $code->( $value, $rule_params );
        }
    }

    return $is_optional;
}

sub _run_convertors {
    my ( $value, $converters, $is_optional ) = @_;

    # process "default" converter (if any)
    my $has_default = exists $converters->{default};

    throw Error::Simple('"default" specified without "optional"')
        if $has_default && !$is_optional;

    if ($has_default) {
        $value = $converters->{default} if !defined($value);
        delete $converters->{default};
    }

    throw Error::Simple('there is more than one converter, except "default"')
        if keys %$converters > 1;

    # process non-"default" converter (if any)
    if (%$converters) {
        my ( $rule_name, $rule_params ) = %$converters;
        my $code = $registered_rules->{$RULE_CONVERTER}{$rule_name};
        $value = $code->( $value, $rule_params );
    }

    return $value;
}

sub _check_types {
    my ( $value, $types ) = @_;

    # first successful check wins, all others will not be checked
    return if !%$types || exists( $types->{any} ) || exists( $types->{string} );

    my $saved_error;
    while ( my ( $rule_name, $rule_params ) = each %$types ) {
        my $last_error;
        try {
            my $code = $registered_rules->{$RULE_TYPE}{$rule_name};
            $code->( $value, $rule_params );
        }
        catch Error with {
            $last_error = $saved_error = shift;
        };
        return if !$last_error;
    }

    if ( scalar keys %$types == 1 ) {
        throw $saved_error;
    }
    else {
        throw Error::Simple('does not satisfy any type');
    }
}

sub _register_rules {
    my $kind  = shift;
    my $rules = shift;

    throw Error::Simple(qq|Can't register rule of kind <$kind>|)
        if $kind ne $RULE_TYPE
        && $kind ne $RULE_CONVERTER
        && $kind ne $RULE_CONSTRAINT;

    $rules = {@$rules};

    while ( my ( $name, $code ) = each %$rules ) {

        throw Error::Simple(qq|Can't register rule without name|)
            if !defined($name) || !length($name);

        throw Error::Simple(qq|Rule <$name> already registered|)
            if exists( $registered_name_to_kind->{$name} );

        $registered_rules->{$kind}{$name} = $code;
        $registered_name_to_kind->{$name} = $kind;
    }
}

sub _register_default_constraints {
    ## built-in constraints implemented inline
    $registered_name_to_kind->{$_} = $RULE_CONSTRAINT for qw/ required optional not_empty /;
}

sub _register_default_converters {
    ## built-in converters implemented inline
    $registered_name_to_kind->{$_} = $RULE_CONVERTER for qw/ default /;
}

sub _register_default_types {
    ## built-in types implemented inline
    $registered_name_to_kind->{$_} = $RULE_TYPE for qw/ any string /;
}

sub _load_base_rules {
    for my $plugin (qw/ SimpleType ParametrizedType Converters /) {
        my $module = __PACKAGE__ . '::Rules::' . $plugin;
        load $module;
    }
}

_register_default_constraints();
_register_default_converters();
_register_default_types();
_load_base_rules();


1;    # End of Validator::Declarative


__END__
=pod

=head1 NAME

Validator::Declarative - Declarative parameters validation

=head1 VERSION

version 1.20130722.2105

=head1 SYNOPSIS

    sub MakeSomethingCool {
        my $serialized_parameters;
        my ( $ace_id, $upm_id, $year, $week, $timestamp_ms ) = Validator::Declarative->validate(
            \@_ => [
                ace_id         => 'id',
                upm_id         => 'id',
                year           => 'year',
                week           => 'week',
                timestamp_ms   => [ 'to_msec', 'mdy', 'timestamp' ],
            ],
        );

        # here all parameters are validated
        # .......

    }

=head1 DESCRIPTION

Almost every function checks the input parameters, in one or other manner. But
often checking of some parameters are not made at all or are made not properly.

In most cases, checking is done by means of one or more conditional statements
for each parameter individually. This reduces the readability of the code and
makes it difficult to maintain.

Often checking is done using "unless" with several conditions, which make
things even worse.

Also, lot of conditional statements increases the cyclomatic complexity of the
function, which makes it impossible to use automated tests to check the quality
and complexity of the code.

To solve these problems, we can use declarative description of function
parameters.

=head1 IMPLEMENTATION

In general, code for declarative validation definition looks like this:

    my ($param1_name, $param2_name) = Validator::Declarative->validate( \@_ => [
        param1_name => [ validation_definition1    ],
        param2_name => [ validation_definitions2   ],
        ....
    ]);

This is usual key=>value pairs, but it should be written as array, not as hash,
because order does matter: one pair represents one parameter, and order of
pairs should be same as order of parameters in @_.

Each validation definition is an array ref. For simple cases, when validation
definition is represented by only one rule, we can type less and skip
surrounding brackets:

    my ($param1_name, $param2_name, $param3_name, $param4_name) = Validator::Declarative->validate( \@_ => [
        param1_name => 'name_of_rule1',
        param2_name => { 'name_of_rule2' => param_for_rule2 },
        param3_name => { 'name_of_rule3' => [ params_for_rule3 ] },
        param4_name => { 'name_of_rule4' => { hash_of_params_for_rule4 } },
        ....
    ]);

These are shortcuts for:

    my ($param1_name, $param2_name, $param3_name, $param4_name) = Validator::Declarative->validate( \@_ => [
        param1_name => [ 'name_of_rule1'                                         ],
        param2_name => [ { 'name_of_rule2' => param_for_rule2 }                  ],
        param3_name => [ { 'name_of_rule3' => [ params_for_rule3 ] }             ],
        param4_name => [ { 'name_of_rule4' => { hash_of_params_for_rule4 } }     ],
        ....
    ]);

=head2 Grammars

Grammars for validation rules are:

=head3 simple

    validation_rule ::= 'rule_name'

=head3 parameterized

    validation_rule ::= { 'rule_name' => 'parameter' }
    validation_rule ::= { 'rule_name' => [ 'parameter' ] }
    validation_rule ::= { 'rule_name' => [ 'param1', 'param2', ... ] }
    validation_rule ::= { 'rule_name' => { 'param1' => 'param2', ... } }

=head3 set of rules

    validation_rule ::= validation_rule, validation_rule, ....

=head2 Rules

Possible kinds of rules are: types (simple and parametrized), converters,
constraints.

Simple and parametrized rules works only on defined values, for undef all of
them return OK (this is needed to support declarations of optional parameters).

=head2 Simple types

=head3 any

always true, aliases: B<string>

=head3 bool

qr/^(1|true|yes|0|false|no|)$/i,
empty string accepted as false,
arbitrary data is not allowed

=head3 float

qr/^[+-]?\d+(:?\.\d*)?$/

=head3 int

qr/^[+-]?\d+$/, aliases: B<integer>

=head3 positive

>0

=head3 negative

<0

=head3 id

B<int> && B<positive>

=head3 email

result of Email::Valid->address($_)

=head2 Simple types (date-like)

=head3 year

B<int> && [1970 .. 3000]

=head3 week

B<int> && [1 .. 53]

=head3 month

B<int> && [1 .. 12]

=head3 day

B<int> && [1 .. 31]

=head3 ymd

like YYYY-MM-DD

=head3 mdy

like M/D/Y (M and D can be 1 or 2 digits, Y can be 2 or 4 digits)

=head3 time

like HH:MM:SS, 00:00:00 ... 23:59:59

=head3 hhmm

like HH:MM, 00:00 ... 23:59

=head3 timestamp

almost same as B<float> (because of L<Time::HiRes>), but can't have sign

=head3 msec

timestamp in milliseconds (ts/1000), alias to B<timestamp>

=head2 Parametrized types

=head3 min => value

minimal accepted value for parameter

=head3 max => value

maximal accepted value for parameter

=head3 ref => ref_type | [ref_types]

ref($_) && ref($_) eq (any of @ref_types)

=head3 class => class_name | [class_names]

blessed($_) && $_->isa(any of @class_names)

=head3 can => method_name | [method_names]

blessed($_) && $_->can(all of @method_names), aliases: B<ducktype>

=head3 can_any => method_name | [method_names]

blessed($_) && $_->can(any of @method_names)

=head3 any_of => [values]

anything from values provided in array ref, aliases: B<enum>

=head3 list_of => validation_rule

list of "values with specific validation check", B<recursive>

=head3 hash_of => { simple_type => validation_rule }

hash of "keys with specific simple type"
to "values with specific validation check", B<recursive>

=head3 hash_of => [ validation_rule => validation_rule ]

hash of "keys with specific validation check"
to "values with specific validation check", B<recursive>

=head3 hash => { key => validation_rule, .... }

hash with specified key names (not required to exists)
and "values with specific validation check", B<recursive>

=head3 date => format | [formats]

date/time in specific format

=head2

Types B<ref> and B<class> can be used as simple (without parameter), in this
case they check whether ref($_) and blessed($_) returns true.

Type B<date> can be used as simple (without parameter), in this case it accept
all same formats that accepted by any_to_mdy():

    /^20\d\d\d\d\d\d$/
    /^[+-]?\d{1,10}$/
    /^[+-]?\d{11,13}$/
    /^\d\d\d\d-?\d\d-?\d\d(?:t\d\d:?\d\d:?\d\d(?:z|\+00)?)?$/i
    /\d+\D+\d+\D+\d+/

When parameter to B<date> is not skipped, it should be name of any of date-like
simple type ('year', 'week', 'mdy' etc) or formatting string for
DateTime::Format::Strptime::parse_datetime (example: '%e/%b/%Y:%H:%M:%S %z',
see L<DateTime::Format::Strptime> for details). There is no strict requirement
for installed L<DateTime::Format::Strptime> - if module can't be loaded,
checking with the appropriate format will always lead to a positive result.

=head2 Converters

=head3 default => value

substitute $_ with provided value (only when actual parameter is B<undef>)

=head3 assume_true

substitute $_ with 0 if it looks like false value (see L<bool>, except for
empty string), and 1 otherwise

=head3 assume_false

substitute $_ with 1 if it looks like true value (see L<bool>, except for
empty string), and 0 otherwise

=head2 Constraints

=head3 required

result of defined($_), applied by default

=head3 optional

OK if !defined($_)

=head3 not_empty

for B<list_of>/B<hash_of>/B<hash>: has at least one element

for B<any>/B<string>: length($_) > 0

=head2 Order of execution

Order of rules in validation definition doesn't matters.

All specified rules will be executed in this order:

=head3 1. Actual parameter is checked to satisfy all constraints.

It's error to specify both B<required> and B<optional> at the same time.

If none of B<required> and B<optional> were specified, then B<required> is
implied.

=head3 2. Actual parameter is passed thru converter (if any).

It's error to specify more than one converter, except for B<default>. If
present, B<default> will be executed at first place.

It's error to specify B<default> if there is no B<optional> constraint.

=head3 3. Parameter (actual or modified by converter, if any) is checked to satisfy any type (simple or parametrized).

If no one type were specified, then B<any> is implied.

Order of types in checking is not defined and doesn't matter.

First successful check will finish entire validation for this parameter.

=head2 Errors and logging

For any calls B<all> parameters will be checked, and in case of any errors
exception should be thrown.

Description of B<all> errors will be included into exception text message.

=head1 METHODS

=head2 validate(\@params => \@rules)

=head2 register_type( $name => $code, ...)

=head2 register_converter( $name => $code, ...)

=head2 register_constraint( $name => $code, ...)

=head1 EXAMPLES

    # Parameter is optional, and can be any type
    field_name => [ 'any', 'optional' ]

    # Parameter is optional, and it's id in database
    field_name => [ 'id',  'optional' ]

    # Parameter is optional, and it's id in database, with default value
    field_name => [ 'id',  'optional', {default => undef} ]

    # Parameter is optional, and it's id or list of ids in database
    field_name => [ 'id',  'optional', {list_of => 'id'}  ]

    # Parameter is mandatory, and can be any type
    field_name => 'any'     # full form:     [ 'required', 'any' ]

    # Parameter is mandatory, and it's id in database
    field_name => 'id'      # full form:     [ 'required', 'id'  ]

    # Parameter is mandatory, and it's id or list of ids in database
    field_name => [ 'id', {list_of => 'id'} ]
    # full form:  [ 'required', 'id', {list_of => 'id'} ]

    # Parameter is bool and optional
    field_name => [ 'bool', 'optional' ]

    # Parameter is bool and optional, and default is true
    field_name => [ 'bool', 'optional', {default => 1} ]

    # Parameter args is mandatory, and it's hash with keys:
    #   - suspensions: not required, hash with keys:
    #       - cssnote_ref: not required, id
    #       - review_deadline: not required, timestamp
    #       - reasons: required, can be id or list of ids
    #   - resumptions: not required, hash with keys:
    #       - cssnote_ref: not required, id
    #       - reasons: required, can be id, list of ids or hash "id to id"
    # At least one key (suspensions or resumptions) should exists in args.
    args => [ 'not_empty', { hash => {
        suspensions => { hash => {
            cssnote_ref     => [ 'optional', 'id' ],
            review_deadline => [ 'optional', 'timestamp' ],
            reasons         => [ 'id', {list_of => 'id'} ],
        }},
        resumptions => { hash => {
            cssnote_ref     => [ 'optional', 'id' ],
            reasons         => [ 'id', {list_of => 'id'}, {hash_of => {'id' => 'id'}} ],
        }},
    }}]

=head1 SEE ALSO

Inspired by Validator::LIVR - L<https://github.com/koorchik/Validator-LIVR>

=head1 AUTHOR

Oleg Kostyuk, C<< <cub at cpan.org> >>

=head1 TODO

Implement types B<list_of>, B<hash_of>, B<hash> and B<date>.

Implement additional converters, like B<to_ts>, B<to_mdy> and several others.

=head1 BUGS

Please report any bugs or feature requests to Github
L<https://github.com/cub-uanic/Validator-Declarative>

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Oleg Kostyuk.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

