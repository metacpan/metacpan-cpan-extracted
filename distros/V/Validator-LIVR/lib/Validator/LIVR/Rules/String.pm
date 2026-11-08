package Validator::LIVR::Rules::String;

use strict;
use warnings;

our $VERSION = '2.21';

sub one_of {
    my $allowed_values;
    if (ref $_[0] eq 'ARRAY') {
        $allowed_values = $_[0];
    } else {
        $allowed_values = [@_];
        pop @$allowed_values; # pop rule_builders
    }

    # LIVR 2.5: booleans are compared as strings, true equals "true"
    my @allowed_strings = map { _boolean_string($_) } @$allowed_values;
    my $has_boolean = grep { _is_boolean($_) } @$allowed_values;

    # The 2.0 form: Perl strings, where a boolean is "1" or "0". Of copies: before Perl 5.36,
    # a number used as a string is a string for JSON encoders, and the output is the number
    my @perl_strings = map { my $copy = $_; defined($copy) ? "$copy" : '' } @$allowed_values;

    return sub {
        my ($value, undef, $output_ref) = @_;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value) && ref($value) !~ 'Boolean';

        my $string = ref($value) ? ( $value ? 'true' : 'false' ) : $value;
        for my $i ( 0 .. $#allowed_strings ) {
            if ( $string eq $allowed_strings[$i] ) {
                $$output_ref = $allowed_values->[$i];
                return;
            }
        }

        # As in 2.0, where a boolean is "1" or "0" as a Perl string: "1" passes [true],
        # and true passes ["1"] and [1]
        if ( $has_boolean || ref($value) ) {
            for my $i ( 0 .. $#perl_strings ) {
                if ( $value eq $perl_strings[$i] ) {
                    $$output_ref = $allowed_values->[$i];
                    return;
                }
            }
        }

        return 'NOT_ALLOWED_VALUE';
    }
}


sub max_length {
    my $max_length = shift;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return 'TOO_LONG' if length($value) > $max_length;
        return;
    };
}


sub min_length {
    my $min_length = shift;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return 'TOO_SHORT' if length($value) < $min_length;
        return;
    };
}


sub length_equal {
    my $length = shift;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return 'TOO_SHORT' if length($value) < $length;
        return 'TOO_LONG' if length($value) > $length;
        return;
    };
}


sub length_between {
    my ($min_length, $max_length) = @_;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return 'TOO_SHORT' if length($value) < $min_length;
        return 'TOO_LONG' if length($value) > $max_length;
        return;
    };
}


sub like {
    my ($re, $flags) = @_;

    my $is_ignore_case = @_ >= 3 && index( $flags, 'i') >= 0;
    $re = _dollar_end_only($re);
    $re = $is_ignore_case ? qr/$re/i : qr/$re/;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return 'WRONG_FORMAT' unless $value =~  m/$re/;
        return;
    };
}


# In LIVR "$" at the end of a pattern matches only at the end of the value, the
# way RFC 9485 (I-Regexp) maps a pattern to PCRE ("\z"). In Perl it also matches
# before a trailing newline, so "12345\n" would match "^[0-9]{5}$". Replaces "$"
# outside character classes with "\z".
sub _dollar_end_only {
    my $re = shift;

    $re =~ s{
        ( \\.                                               # an escaped character
        | \[ \^? \]? (?: \[:[^\]]*:\] | \\. | [^\]] )* \]   # a character class
        )
        | \$
    }{ defined $1 ? $1 : '\z' }gesx;

    return $re;
}


sub string {
    return sub {
        my $value = shift;

        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);
        return;
    };
}


sub equal {
    my $allowed_value = shift;
    my $allowed_string = _boolean_string($allowed_value);
    my $is_boolean = _is_boolean($allowed_value);

    return sub {
        my ($value, undef, $output_ref) = @_;
        return if !defined($value) || $value eq '';

        # LIVR 2.5: a boolean is compared as a string, so ["boolean", { eq => JSON::PP::true }]
        # accepts true and "true"
        my $string = $value;
        if ( ref($value) ) {
            return 'FORMAT_ERROR' if ref($value) !~ /Boolean/;
            $string = $value ? 'true' : 'false';
        }

        # The output is the value of the rule, as in one_of: { eq => 2 } outputs 2 for "2".
        # As in 2.0, where true is "1" as a Perl string, "1" passes { eq => JSON::PP::true }
        if ( $string eq $allowed_string || $is_boolean && !ref($value) && $value eq $allowed_value ) {
            $$output_ref = $allowed_value;
            return;
        }

        return 'NOT_ALLOWED_VALUE';
    };
}

# A boolean of a JSON decoder as "true" or "false", any other value as it is
sub _boolean_string {
    my $value = shift;
    return _is_boolean($value) ? ( $value ? 'true' : 'false' ) : $value;
}

sub _is_boolean { ref( $_[0] ) && ref( $_[0] ) =~ /Boolean/ }

1;

=head1 NAME

Validator::LIVR::Rules::String - String rules of Validator::LIVR: string, eq, one_of, min_length, max_length, length_equal, length_between and like

=head1 DESCRIPTION

This module has the code of the string rules, which are documented in
L<Validator::LIVR/String rules>.

Each sub is the builder of the rule with the same name. The builder of C<eq>
is C<equal>. The code is a good example for L<writing your own
rules|Validator::LIVR/WRITING RULES IN PERL>.

=cut
