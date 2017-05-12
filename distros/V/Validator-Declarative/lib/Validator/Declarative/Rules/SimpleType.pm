#!/usr/bin/env perl
use strict;
use warnings;

package Validator::Declarative::Rules::SimpleType;
{
  $Validator::Declarative::Rules::SimpleType::VERSION = '1.20130722.2105';
}

# ABSTRACT: Declarative parameters validation - default simple types rules

use Error qw/ :try /;
use Email::Valid;

#
# INTERNALS
#
sub _validate_bool {
    my ($input) = @_;
    throw Error::Simple('does not satisfy BOOL')
        if ref($input) || $input !~ m/^(1|true|t|yes|y|0|false|f|no|n|)$/i;
}

sub _validate_float {
    my ($input) = @_;
    throw Error::Simple('does not satisfy FLOAT')
        if ref($input) || $input !~ m/^[+-]?\d+(:?\.\d*)?$/;
}

sub _validate_int {
    my ($input) = @_;
    throw Error::Simple('does not satisfy INT')
        if ref($input) || $input !~ m/^[+-]?\d+$/;
}

sub _validate_positive {
    my ($input) = @_;
    no warnings;
    throw Error::Simple('does not satisfy POSITIVE')
        if ref($input) || $input <= 0;
}

sub _validate_negative {
    my ($input) = @_;
    no warnings;
    throw Error::Simple('does not satisfy NEGATIVE')
        if ref($input) || $input >= 0;
}

sub _validate_id {
    my ($input) = @_;
    try {
        _validate_int($input);
        _validate_positive($input);
    }
    catch Error with {
        throw Error::Simple('does not satisfy ID');
    };
}

sub _validate_email {
    my ($input) = @_;
    throw Error::Simple('does not satisfy EMAIL')
        if ref($input) || !Email::Valid->address($input);
}

sub _validate_year {
    my ($input) = @_;
    try {
        _validate_int($input);
        no warnings;
        die('bad') if ref($input) || $input < 1970 || $input > 3000;
    }
    catch Error with {
        throw Error::Simple('does not satisfy YEAR');
    };
}

sub _validate_week {
    my ($input) = @_;
    try {
        _validate_int($input);
        no warnings;
        die('bad') if ref($input) || $input < 1 || $input > 53;
    }
    catch Error with {
        throw Error::Simple('does not satisfy WEEK');
    };
}

sub _validate_month {
    my ($input) = @_;
    try {
        _validate_int($input);
        no warnings;
        die('bad') if ref($input) || $input < 1 || $input > 12;
    }
    catch Error with {
        throw Error::Simple('does not satisfy MONTH');
    };
}

sub _validate_day {
    my ($input) = @_;
    try {
        _validate_int($input);
        no warnings;
        die('bad') if ref($input) || $input < 1 || $input > 31;
    }
    catch Error with {
        throw Error::Simple('does not satisfy DAY');
    };
}

sub _validate_ymd {
    my ($input) = @_;
    no warnings;
    throw Error::Simple('does not satisfy YMD')
        if ref($input)
        || $input !~ m/^(\d{4})-(\d{2})-(\d{2})$/
        || $1 < 1970
        || $1 > 3000
        || $2 < 1
        || $2 > 12
        || $3 < 1
        || $3 > 31;
}

sub _validate_mdy {
    my ($input) = @_;
    no warnings;
    throw Error::Simple('does not satisfy MDY')
        if ref($input)
        || $input !~ m|^(\d\d?)/(\d\d?)/(\d\d(?:\d\d)?)$|
        || $1 < 1
        || $1 > 12
        || $2 < 1
        || $2 > 31
        || !( $3 > 0 && $3 < 100 || $3 >= 1970 && $3 <= 3000 );
}

sub _validate_time {
    my ($input) = @_;
    no warnings;
    throw Error::Simple('does not satisfy TIME')
        if ref($input) || $input !~ m/^(\d\d):(\d\d):(\d\d)$/ || $1 > 23 || $2 > 59 || $3 > 59;
}

sub _validate_hhmm {
    my ($input) = @_;
    no warnings;
    throw Error::Simple('does not satisfy HHMM')
        if ref($input) || $input !~ m/^(\d\d):(\d\d)$/ || $1 > 23 || $2 > 59;
}

sub _validate_timestamp {
    my ($input) = @_;
    ## almost same as float, but can't have sign
    ## we can't use _validate_float && _validate_positive because input can be zero
    no warnings;
    throw Error::Simple('does not satisfy TIMESTAMP')
        if ref($input) || $input !~ m/^\d+(:?\.\d*)?$/;
}

sub _register_default_simple_types {
    require Validator::Declarative;
    Validator::Declarative::register_type(
        ## generic types
        bool     => \&_validate_bool,
        float    => \&_validate_float,
        int      => \&_validate_int,
        integer  => \&_validate_int,
        positive => \&_validate_positive,
        negative => \&_validate_negative,
        id       => \&_validate_id,
        email    => \&_validate_email,
        ## datetime-like types
        year      => \&_validate_year,
        week      => \&_validate_week,
        month     => \&_validate_month,
        day       => \&_validate_day,
        ymd       => \&_validate_ymd,
        mdy       => \&_validate_mdy,
        time      => \&_validate_time,
        hhmm      => \&_validate_hhmm,
        timestamp => \&_validate_timestamp,
        msec      => \&_validate_timestamp,
    );
}

_register_default_simple_types();


1;    # End of Validator::Declarative::Rules::SimpleType


__END__
=pod

=head1 NAME

Validator::Declarative::Rules::SimpleType - Declarative parameters validation - default simple types rules

=head1 VERSION

version 1.20130722.2105

=head1 DESCRIPTION

Internally used by Validator::Declarative.

=head1 METHODS

There is no public methods.

=head1 SEE ALSO

L<Validator::Declarative>

=head1 AUTHOR

Oleg Kostyuk, C<< <cub at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/cub-uanic/Validator-Declarative>

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Oleg Kostyuk.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

