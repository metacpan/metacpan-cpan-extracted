package Validator::LIVR::Rules::Types;

use strict;
use warnings;

our $VERSION = '2.22';

# Perl 5.36 and later tell numbers from strings with builtin::created_as_number
BEGIN { warnings->unimport('experimental::builtin') if $] >= 5.036 }
use constant HAS_CREATED_AS_NUMBER => defined &builtin::created_as_number;

# LIVR 2.5. Rules of this module check their arguments when the validator is built: a wrong
# argument dies, as an unknown rule does. Booleans of JSON decoders are objects, such as
# JSON::PP::Boolean: primitive values with the string form "true" or "false"

# JSON::PP::true and JSON::PP::false, which JSON encoders write as true and false. JSON::PP takes
# milliseconds to load, so without it the objects are made as JSON::PP makes them
my ( $TRUE, $FALSE );

sub _init_booleans {
    require JSON::PP::Boolean;

    no warnings 'once';
    if ( defined $JSON::PP::true ) {
        ( $TRUE, $FALSE ) = ( $JSON::PP::true, $JSON::PP::false );
    } else {
        $TRUE  = bless \( my $true = 1 ),  'JSON::PP::Boolean';
        $FALSE = bless \( my $false = 0 ), 'JSON::PP::Boolean';
    }
}

sub boolean {
    die "Rule [boolean] takes no arguments\n" if @_ > 1;
    _init_booleans() unless $TRUE;

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || $value eq '';

        if ( ref($value) ) {
            return 'FORMAT_ERROR' if ref($value) !~ /Boolean/;
            $$output_ref = $value ? $TRUE : $FALSE;
            return;
        }

        # A number 1.0 is "1", but the string "1.0" is not a boolean
        my $string = string_form($value);
        if ( $string eq '1' || $string eq 'true' ) {
            $$output_ref = $TRUE;
        } elsif ( $string eq '0' || $string eq 'false' ) {
            $$output_ref = $FALSE;
        } else {
            return 'NOT_BOOLEAN';
        }

        return;
    };
}

sub not_one_of {
    my @values = @_;
    pop @values; # rule_builders

    die "Rule [not_one_of] takes one or more values\n" if !@values;

    # By the string forms, so 1 equals "1" and true equals "true"
    my %is_forbidden;
    foreach my $value (@values) {
        my $string = primitive_string($value);
        die "Rule [not_one_of] takes strings, numbers or booleans\n" if !defined $string;

        $is_forbidden{$string} = 1;
    }

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        my $string;
        if ( ref($value) ) {
            return 'FORMAT_ERROR' if ref($value) !~ /Boolean/;
            $string = $value ? 'true' : 'false';
        } else {
            $string = string_form($value);
        }

        return 'NOT_ALLOWED_VALUE' if $is_forbidden{$string};
        return;
    };
}

sub max_decimals {
    # Arguments after the first one are ignored. The last one is the rule builders
    my ($max_decimals) = @_;
    die "Rule [max_decimals] takes a non-negative integer\n" if @_ < 2 || !is_length($max_decimals);
    require B if !HAS_CREATED_AS_NUMBER;

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value);

        if ( ref($value) ) {
            return ref($value) =~ /Boolean/ ? 'NOT_NUMBER' : 'FORMAT_ERROR';
        }

        # Before $value is used as a string: Perl before 5.36 marks a stringified number as a string
        my $is_number = is_number($value);
        return if $value eq '';

        # A number in its string form, so 1e-7 has 7 decimals. A string as it is written: "1e-7"
        # is not a number
        my $string = $is_number ? number_string($value) : $value;
        return 'NOT_NUMBER' unless $string =~ /\A-?[0-9]+(?:\.([0-9]+))?\z/;

        # Trailing zeros do not count: "1.230" has 2 decimals, as the number 1.230
        my $decimals = 0;
        if ( defined $1 ) {
            my $fraction = $1;
            $decimals = length($fraction);
            $decimals-- while $decimals && substr( $fraction, $decimals - 1, 1 ) eq '0';
        }

        return 'TOO_MANY_DECIMALS' if $decimals > $max_decimals;

        # The output is a number: a string too large for a double, such as "1" with 400 zeros,
        # is not one
        my $number = $value + 0;
        return 'NOT_NUMBER' if $number - $number != 0;

        # A number stays as it is: -0 + 0 is 0
        $$output_ref = $is_number ? $value : $number;
        return;
    };
}

