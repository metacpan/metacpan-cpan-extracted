package Webservice::OVH::Helper;

=encoding utf-8

=head1 NAME

Webservice::OVH::Helper

=head1 DESCRIPTION

Some Helper Methods

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

use DateTime::Format::Strptime;

=head2 construct_filter

Helper method to construct uri parameter

=over

=item * Parameter: key => value

=item * Return: VALUE

=item * Synopsis: Webservice::OVH::Helper->construct_filter();

=back

=cut

sub construct_filter {

    my ( $class, %params ) = @_;

    my @params = keys %params;
    my @values = values %params;
    my $filter = scalar @values ? '?' : "";

    foreach my $param (@params) {

        my $value = $params{$param};
        next unless $value;

        $value = $value eq '_empty_' ? "" : $value;

        if ( $filter ne '?' ) {

            $filter .= '&';
        }

        $filter .= sprintf( "%s=%s", $param, $value );
    }

    return $filter;
}

=head2 construct_filter

Returns a DateTime Object.
Methods uses special pattern to match ovhs DT format.

=over

=item * Parameter: $str_datetime - datetime string, $locale - locale like 'en_EN', $timezone - timezone

=item * Return: DateTime

=item * Synopsis: Webservice::OVH::Helper->parse_datetime("2016-05-15T19:30:23", 'de_DE', 'Europe/Berlin');

=back

=cut

sub parse_datetime {

    my ( $class, $str_datetime, $locale, $timezone ) = @_;

    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%FT%T',
        locale    => ( $locale || 'de_DE' ),
        time_zone => ( $timezone || 'Europe/Berlin' ),
        on_error  => 'croak',
    );

    return $strp->parse_datetime($str_datetime);
}

sub parse_date {

    my ( $class, $str_datetime, $locale, $timezone ) = @_;

    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%F',
        locale    => ( $locale || 'de_DE' ),
        time_zone => ( $timezone || 'Europe/Berlin' ),
        on_error  => 'croak',
    );

    return $strp->parse_datetime($str_datetime);
}

=head2 format_datetime

Returns a date time string fitting ovhs requirements

=over

=item * Parameter: $dt - DateTime object

=item * Return: VALUE

=item * Synopsis: my $dt_str = Webservice::OVH::Helper->format_datetime(DateTime->today());

=back

=cut

sub format_datetime {

    my ( $class, $dt ) = @_;

    return $dt->strftime('%FT%T%z');
}

sub trim {

    my ( $class, $string ) = @_;

    $string =~ s/^\s+|\s+$//g;

    return $string;
}

sub rtrim {

    my ( $class, $string ) = @_;

    $string =~ s/\s+$//;

    return $string;
}

sub ltrim {

    my ( $class, $string ) = @_;

    $string =~ s/^\s+//;

    return $string;
}

1;
