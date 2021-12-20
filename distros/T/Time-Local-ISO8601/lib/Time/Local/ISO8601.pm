package Time::Local::ISO8601;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-25'; # DATE
our $DIST = 'Time-Local-ISO8601'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       timelocal_from_ymd
                       timegm_from_ymd
               );
# TODO: timelocal_from_iso8601
# TODO: timegm_from_iso8601
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub _parse_args {
    my ($y, $m, $d);
    if (@_ == 1) {
        ($y, $m, $d) = $_[0] =~ /\A([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})\z/
            or die "Invalid ymd string '$_[0]', please use YYYY-MM-DD format";
    } elsif (@_ == 3) {
        ($y, $m, $d) = @_;
    } else {
        die "Please specify ymd as a single argument string or 3-argument (y,m,d)";
    }
    ($y, $m, $d);
}

sub timelocal_from_ymd {
    my ($y, $m, $d) = _parse_args(@_);
    require Time::Local;
    Time::Local::timelocal_modern(0, 0, 0, $d, $m-1, $y);
}

sub timegm_from_ymd {
    my ($y, $m, $d) = _parse_arg(@_);
    require Time::Local;
    Time::Local::timegm_modern(0, 0, 0, $d, $m-1, $y);
}

1;
# ABSTRACT: Compute time (Unix epoch) from YMD/ISO8601 sting

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Local::ISO8601 - Compute time (Unix epoch) from YMD/ISO8601 sting

=head1 VERSION

This document describes version 0.001 of Time::Local::ISO8601 (from Perl distribution Time-Local-ISO8601), released on 2021-06-25.

=head1 SYNOPSIS

 use Time::Local::ISO8601 qw(
     timelocal_from_ymd
     timegm_from_ymd
 );
 # you can import all using :all tag

 # either supply a "YYYY-MM-DD" string
 my $epoch = timelocal_from_ymd("2021-06-25");
 my $epoch = timegm_from_ymd   ("2021-6-25");

 # or separate year, mon, day arguments
 my $epoch = timelocal_from_ymd(2021, 6, 25);
 my $epoch = timegm_from_ymd   (2021, 6, 25);

=head1 DESCRIPTION

B<Early release, not all functions implemented.>

This is basically a variant or thin wrapper to L<Time::Local> to compute time
(Unix epoch) from ISO8601 strings.

=for Pod::Coverage .+

=head1 FUNCTIONS

=head2 timelocal_from_ymd

=head2 timegm_from_ymd

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Time-Local-ISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Time-Local-ISO8601>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Time-Local-ISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Time::Local::More> to compute time (Unix epoch) from separate time elements.

L<Date::Format::ISO8601> is the counterpart for this module; it formats time
(Unix epoch) into ISO8601 date/datetime string.

L<DateTime::Format::ISO8601> parses ISO8601 string into L<DateTime> object;
L<DateTime::Format::ISO8601::Format> formats DateTime object into ISO8601
date/datetime string.

C<localtime()> and C<gmtime()> in L<perlfunc>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
