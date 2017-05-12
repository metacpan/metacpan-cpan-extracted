# ABSTRACT: Validation::Class Core Directives Registry

package Validation::Class::Directives;

use strict;
use warnings;

use base 'Validation::Class::Mapping';

use Validation::Class::Util '!has';

use List::MoreUtils 'first_index';
use Module::Find 'usesub';
use Carp 'confess';

use List::MoreUtils;

our $_registry = {};

foreach my $module (usesub 'Validation::Class::Directive') {
    $_registry->{$module} = $module->new
        if $module->isa('Validation::Class::Directive')
    ;
}

our $VERSION = '7.900057'; # VERSION


sub new {

    my $class = shift;

    my $arguments = $class->build_args(@_);

    $arguments = $_registry unless keys %{$arguments};

    my $self = bless {}, $class;

    $self->add($arguments);

    return $self;

}

sub add {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    while (my ($key, $value) = each %{$arguments}) {

        # never overwrite
        unless (defined $self->{$key}) {
            # is it a direct directive?
            if ("Validation::Class::Directive" eq ref $value) {
                $self->{$key} = $value;
            }
            # is it a directive sub-class
            elsif (isa_classref($value)) {
                if ($value->isa("Validation::Class::Directive")) {
                    $self->{$value->name} = $value;
                }
            }
            # is it a hashref
            elsif (isa_hashref($value)) {
                $self->{$key} = Validation::Class::Directive->new($value);
            }
        }

    }

    return $self;

}