sub digits {
    die "Rule [digits] takes no arguments\n" if @_ > 1;

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || $value eq '';

        if ( ref($value) ) {
            return ref($value) =~ /Boolean/ ? 'NOT_DIGITS' : 'FORMAT_ERROR';
        }

        # A string, with the leading zeros: "007" stays "007", 7 becomes "7"
        my $string = string_form($value);
        return 'NOT_DIGITS' unless $string =~ /\A[0-9]+\z/;

        $$output_ref = $string;
        return;
    };
}

sub starts_with {
    my @prefixes = _strings( 'starts_with', @_ );

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || $value eq '';

        my $string;
        if ( ref($value) ) {
            return 'FORMAT_ERROR' if ref($value) !~ /Boolean/;
            $string = $value ? 'true' : 'false';
        } else {
            $string = string_form($value);
        }

        # rindex() from 0 checks only the start
        foreach my $prefix (@prefixes) {
            if ( rindex( $string, $prefix, 0 ) == 0 ) {
                $$output_ref = $string;
                return;
            }
        }

        return 'WRONG_FORMAT';
    };
}

sub ends_with {
    my @suffixes = _strings( 'ends_with', @_ );

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || $value eq '';

        my $string;
        if ( ref($value) ) {
            return 'FORMAT_ERROR' if ref($value) !~ /Boolean/;
            $string = $value ? 'true' : 'false';
        } else {
            $string = string_form($value);
        }

        foreach my $suffix (@suffixes) {
            if ( length($string) >= length($suffix) && substr( $string, -length($suffix) ) eq $suffix ) {
                $$output_ref = $string;
                return;
            }
        }

        return 'WRONG_FORMAT';
    };
}

sub contains {
    my @substrings = _strings( 'contains', @_ );

    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || $value eq '';

        my $string;
        if ( ref($value) ) {
            return 'FORMAT_ERROR' if ref($value) !~ /Boolean/;
            $string = $value ? 'true' : 'false';
        } else {
            $string = string_form($value);
        }

        foreach my $substring (@substrings) {
            if ( index( $string, $substring ) >= 0 ) {
                $$output_ref = $string;
                return;
            }
        }

        return 'WRONG_FORMAT';
    };
}

# Any value passes and stays in the output: objects, lists and empty values too
sub any {
    die "Rule [any] takes no arguments\n" if @_ > 1;
    return sub { return };
}

# The arguments of starts_with, ends_with and contains: one or more non-empty strings. A number
# is its string form
sub _strings {
    my ( $rule_name, @strings ) = @_;
    pop @strings; # rule_builders

    if ( !@strings || grep { !defined($_) || ref($_) || $_ eq '' } @strings ) {
        die "Rule [$rule_name] takes one or more non-empty strings\n";
    }

    return map { string_form($_) } @strings;
}

# Helpers for the other LIVR 2.5 modules

# The string form of a primitive value: "true" or "false" for a boolean, undef for undef,
# an object or a list
sub primitive_string {
    my $value = shift;
    return undef if !defined $value;

    if ( ref($value) ) {
        return undef if ref($value) !~ /Boolean/;
        return $value ? 'true' : 'false';
    }

    return string_form($value);
}

# The string form of a value that is not a reference (LIVR 2.5, section 2.2): a string as it is,
# a number as the shortest decimal that reads back as the same number, without an exponent:
# 1e15 is "1000000000000000", not "1e+15", and 0.1 + 0.2 is "0.30000000000000004", not "0.3".
# Perl before 5.36 cannot tell a number from a string once it is used as a string, so there
# numbers keep the string form of Perl
sub string_form {
    return number_string( $_[0] ) if HAS_CREATED_AS_NUMBER && builtin::created_as_number( $_[0] );

    # The number -0 is "0". Perl writes it as "-0", and JSON::PP 4 decodes -0 as it on Perl 5.10.
    # A string "-0" has no number flags, unless it was used as a number
    my $string = "$_[0]";
    return $string if HAS_CREATED_AS_NUMBER || $string ne '-0';

    require B;
    return B::svref_2object( \$_[0] )->FLAGS & ( B::SVp_IOK() | B::SVp_NOK() ) ? '0' : $string;
}

