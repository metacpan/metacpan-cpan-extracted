package Value::Object::ValidationUtils;

use warnings;
use strict;

our $VERSION = '0.15';

# RFC 1123 and 2181
sub why_invalid_domain_name
{
    my ($poss_domain) = @_;

    return ( 'No domain supplied', '', undef ) unless defined $poss_domain;
    return ( 'Domain must be between 1 and 255 octets in length.', '', undef )
        if !length $poss_domain or length $poss_domain > 255;
    my @labels = split( /\./, $poss_domain );
    return ( __PACKAGE__ . ': At least one label is required', '', undef ) unless @labels;

    # Final label can be empty
    my $last = length $labels[0] ? $#labels : $#labels-1;
    foreach my $label ( @labels[0 .. $last] )
    {
        my ($why, $long, $data) = why_invalid_domain_label( $label );
        return ($why, $long, $label) if defined $why;
    }
    return;
}

sub is_valid_domain_name
{
    my ($poss_domain) = @_;
    my ($why) = why_invalid_domain_name( $poss_domain );
    return !defined $why;
}

# RFC 1123 and 2181
sub why_invalid_domain_label
{
    my ($poss_label) = @_;
    return ( 'No domain label supplied', '', undef ) unless defined $poss_label;
    return ( 'Label is not in the length range 1 to 63', '', undef )
        if !length $poss_label or length $poss_label > 63;
    return ( 'Label is not the correct form.', '', undef )
        unless $poss_label =~ m{\A[a-zA-Z0-9]        # No hyphens at front
                                  (?:[-a-zA-Z0-9]*   # hyphens allowed in the middle
                                     [a-zA-Z0-9])?   # No hyphens at the end
                             \z}x;
    return;
}

sub is_valid_domain_label
{
    my ($poss_label) = @_;
    my ($why) = why_invalid_domain_label( $poss_label );
    return !defined $why;
}