sub resolve_dependencies {

    my ($self, $type) = @_;

    $type ||= 'validation';

    my $dependencies = {};

    foreach my $key ($self->keys) {

        my $class      = $self->get($key);
        my $name       = $class->name;
        my $dependents = $class->dependencies->{$type};

        # avoid invalid dependencies by excluding the unknown
        $dependencies->{$name} = [grep { $self->has($_) } @{$dependents}];

    }

    my @ordered;
    my %found;
    my %track;

    my @pending =  keys %$dependencies;
    my $limit   =  scalar(keys %$dependencies);
       $limit   += scalar(@{$_}) for values %$dependencies;

    while (@pending) {

        my $k = shift @pending;

        if (grep { $_ eq $k } @{$dependencies->{$k}}) {

            confess sprintf 'Direct circular dependency on event %s: %s -> %s',
            $type, $k, $k;

        }

        elsif (grep { ! exists $found{$_} } @{$dependencies->{$k}}) {

            confess sprintf 'Invalid dependency on event %s: %s -> %s',
            $type, $k, join(',', @{$dependencies->{$k}})
            if grep { ! exists $dependencies->{$_} } @{$dependencies->{$k}};

            confess
            sprintf 'Indirect circular dependency on event %s: %s -> %s ',
            $type, $k, join(',', @{$dependencies->{$k}})
            if $track{$k} && $track{$k} > $limit; # allowed circular iterations

            $track{$k}++ if push @pending, $k;

        }

        else {

            $found{$k} = 1;
            push @ordered, $k;

        }

    }

    my @list = reverse @ordered;

    foreach my $x (keys %$dependencies) {

        foreach my $y (@{$dependencies->{$x}}) {

            my $a = first_index { $_ eq $x } @list;
            my $b = first_index { $_ eq $y } @list;

            confess sprintf
                'Broken dependency chain; Faulty ordering on '.
                'event %s: %s before %s', $type, $x, $y
                if $a > $b
            ;

        }

    }

    return (@ordered);

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directives - Validation::Class Core Directives Registry

=head1 VERSION

version 7.900057

=head1 DESCRIPTION

Validation::Class::Directives provides a collection of installed
Validation::Class directives. This class inherits from
L<Validation::Class::Mapping>. Please look at L<Validation::Class::Directive>
for information of developing your own directives.

=head1 RATIONALE

The following is a list of core directives that get installed automatically with
Validation::Class and can be used to jump-start your data validation initiative.
B<Please Note!> The purpose of the core directives is merely to provide a
reasonable layer of protection against bad/malformed data, the validators are
not very sophisticated and were created using a minimal level of strictness
(e.g. the email and hostname directives do not perform a hostname lookup nor
does the email directive conform to the RFC specification).

Various applications have varied levels of strictness regarding various types
of input (e.g. a hospital API may require a more sophisticated SSN validation
than that of a department of education API; likewise; an email service API may
require a more sophisticated email validation than that of a file sharing API).
Validation::Class does not attempt to provide validators for all levels of
strictness and the core directives exist to support typical use-cases with
a minimal level of strictness.

=head2 alias

The alias directive is provided by L<Validation::Class::Directive::Alias> and
handles parameter aliases.

=head2 between

The between directive is provided by L<Validation::Class::Directive::Between>
and handles numeric range validation.

=head2 city

The city directive is provided by L<Validation::Class::Directive::City> and
handles city/area validation for cities in the USA.

=head2 creditcard

The creditcard directive is provided by L<Validation::Class::Directive::Creditcard>
and handles validation for american express, bankcard, diners card,
discover card, electron,  enroute, jcb, maestro, mastercard, solo, switch, visa
and voyager credit cards.

=head2 date

The date directive is provided by L<Validation::Class::Directive::Date> and
handles validation of simple date formats.

=head2 decimal

The decimal directive is provided by L<Validation::Class::Directive::Decimal>
and handles validation of floating point integers.

=head2 default

The default directive is provided by L<Validation::Class::Directive::Default>
and hold the value which should be used if no parameter is supplied.

=head2 depends_on

The depends_on directive is provided by L<Validation::Class::Directive::DependsOn>
and validates the existence of dependent parameters.

=head2 email

The email directive is provided by L<Validation::Class::Directive::Email>
and checks the validity of email address specified by the associated parameters
within reason. Please note, the email directive does not perform a host lookup
nor does it conform to the RFC specification.

=head2 error

The error directive is provided by L<Validation::Class::Directive::Error>
and holds the error message that will supersede any other error messages that
attempt to register errors at the field-level for the associated field.

=head2 errors

The errors directive is provided by L<Validation::Class::Directive::Errors>
and is a container (object) which holds error message registered at the field-level
for the associated field.

=head2 filtering

The filtering directive is provided by L<Validation::Class::Directive::Filtering>
and specifies whether filtering and sanitation should occur as a pre-process or
post-process.

=head2 filters

The filters directive is provided by L<Validation::Class::Directive::Filters>
and specifies which filter should be executed on the associated field.

=head2 hostname

The hostname directive is provided by L<Validation::Class::Directive::Hostname>
and handles validatation of server hostnames.

=head2 label

The label directive is provided by L<Validation::Class::Directive::Label>
and holds a user-friendly string (name) representing the associated field.

=head2 length

The length directive is provided by L<Validation::Class::Directive::Length>
and validates the exact length of the associated parameters.

=head2 matches

The matches directive is provided by L<Validation::Class::Directive::Matches>
and validates whether the value of the dependent parameters matches that of the
associated field.

=head2 max_alpha

The max_alpha directive is provided by L<Validation::Class::Directive::MaxAlpha>
and validates the length of alphabetic characters in the associated parameters.

=head2 max_digits

The max_digits directive is provided by L<Validation::Class::Directive::MaxDigits>
and validates the length of numeric characters in the associated parameters.

=head2 max_length

The max_length directive is provided by L<Validation::Class::Directive::MaxLength>
and validates the length of all characters in the associated parameters.

=head2 max_sum

The max_sum directive is provided by L<Validation::Class::Directive::MaxSum>
and validates the numeric value of the associated parameters.

=head2 max_symbols

The max_symbols directive is provided by L<Validation::Class::Directive::MaxSymbols>
and validates the length of non-alphanumeric characters in the associated parameters.

=head2 messages

The messages directive is provided by L<Validation::Class::Directive::Messages>
and is a container (object) which holds error message which will supersede the
default error messages of the associated directives.

=head2 min_alpha

The min_alpha directive is provided by L<Validation::Class::Directive::MinAlpha>
and validates the length of alphabetic characters in the associated parameters.

=head2 min_digits

The min_digits directive is provided by L<Validation::Class::Directive::MinDigits>
and validates the length of numeric characters in the associated parameters.

=head2 min_length

The min_length directive is provided by L<Validation::Class::Directive::MinLength>
and validates the length of all characters in the associated parameters.

=head2 min_sum

The min_sum directive is provided by L<Validation::Class::Directive::MinSum>
and validates the numeric value of the associated parameters.

=head2 min_symbols

The min_symbols directive is provided by L<Validation::Class::Directive::MinSymbols>
and validates the length of non-alphanumeric characters in the associated parameters.

=head2 mixin

The mixin directive is provided by L<Validation::Class::Directive::Mixin>
and determines what directive templates will be merged with the associated field.

=head2 mixin_field

The mixin_field directive is provided by L<Validation::Class::Directive::MixinField>
and determines what fields will be used as templates and merged with the associated
field.

=head2 multiples

The multiples directive is provided by L<Validation::Class::Directive::Multiples>
and validates whether the associated parameters may contain a multi-value
(an array of strings).

=head2 name

The name directive is provided by L<Validation::Class::Directive::Name>
and merely holds the name of the associated field. This value is populated
automatically.

=head2 options

The options directive is provided by L<Validation::Class::Directive::Options> and
holds an enumerated list of values to be validated against the associated
parameters.

=head2 pattern

The pattern directive is provided by L<Validation::Class::Directive::Pattern> and
handles validation of simple patterns and complex regular expressions.

=head2 readonly

The readonly directive is provided by L<Validation::Class::Directive::Readonly>
and determines whether the associated parameters should be ignored.

=head2 required

The required directive is provided by L<Validation::Class::Directive::Required>
and handles validation of supply and demand.

=head2 ssn

The ssn directive is provided by L<Validation::Class::Directive::SSN> and
handles validation of social security numbers in the USA.

=head2 state

The state directive is provided by L<Validation::Class::Directive::State> and
handles state validation for states in the USA.

=head2 telephone

The telephone directive is provided by L<Validation::Class::Directive::Telephone>
and handles telephone number validation for the USA and North America.

=head2 time

The time directive is provided by L<Validation::Class::Directive::Time>
and handles validation for standard time formats.

=head2 toggle

The toggle directive is provided by L<Validation::Class::Directive::Toggle>
and used internally to handle validation of per-validation-event requirements.

=head2 uuid

The uuid directive is provided by L<Validation::Class::Directive::UUID>
and handles validation of Globally/Universally Unique Identifiers.

=head2 validation

The validation directive is provided by L<Validation::Class::Directive::Validation>
and used to execute user-defined validation routines.

=head2 value

The value directive is provided by L<Validation::Class::Directive::value>
and hold the absolute value of the associated field.

=head2 zipcode

The zipcode directive is provided by L<Validation::Class::Directive::Zipcode>
and handles postal-code validation for areas in the USA and North America.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
