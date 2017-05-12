package Zodiac::Tiny;

our $DATE = '2015-11-28'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
#use strict;
#use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       zodiac_of
               );

sub zodiac_of {
    my $date = shift;

    my ($m, $d);
    if (my $ref = ref($date)) {
        if ($ref eq 'DateTime' || $ref eq 'Time::Moment') {
            $m = $date->month;
            $d = $date->day_of_month;
        } else {
            die "Invalid date object, only DateTime and Time::Moment ".
                "currently supported";
        }
    } else {
        ($m, $d) = $date =~ /\A(?:\d\d\d\d-)?(\d\d)-(\d\d)\z/
            or die "Invalid date string, please use YYYY-MM-DD";
    }

    if ($m == 1) {
        return $d <= 19 ? "capricornus" : "aquarius";
    } elsif ($m == 2) {
        return $d <= 18 ? "aquarius" : "pisces";
    } elsif ($m == 3) {
        return $d <= 20 ? "pisces" : "aries";
    } elsif ($m == 4) {
        return $d <= 19 ? "aries" : "taurus";
    } elsif ($m == 5) {
        return $d <= 20 ? "taurus" : "gemini";
    } elsif ($m == 6) {
        return $d <= 20 ? "gemini" : "cancer";
    } elsif ($m == 7) {
        return $d <= 22 ? "cancer" : "leo";
    } elsif ($m == 8) {
        return $d <= 22 ? "leo" : "virgo";
    } elsif ($m == 9) {
        return $d <= 22 ? "virgo" : "libra";
    } elsif ($m == 10) {
        return $d <= 22 ? "libra" : "scorpius";
    } elsif ($m == 11) {
        return $d <= 21 ? "scorpius" : "sagittarius";
    } else {
        return $d <= 21 ? "sagittarius" : "capricornus";
    }
}

1;
# ABSTRACT: Look up zodiac sign for a given date

__END__

=pod

=encoding UTF-8

=head1 NAME

Zodiac::Tiny - Look up zodiac sign for a given date

=head1 VERSION

This document describes version 0.01 of Zodiac::Tiny (from Perl distribution Zodiac-Tiny), released on 2015-11-28.

=head1 DESCRIPTION

This module is a lightweight alternative to L<DateTime::Event::Zodiac>.

=head1 FUNCTIONS

=head2 zodiac_of($date) => str

Return zodiac sign for a date, which can be a string in the format of
C<"YYYY-MM-DD"> or C<"MM-DD">, or a L<DateTime> or L<Time::Moment> object.

=head1 SEE ALSO

This module is a lightweight alternative to L<DateTime::Event::Zodiac>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Zodiac-Tiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Zodiac-Tiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Zodiac-Tiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