sub number_string {
    my $number = shift;
    my $string = "$number";
    return '0' if $string eq '-0';

    # Perl writes 15 digits, and an exponent from 1e15 on. Integers below that are exact
    return $string if $string !~ /[.eEnN]/;

    # Compared as a copy: JSON encoders write a string that was used as a number as a number
    foreach my $precision ( 16, 17 ) {
        last if do { my $copy = $string; $copy == $number };
        $string = sprintf "%.${precision}g", $number;
    }

    # 1.5e+20 is "150000000000000000000", 1.5e-07 is "0.00000015"
    if ( $string =~ /\A(-?)([0-9])(?:\.([0-9]+))?e([-+][0-9]+)\z/ ) {
        my ( $sign, $digits, $point ) = ( $1, $2 . ( $3 // '' ), $4 + 1 );

        if ( $point <= 0 ) {
            $string = $sign . '0.' . ( '0' x -$point ) . $digits;
        } elsif ( $point >= length($digits) ) {
            $string = $sign . $digits . ( '0' x ( $point - length($digits) ) );
        } else {
            $string = $sign . substr( $digits, 0, $point ) . '.' . substr( $digits, $point );
        }
    }

    return $string;
}

# A rule set of values, keys or when: a rule name, a hash with a rule or a list of them. null in
# place of rules, an empty list and null or a list in a list of rules die. The validator would
# die on them too, but with an unclear message
sub check_rule_set {
    my ( $rule_name, $rules ) = @_;

    die qq{Rule [$rule_name] got null in place of rules, use "any" for no rules\n} if !defined $rules;
    return if ref($rules) ne 'ARRAY';

    die qq{Rule [$rule_name] got an empty list of rules, use "any" for no rules\n} if !@$rules;

    foreach my $rule (@$rules) {
        die "Rule [$rule_name] got null in a list of rules\n" if !defined $rule;
        next if ref($rule) ne 'ARRAY';

        die "Rule [$rule_name] got " . ( @$rule ? 'a list' : 'an empty list' ) . " inside a list of rules\n";
    }

    return;
}

# A non-negative integer argument, as a length: a number or a string in the grammar of "decimal"
# ("2", "2.0" and "02" are 2; " 2", "1e1" and "0x40" are not numbers). Perl cannot tell "4" from 4
sub is_length {
    my $value = shift;
    return defined($value) && !ref($value) && $value =~ /\A-?[0-9]+(?:\.[0-9]+)?\z/
        && $value == int($value) && $value >= 0;
}

# A number, not a string, as JSON encoders tell them apart: a decoded JSON number, such as 1.5,
# has no string flag, a decoded JSON string has it. Perl before 5.36 sets the flag when a number
# is used as a string, so call it before that. There the caller loads B
sub is_number {
    return builtin::created_as_number( $_[0] ) ? 1 : 0 if HAS_CREATED_AS_NUMBER;

    my $flags = B::svref_2object( \$_[0] )->FLAGS;
    return ( $flags & ( B::SVp_IOK() | B::SVp_NOK() ) ) && !( $flags & B::SVf_POK() ) ? 1 : 0;
}

1;

=head1 NAME

Validator::LIVR::Rules::Types - LIVR 2.5 rules of Validator::LIVR for types and strings: boolean, not_one_of, max_decimals, digits, starts_with, ends_with, contains and any

=head1 DESCRIPTION

This module has the code of these rules, which are documented in
L<Validator::LIVR/LIVR 2.5 rules>. Validator::LIVR loads it when a validator
uses one of the rules.

Each sub is the builder of the rule with the same name. The code is a good
example for L<writing your own rules|Validator::LIVR/WRITING RULES IN PERL>.

=cut
