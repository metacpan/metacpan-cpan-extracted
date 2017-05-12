package Validator::LIVR::Rules::Numeric;

use strict;
use warnings;

use Scalar::Util qw/looks_like_number/;

our $VERSION = '2.0';

sub integer {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);
        return 'NOT_INTEGER' unless looks_like_number($value);

        return 'NOT_INTEGER' unless $value =~ /^\-?\d+$/ && looks_like_number($value);
        return;
    };
}


sub positive_integer {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);
        return 'NOT_POSITIVE_INTEGER' unless looks_like_number($value);

        return 'NOT_POSITIVE_INTEGER' unless $value =~ /^\d+$/
                                      && looks_like_number($value)
                                      && $value > 0;
        return;
    };
}


sub decimal {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);
        return 'NOT_DECIMAL' unless looks_like_number($value);

        return 'NOT_DECIMAL' unless $value =~ /^\-?[\d.]+$/
                             && looks_like_number($value);

        return;
    };
}


sub positive_decimal {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);
        return 'NOT_POSITIVE_DECIMAL' unless looks_like_number($value);


        return 'NOT_POSITIVE_DECIMAL' unless $value =~ /^\-?[\d.]+$/
                                      && looks_like_number($value)
                                      && $value > 0;

        return;
    };
}


sub max_number {
    my $max_number = shift;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);
        return 'NOT_NUMBER' unless looks_like_number($value);

        return 'TOO_HIGH' if $value > $max_number;
        return;
    };
}


sub min_number {
    my $min_number = shift;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);
        return 'NOT_NUMBER' unless looks_like_number($value);

        return 'TOO_LOW' if $value < $min_number;
        return;
    };
}


sub number_between {
    my ($min_number, $max_number) = @_;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);
        return 'NOT_NUMBER' unless looks_like_number($value);

        return 'TOO_LOW' if $value < $min_number;
        return 'TOO_HIGH' if $value > $max_number;
        return;
    };
}

1;
