package Validator::LIVR::Rules::Conditional;

use strict;
use warnings;

use Validator::LIVR::Rules::Types;

our $VERSION = '2.22';

# LIVR 2.5: rules that depend on other fields. A reference, such as "type" or "address/country",
# is a path from the containing object: the hash that a rule gets as $all_values. That is the
# hash of the validator, of nested_object, list_of_objects and the other metarules for objects.
# Aliases and "or" give the hash of their caller, and list_of, values and keys an empty hash

sub required_if {
    my ($conditions) = @_;

    # Arguments after the object are ignored. The last one is the rule builders
    if ( @_ < 2 || ref($conditions) ne 'HASH' || !%$conditions ) {
        die "Rule [required_if] takes an object of references and values\n";
    }

    # A path and the values as strings, so 1 matches "1" and true matches "true"
    my @entries;
    foreach my $reference ( sort keys %$conditions ) {
        my $path = parse_reference( $reference, 'required_if' );
        my $expected = $conditions->{$reference};

        # An empty list never matches
        die qq{Rule [required_if] takes a primitive value other than "" or a list of them for "$reference"\n}
            if ref($expected) eq 'ARRAY' && !@$expected;

        my %is_expected;
        foreach my $value ( ref($expected) eq 'ARRAY' ? @$expected : $expected ) {
            my $string = _expected_value($value);
            die qq{Rule [required_if] takes a primitive value other than "" or a list of them for "$reference"\n}
                if !defined($string) || $string eq '';

            $is_expected{$string} = 1;
        }

        push @entries, [ $path, \%is_expected ];
    }

    return sub {
        my ( $value, $all_values ) = @_;
        return if defined($value) && $value ne '';

        # Required when every referenced value is a non-empty primitive value from its list
        foreach my $entry (@entries) {
            my $string = _reference_string( $all_values, $entry->[0] );
            return if !defined($string) || !$entry->[1]{$string};
        }

        return 'REQUIRED';
    };
}

sub _expected_value {
    my $value = shift;
    return undef if !defined($value) || ( ref($value) && ref($value) !~ /Boolean/ );
    return ref($value) ? ( $value ? 'true' : 'false' ) : Validator::LIVR::Rules::Types::string_form($value);
}

