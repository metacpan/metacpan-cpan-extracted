package Validator::LIVR::Rules::Meta;

use strict;
use warnings;

our $VERSION = '2.21';

# The fields next to an item of list_of: none. Items have no containing object, so
# equal_to_field and the references of required_if and when see a missing value there
my $NO_FIELDS = {};

# Arguments after the ones a rule takes are ignored: the rule builders are always the last one

sub nested_object {
    my ( $livr, $rule_builders ) = ( $_[0], $_[-1] );

    my $validator = Validator::LIVR->_new_with_rules( $livr, $rule_builders )->prepare();

    return sub {
        my ( $nested_object, $params, $output_ref ) = @_;
        return if !defined($nested_object) || $nested_object eq '';

        return 'FORMAT_ERROR' unless ref($nested_object) eq 'HASH';

        my $result = $validator->validate( $nested_object );

        if ( $result ) {
            $$output_ref = $result;
            return;
        } else {
            return $validator->get_errors();
        }
    }
}


sub list_of {
    my ( $rules, $rule_builders );

    if (ref $_[0] eq 'ARRAY') {
        ( $rules, $rule_builders ) = ( $_[0], $_[-1] );
    } else {
        $rules = [@_];
        $rule_builders = pop @$rules;
    }

    my $item_rule = Validator::LIVR->_new_with_rules( { field => $rules }, $rule_builders )->_field_rule('field');

    return sub {
        my ( $values, $params, $output_ref ) = @_;
        return if !defined($values) || $values eq '';

        return 'FORMAT_ERROR' unless ref($values) eq 'ARRAY';

        my ( @results, @errors, $has_errors );

        foreach my $val (@$values) {
            my $output = $val;

            if ( my $err_code = $item_rule->( $val, $NO_FIELDS, \$output ) ) {
                push @errors, $err_code;
                push @results, undef;
                $has_errors = 1;
            } else {
                push @results, $output;
                push @errors, undef;
            }
        }

        if ( $has_errors ) {
            return \@errors;
        } else {
            $$output_ref = \@results;
            return;
        }
    }
}


sub list_of_objects {
    my ( $livr, $rule_builders ) = ( $_[0], $_[-1] );

    my $validator = Validator::LIVR->_new_with_rules( $livr, $rule_builders )->prepare();

    return sub {
        my ( $objects, $params, $output_ref ) = @_;
        return if !defined($objects) || $objects eq '';

        return 'FORMAT_ERROR' unless ref($objects) eq 'ARRAY';

        my ( @results, @errors );

        foreach my $obj (@$objects) {
            if ( my $result = $validator->validate($obj) ) {
                push @results, $result;
                push @errors, undef;
            } else {
                push @errors, $validator->get_errors();
                push @results, undef;
            }
        }

        if ( grep {$_} @errors ) {
            return \@errors;
        } else {
            $$output_ref = \@results;
            return;
        }
    }
}

sub list_of_different_objects {
    my ( $selector_field, $livrs, $rule_builders ) = ( @_[ 0, 1 ], $_[-1] );

    my %validators;
    foreach my $selector_value ( keys %$livrs ) {
        my $validator = Validator::LIVR->_new_with_rules( $livrs->{$selector_value}, $rule_builders )->prepare();

        $validators{$selector_value} = $validator;
    }


    return sub {
        my ( $objects, $params, $output_ref ) = @_;
        return if !defined($objects) || $objects eq '';

        return 'FORMAT_ERROR' unless ref($objects) eq 'ARRAY';

        my ( @results, @errors );

        foreach my $obj (@$objects) {
            if ( ref($obj) ne 'HASH' || !$obj->{$selector_field} || !$validators{$obj->{$selector_field}} ) {
                push @errors, 'FORMAT_ERROR';
                next;
            }

            my $validator = $validators{ $obj->{$selector_field} };

            if ( my $result = $validator->validate($obj) ) {
                push @results, $result;
                push @errors, undef;
            } else {
                push @errors, $validator->get_errors();
            }
        }

        if ( grep {$_} @errors ) {
            return \@errors;
        } else {
            $$output_ref = \@results;
            return;
        }
    }
}



sub variable_object {
    my ( $selector_field, $livrs, $rule_builders ) = ( @_[ 0, 1 ], $_[-1] );

    my %validators;
    foreach my $selector_value ( keys %$livrs ) {
        my $validator = Validator::LIVR->_new_with_rules( $livrs->{$selector_value}, $rule_builders )->prepare();

        $validators{$selector_value} = $validator;
    }


    return sub {
        my ( $object, $params, $output_ref ) = @_;
        return if !defined($object) || $object eq '';


        if ( ref($object) ne 'HASH' || !$object->{$selector_field} || !$validators{$object->{$selector_field}} ) {
            return 'FORMAT_ERROR';
        }

        my $validator = $validators{ $object->{$selector_field} };

        if ( my $result = $validator->validate($object) ) {
            $$output_ref = $result;
            return;
        } else {
            return $validator->get_errors();
        }
    }
}


sub livr_or { # we call it livr_or to avoid conflicts with the "or" operator
    my @rule_sets = @_;
    my $rule_builders = pop @rule_sets;

    # One validator for all rule sets, a field for each
    my %livr = map { ( "or$_" => $rule_sets[$_] ) } 0 .. $#rule_sets;
    my $validator = Validator::LIVR->_new_with_rules( \%livr, $rule_builders )->prepare();
    my @field_rules = map { $validator->_field_rule("or$_") } 0 .. $#rule_sets;

    return sub {
        my ($value, $params, $output_ref) = @_;

        # Empty values go to the rule sets too, so "required" and "not_empty" in them work.
        # The rule sets are transparent: their rules see the fields next to the field
        my $last_error;

        for my $field_rule (@field_rules) {
            my $output = $value;
            my $err_code = $field_rule->( $value, $params, \$output );

            if ( !$err_code ) {
                $$output_ref = $output;
                return;
            }

            $last_error = $err_code;
        }

        return $last_error;
    }
}

1;

=head1 NAME

Validator::LIVR::Rules::Meta - Metarules of Validator::LIVR: nested_object, list_of, list_of_objects, variable_object, list_of_different_objects and or

=head1 DESCRIPTION

This module has the code of the metarules, which are documented in
L<Validator::LIVR/Metarules>.

Each sub is the builder of the rule with the same name. The builder of C<or>
is C<livr_or>, as C<or> is a Perl operator. The code is a good example for
L<writing your own rules|Validator::LIVR/WRITING RULES IN PERL>.

=cut