# RFC 5322
sub why_invalid_email_local_part
{
    my ($poss_part) = @_;
    return ( 'No email local part supplied', '', undef ) unless defined $poss_part;
    return ( 'Local part is not in the length range 1 to 64', '', undef )
        if !length $poss_part or length $poss_part > 64;
    return ( 'Local part is not correct form.', '', undef )
        unless $poss_part =~ m/\A"(?:\\.|[!#-[\]-~])+"\z/   # quoted string (all 7-bit ASCII except \ and " unless quoted)
            || $poss_part =~ m{\A[a-zA-Z0-9!#\$\%&'*+\-/=?^_`{|}~]+       # any 'atext' characters
                                 (?:\.                                    # separated by dots
                                      [a-zA-Z0-9!#\$\%&'*+\-/=?^_`{|}~]+  # any 'atext' characters
                                 )*
                               \z}x;
    return;
}

sub is_valid_email_local_part
{
    my ($poss_part) = @_;
    my ($why) = why_invalid_email_local_part( $poss_part );
    return !defined $why;
}



# RFC 5322
sub why_invalid_common_email_local_part
{
    my ($poss_part) = @_;
    return ( 'No email local part supplied', '', undef ) unless defined $poss_part;
    return ( 'Local part is not in the length range 1 to 64', '', undef )
        if !length $poss_part or length $poss_part > 64;
    return ( 'Local part is not correct form.', '', undef )
        unless $poss_part =~ m{\A[a-zA-Z0-9!#\$\%&'*+\-/=?^_`{|}~]+       # any 'atext' characters
                                 (?:\.                                    # separated by dots
                                      [a-zA-Z0-9!#\$\%&'*+\-/=?^_`{|}~]+  # any 'atext' characters
                                 )*
                               \z}x;
    return;
}

sub is_valid_common_email_local_part
{
    my ($poss_part) = @_;
    my ($why) = why_invalid_common_email_local_part( $poss_part );
    return !defined $why;
}

sub why_invalid_iso_8601_date
{
    my ($value) = @_;
    return ( 'date is undefined', '', undef ) unless defined $value;
    return ( 'date is empty', '', undef ) unless length $value;
    return ( 'date format is incorrect', '', undef )
        unless $value =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/;
    my ($year, $month, $day) = ($1, $2, $3);
    return ( 'value month is out of range', '', $month )
        unless 1 <= $month && $month <= 12;
    return ( 'value day is out of range', '', $day )
        unless 1 <= $day && $day <= 31;
    return ( 'value day is out of range for month', '', $day )
        if $day == 31 && grep { $month == $_ } (2, 4, 6, 9, 11);
    return ( 'value day is out of range for February', '', $day )
        if $day == 30 || ($day == 29 && !_is_leap_year( $year ));
    return;
}

sub _is_leap_year
{
    my ($year) = @_;
    return ($year % 4 == 0 && ($year % 100 != 0 || $year % 400 == 0));
}

sub why_invalid_iso_8601_time
{
    my ($value) = @_;
    return ( 'time is undefined', '', undef ) unless defined $value;
    return ( 'time is empty', '', undef ) unless length $value;
    return ( 'time format is incorrect', '', undef )
        unless $value =~ /\A([0-9]{2}):([0-9]{2})(?::([0-9]{2}(?:\.[0-9]+)?))(Z|[-+][0-9]{2}:[0-9]{2})\z/;
    my ($hour, $minute, $second, $tzi) = ($1, $2, $3, $4);
    return ( 'value hour is out of range', '', $hour )
        unless $hour <= 23 || ($hour == 24 && $minute == 0);
    return ( 'value minute is out of range', '', $minute )
        unless $minute <= 59;
    return ( 'value second is out of range', '', $second )
        unless $second <= 60;  # Account for leap seconds
    return if $tzi eq 'Z';
    my ($tzh, $tzm) = $tzi =~ /(\d+):(\d+)/;
    return ( 'value timezone hour offset is out of range', '', $tzh )
        unless $tzh <= 23 || ($tzh == 24 && $tzm == 0);
    return ( 'value timezone minute offset is out of range', '', $tzm )
        unless $tzm <= 59;
    return;
}

1;
__END__

=head1 NAME

Value::Object::ValidationUtils - Utility functions for validation of value objects

=head1 VERSION

This document describes Value::Object::ValidationUtils version 0.15

=head1 SYNOPSIS

    use Value::Object::ValidationUtils;

    print "Yes\n"
        if Value::Object::ValidationUtils::is_valid_domain_name( $foo );

=head1 DESCRIPTION

Some C<Value::Object>-derived objects share code needed for validation. Rather
than duplicating the knowledge of that information in multiple value objects,
the knowledge and utilities are collected into this module.

=head1 INTERFACE

=head2 why_invalid_domain_name( $str )

Returns a three item list if the supplied C<$str> is not a valid domain name
as specified by RFCs 1123 and 2181. The first item is a short message
describing the problem. The second item is empty and the third may contain a
string with the part of the domain name that is invalid (depending on how it
is invalid).

Returns an empty list if C<$str> is a valid domain name.

=head2 is_valid_domain_name( $str )

Returns true if the supplied C<$str> is a valid domain name as specified by
RFCs 1123 and 2181. Otherwise, return false.

=head2 why_invalid_domain_label( $str )

Returns a three item list if the supplied C<$str> is not a valid domain label
as specified by RFCs 1123 and 2181. The first item is a short message
describing the problem. The second item is empty and the third item is
C<undef>.

Returns an empty list if C<$str> is a valid domain label.

=head2 is_valid_domain_label( $str )

Returns true if the supplied C<$str> is a valid domain label as specified by
RFCs 1123 and 2181. Otherwise, return false.

=head2 why_invalid_email_local_part( $str )

Returns a three item list if the supplied C<$str> is not a valid email local
part as specified by RFC 5322. The first item is a short message describing
the problem. The second item is empty and the third item is C<undef>.

Returns an empty list if C<$str> is a valid email local part.

=head2 is_valid_email_local_part( $str )

Returns true if the supplied C<$str> is a valid email address as specified by
RFC 5322. Otherwise, return false.

=head2 why_invalid_common_email_local_part( $str )

Returns a three item list if the supplied C<$str> is not a valid email local
part mostly as specified by RFC 5322. The difference between the common version
of the email local part and the standard is that the common version does not
support the quoted form. This does seem to match the common usage of email
addresses that I've seem.

The first item is a short message describing the problem. The second item is
empty and the third item is C<undef>.

Returns an empty list if C<$str> is a valid common email local part.

=head2 is_valid_common_email_local_part( $str )

Returns true if the supplied C<$str> is a valid email address as specified by
common email address as defined by C<why_invalid_common_email_local_part>.
Otherwise, return false.

=head2 why_invalid_iso_8601_date( $str )

Returns a three item list if the supplied C<$str> is not a valid date as specified
by the W3C Date/Time format which conforms to ISO 8601 (YYYY-MM-DD).

The first item is a short message describing the problem. The second item is
empty and the third item is data relating to the failure.

Returns an empty list if C<$str> is a valid ISO 8601 date.

=head2 why_invalid_iso_8601_time( $str )

Returns a three item list if the supplied C<$str> is not a valid time as specified
by the W3C Date/Time format which conforms to ISO 8601 (HH:MM:SS(.SSS)?(Z|[+-]HH:MM)).

The first item is a short message describing the problem. The second item is
empty and the third item is data relating to the failure.

Returns an empty list if C<$str> is a valid ISO 8601 Time.

=head1 CONFIGURATION AND ENVIRONMENT

C<Value::Object::ValidationUtils> requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-value-object@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

G. Wade Johnson  C<< gwadej@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, G. Wade Johnson C<< gwadej@cpan.org >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

