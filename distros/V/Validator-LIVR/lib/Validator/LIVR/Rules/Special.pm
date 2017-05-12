package Validator::LIVR::Rules::Special;

use strict;
use warnings;

use Email::Valid;
use Regexp::Common qw/URI/;
use Time::Piece;

our $VERSION = '2.0';

sub email {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return 'WRONG_EMAIL' unless Email::Valid->address($value);
        return;
    };
}


sub equal_to_field {
    my $field = shift;

    return sub {
        my ( $value, $params ) = @_;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return 'FIELDS_NOT_EQUAL' unless $value eq $params->{$field};
        return;
    };
}


sub url {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        $value =~ s/#[^#]*$//;

        return 'WRONG_URL' unless lc($value) =~ /^$RE{URI}{HTTP}{-scheme => 'https?'}$/;
        return;
    };
}


sub iso_date {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        my $iso_date_re = qr#^
            (?<year>\d{4})-
            (?<month>[0-1][0-9])-
            (?<day>[0-3][0-9])
        $#x;

        if ( $value =~ $iso_date_re ) {
            my $date = eval { Time::Piece->strptime($value, "%Y-%m-%d") };
            return "WRONG_DATE" if !$date || $@;

            if ( $date->year == $+{year} && $date->mon == $+{month} && $date->mday == $+{day} ) {
                return;
            }
        }

        return "WRONG_DATE";
    };
}

1;
