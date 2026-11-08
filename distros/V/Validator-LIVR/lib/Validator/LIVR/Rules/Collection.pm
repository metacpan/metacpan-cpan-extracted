package Validator::LIVR::Rules::Collection;

use strict;
use warnings;

use Validator::LIVR::Rules::Types;

our $VERSION = '2.21';

# LIVR 2.5: rules for hashes and lists. The builders of values, keys and split are livr_values,
# livr_keys and livr_split, as Perl has functions with these names

# The fields next to a value of "values" or a key of "keys": none. They have no containing
# object, so equal_to_field and the references of required_if and when see a missing value there
my $NO_FIELDS = {};

sub livr_values {
    my ( $rules, $rule_builders ) = _rules_argument( 'values', @_ );
    my $value_rule = Validator::LIVR->_new_with_rules( { field => $rules }, $rule_builders )->_field_rule('field');

    return sub {
        my ( $object, undef, $output_ref ) = @_;
        return if !defined($object) || $object eq '';
        return 'FORMAT_ERROR' if ref($object) ne 'HASH';

        my ( %result, %errors );

        foreach my $key ( keys %$object ) {
            my $value = $object->{$key};
            my $output = $value;

            if ( my $err_code = $value_rule->( $value, $NO_FIELDS, \$output ) ) {
                $errors{$key} = $err_code;
            } else {
                $result{$key} = $output;
            }
        }

        return \%errors if %errors;

        $$output_ref = \%result;
        return;
    };
}

sub livr_keys {
    my ( $rules, $rule_builders ) = _rules_argument( 'keys', @_ );

    # Keys are checked as they are, without auto trim
    my $key_rule = Validator::LIVR->_new_with_rules( { field => $rules }, $rule_builders, 0 )->_field_rule('field');

    return sub {
        my $object = shift;
        return if !defined($object) || $object eq '';
        return 'FORMAT_ERROR' if ref($object) ne 'HASH';

        # The rules only check: their output is ignored and the hash stays unchanged
        my %errors;
        foreach my $key ( keys %$object ) {
            my $output = $key;
            $errors{$key} = 'WRONG_KEY' if $key_rule->( $key, $NO_FIELDS, \$output );
        }

        return \%errors if %errors;
        return;
    };
}

# The arguments of values and keys are the same as in list_of: values('string'),
# values('required', 'string') or values(['required', 'string'])
sub _rules_argument {
    my ( $rule_name, @args ) = @_;
    my $rule_builders = pop @args;

    my $rules = @args == 1 && ref( $args[0] ) eq 'ARRAY' ? $args[0] : \@args;
    die "Rule [$rule_name] needs rules\n" if !@$rules;

    # { values => undef }: null in place of rules, not in a list of rules
    Validator::LIVR::Rules::Types::check_rule_set( $rule_name, @args == 1 && !defined( $args[0] ) ? undef : $rules );

    return ( $rules, $rule_builders );
}