#   when(reference, condition, rules_if_true, [rules_if_false], rule_builders): the condition form
#   when(reference, cases, rule_builders): the switch form
# Arguments after the 4th are ignored
sub when {
    my @args = @_;
    my $rule_builders = pop @args;

    if ( @args < 2 ) {
        die "Rule [when] takes a reference and cases, or a reference, a condition, rules if true "
            . "and optional rules if false\n";
    }
    splice @args, 4 if @args > 4;

    # A reference is a string: Perl tells a number from a string only by how it was created
    require B if !Validator::LIVR::Rules::Types::HAS_CREATED_AS_NUMBER;
    if ( defined( $args[0] ) && !ref( $args[0] ) && Validator::LIVR::Rules::Types::is_number( $args[0] ) ) {
        die "Rule [when] takes a reference as a non-empty string\n";
    }

    my $path = parse_reference( $args[0], 'when' );
    return _switch( $path, $args[1], $rule_builders ) if @args == 2;

    my ( $condition, $rules_if_true, $rules_if_false ) = _field_rules( $rule_builders, @args[ 1 .. $#args ] );

    return sub {
        my ( $value, $all_values, $output_ref ) = @_;

        # The condition rules see the fields next to the field, their output is discarded
        my $ref_value = resolve_reference( $all_values, $path );
        my $is_true = defined($ref_value) && $ref_value ne ''
            && !$condition->( $ref_value, $all_values, \( my $output = $ref_value ) );

        return _run_branch( $is_true ? $rules_if_true : $rules_if_false, $value, $all_values, $output_ref );
    };
}

sub _switch {
    my ( $path, $cases, $rule_builders ) = @_;

    die "Rule [when] takes an object of values and rules as cases\n" if ref($cases) ne 'HASH';
    die "Rule [when] needs at least one case\n" if !%$cases;

    my @case_values = sort keys %$cases;
    my %case_rules;
    @case_rules{@case_values} = _field_rules( $rule_builders, map { $cases->{$_} } @case_values );

    return sub {
        my ( $value, $all_values, $output_ref ) = @_;

        # An empty or unknown referenced value chooses no case. An empty value passes unchanged
        # (the referenced field reports its own errors), any other value would pass unchecked
        my $string = _reference_string( $all_values, $path );
        my $rules = defined($string) ? $case_rules{$string} : undef;

        if ( !defined $rules ) {
            return if !defined($value) || $value eq '';
            return 'NOT_ALLOWED_VALUE';
        }

        return _run_branch( $rules, $value, $all_values, $output_ref );
    };
}

# The rules of a branch get the value as it is, empty values too, and the fields next to the field
sub _run_branch {
    my ( $rules, $value, $all_values, $output_ref ) = @_;

    # No rules if false: the value passes and stays in the output unchanged
    return if !$rules;

    my $output = $value;
    my $err_code = $rules->( $value, $all_values, \$output );
    return $err_code if $err_code;

    $$output_ref = $output;
    return;
}

# Rule sets in any form that a field takes, each as one rule, from one validator. null and an
# empty list die: they are almost always a mistake, "any" is a rule set without rules
sub _field_rules {
    my ( $rule_builders, @rule_sets ) = @_;

    my %livr;
    foreach my $i ( 0 .. $#rule_sets ) {
        my $rules = $rule_sets[$i];
        Validator::LIVR::Rules::Types::check_rule_set( 'when', $rules );
        $livr{"when$i"} = $rules;
    }

    my $validator = Validator::LIVR->_new_with_rules( \%livr, $rule_builders )->prepare();
    return map { $validator->_field_rule("when$_") } 0 .. $#rule_sets;
}

# The string form of the referenced value when it is a non-empty primitive value, otherwise undef
sub _reference_string {
    my $value = resolve_reference(@_);
    return undef if !defined($value) || $value eq '';

    if ( ref($value) ) {
        return undef if ref($value) !~ /Boolean/;
        return $value ? 'true' : 'false';
    }

    return Validator::LIVR::Rules::Types::string_form($value);
}

# "a/b/0" as [ 'a', 'b', '0' ]. "~1" stands for "/" and "~0" for "~" as in JSON Pointer (RFC 6901).
# Not a string, an empty reference, a leading or trailing "/", an empty segment ("a//b") and a
# wrong escape ("~2", a trailing "~") die. A leading "/" is reserved for references from the root
sub parse_reference {
    my ( $reference, $rule_name ) = @_;

    if ( !defined($reference) || ref($reference) || $reference eq '' ) {
        die "Rule [$rule_name] takes a reference as a non-empty string\n";
    }

    # The common case: a field name
    return [$reference] if index( $reference, '/' ) < 0 && index( $reference, '~' ) < 0;

    if ( substr( $reference, 0, 1 ) eq '/' ) {
        die qq{Rule [$rule_name] got the reference "$reference": a leading "/" is reserved for references from the root\n};
    }

    my @path = split /\//, $reference, -1;

    foreach my $segment (@path) {
        die qq{Rule [$rule_name] got the reference "$reference" with an empty segment\n} if $segment eq '';
        next if index( $segment, '~' ) < 0;

        die qq{Rule [$rule_name] got the reference "$reference" with a wrong escape\n} if $segment =~ /~(?![01])/;

        $segment =~ s/~1/\//g;
        $segment =~ s/~0/~/g;
    }

    return \@path;
}

# The input value at the path, or undef when a segment is missing or a value on the way is not a
# hash (or a list for an index segment: "0" or a number without leading zeros)
sub resolve_reference {
    my ( $value, $path ) = @_;

    foreach my $segment (@$path) {
        my $type = ref($value);

        if ( $type eq 'HASH' ) {
            return undef if !exists $value->{$segment};
            $value = $value->{$segment};
        } elsif ( $type eq 'ARRAY' ) {
            return undef if $segment !~ /\A(?:0|[1-9][0-9]*)\z/ || $segment >= @$value;
            $value = $value->[$segment];
        } else {
            return undef;
        }
    }

    return $value;
}

1;

=head1 NAME

Validator::LIVR::Rules::Conditional - LIVR 2.5 rules of Validator::LIVR that depend on other fields: required_if and when

=head1 DESCRIPTION

This module has the code of these rules, which are documented in
L<Validator::LIVR/LIVR 2.5 rules>. Validator::LIVR loads it when a validator
uses one of the rules.

Each sub is the builder of the rule with the same name.

=cut