#   list_length($length), list_length($min, $max), list_length({ min => $min, max => $max })
sub list_length {
    my @args = @_;
    pop @args; # rule_builders

    my ( $min, $max );

    # Arguments after the options object, or after "max", are ignored
    if ( @args && ref( $args[0] ) eq 'HASH' ) {
        my $options = $args[0];

        foreach my $name ( sort keys %$options ) {
            die qq{Rule [list_length] got an unknown option "$name"\n} if $name ne 'min' && $name ne 'max';
        }

        die qq{Rule [list_length] takes "min", "max" or both\n} if !%$options;

        ( $min, $max ) = ( $options->{min} // 0, $options->{max} );
        if ( ( exists $options->{min} && !_is_length( $options->{min} ) )
            || ( exists $options->{max} && !_is_length( $options->{max} ) ) )
        {
            die qq{Rule [list_length] takes non-negative integers as "min" and "max"\n};
        }
    } elsif ( @args == 1 && _is_length( $args[0] ) ) {
        $min = $max = $args[0];
    } elsif ( @args >= 2 && _is_length( $args[0] ) && _is_length( $args[1] ) ) {
        ( $min, $max ) = @args;
    } else {
        die qq{Rule [list_length] takes a length, a minimum and a maximum, or an object with "min" and "max"\n};
    }

    die qq{Rule [list_length] got "min" greater than "max"\n} if defined($max) && $min > $max;

    return sub {
        my $list = shift;

        # An empty list is a value: { min => 1 } rejects it
        return if !defined($list) || $list eq '';
        return 'FORMAT_ERROR' if ref($list) ne 'ARRAY';

        return 'TOO_FEW_ITEMS'  if @$list < $min;
        return 'TOO_MANY_ITEMS' if defined($max) && @$list > $max;
        return;
    };
}

sub _is_length { Validator::LIVR::Rules::Types::is_length(@_) }

#   unique(): primitive items, unique(@keys): hashes with unique values of the keys
sub unique {
    my @keys = @_;
    pop @keys; # rule_builders

    die "Rule [unique] takes key names as strings\n" if grep { !defined($_) || ref($_) } @keys;

    # Items are compared by their string forms, so 1 and "1" are duplicates. A wrong item
    # is FORMAT_ERROR, wherever it is in the list
    if ( !@keys ) {
        return sub {
            my $list = shift;
            return if !defined($list) || $list eq '';
            return 'FORMAT_ERROR' if ref($list) ne 'ARRAY';

            my ( %is_seen, $has_duplicates );

            foreach my $item (@$list) {
                next if !defined($item) || $item eq '';

                my $string;
                if ( ref($item) ) {
                    return 'FORMAT_ERROR' if ref($item) !~ /Boolean/;
                    $string = $item ? 'true' : 'false';
                } else {
                    $string = Validator::LIVR::Rules::Types::string_form($item);
                }

                $has_duplicates = 1 if $is_seen{$string}++;
            }

            return 'NOT_UNIQUE_ITEMS' if $has_duplicates;
            return;
        };
    }

    return sub {
        my $list = shift;
        return if !defined($list) || $list eq '';
        return 'FORMAT_ERROR' if ref($list) ne 'ARRAY';

        my ( %is_seen, $has_duplicates );

        ITEM: foreach my $item (@$list) {
            next if !defined($item) || $item eq '';
            return 'FORMAT_ERROR' if ref($item) ne 'HASH';

            # An item with an empty key value is not compared, a key value of a wrong type is an error.
            # The string forms with their lengths, so ["a,b"] and ["a", "b"] differ
            my ( $id, $has_empty_value ) = ('');

            foreach my $key (@keys) {
                my $value = $item->{$key};

                if ( !defined($value) || $value eq '' ) {
                    $has_empty_value = 1;
                    next;
                }

                my $string;
                if ( ref($value) ) {
                    return 'FORMAT_ERROR' if ref($value) !~ /Boolean/;
                    $string = $value ? 'true' : 'false';
                } else {
                    $string = Validator::LIVR::Rules::Types::string_form($value);
                }

                $id .= length($string) . ':' . $string;
            }

            next ITEM if $has_empty_value;
            $has_duplicates = 1 if $is_seen{$id}++;
        }

        return 'NOT_UNIQUE_ITEMS' if $has_duplicates;
        return;
    };
}

sub livr_split {
    my ($separator) = @_;

    # Arguments after the separator are ignored. The last one is the rule builders
    if ( @_ < 2 || !defined($separator) || ref($separator) || $separator eq '' ) {
        die "Rule [split] takes a non-empty separator string\n";
    }

    # A number is its string form
    $separator = Validator::LIVR::Rules::Types::string_form($separator);
    my $separator_re = qr/\Q$separator\E/;

    # A modifier: lists, empty values and hashes stay as they are, the next rule reports them.
    # Numbers and booleans are split in their string form, like strings
    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value);

        my $string;
        if ( ref($value) ) {
            return if ref($value) !~ /Boolean/;
            $string = $value ? 'true' : 'false';
        } else {
            return if $value eq '';
            $string = Validator::LIVR::Rules::Types::string_form($value);
        }

        # At every separator, empty parts are kept: "a,,b" is [ "a", "", "b" ]
        $$output_ref = index( $string, $separator ) < 0 ? [$string] : [ split $separator_re, $string, -1 ];
        return;
    };
}

1;

=head1 NAME

Validator::LIVR::Rules::Collection - LIVR 2.5 rules of Validator::LIVR for hashes and lists: values, keys, list_length, unique and split

=head1 DESCRIPTION

This module has the code of these rules, which are documented in
L<Validator::LIVR/LIVR 2.5 rules>. Validator::LIVR loads it when a validator
uses one of the rules.

Each sub is the builder of the rule with the same name. The builders of
C<values>, C<keys> and C<split> are C<livr_values>, C<livr_keys> and
C<livr_split>, as Perl has functions with these names.

=cut
