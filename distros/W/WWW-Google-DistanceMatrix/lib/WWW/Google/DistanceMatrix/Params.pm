package WWW::Google::DistanceMatrix::Params;

$WWW::Google::DistanceMatrix::Params::VERSION   = '0.21';
$WWW::Google::DistanceMatrix::Params::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::DistanceMatrix::Params - Placeholder for parameters for WWW::Google::DistanceMatrix

=head1 VERSION

Version 0.21

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;
use parent 'Exporter';

our @EXPORT_OK = qw(validate $FIELDS);

my $LANGUAGES = {
    'ar' => 1, 'eu' => 1, 'bg'    => 1, 'bn'    => 1, 'ca'    => 1, 'cs'    => 1, 'da'    => 1, 'de' => 1,
    'el' => 1, 'en' => 1, 'en-au' => 1, 'en-gb' => 1, 'es'    => 1, 'eu'    => 1, 'fa'    => 1, 'fi' => 1,
    'fi' => 1, 'fr' => 1, 'gl'    => 1, 'gu'    => 1, 'hi'    => 1, 'hr'    => 1, 'hu'    => 1, 'id' => 1,
    'it' => 1, 'iw' => 1, 'ja'    => 1, 'kn'    => 1, 'ko'    => 1, 'lt'    => 1, 'lv'    => 1, 'ml' => 1,
    'mr' => 1, 'nl' => 1, 'no'    => 1, 'pl'    => 1, 'pt'    => 1, 'pt-br' => 1, 'pt-pt' => 1, 'ro' => 1,
    'ru' => 1, 'sk' => 1, 'sl'    => 1, 'sr'    => 1, 'sv'    => 1, 'tl'    => 1, 'ta'    => 1, 'te' => 1,
    'th' => 1, 'tr' => 1, 'uk'    => 1, 'vi'    => 1, 'zh-cn' => 1, 'zh-tw' => 1 };

my $AVOID = { 'tolls'   => 1, 'highways' => 1 };
my $UNITS = { 'metric'  => 1, 'imperial' => 1 };
my $MODE  = { 'driving' => 1, 'walking'  => 1, 'bicycling' => 1 };

our $Language = sub {
    my ($str) = @_;

    die "ERROR: Invalid data type 'language' found [$str]" unless check_language($str);
};

sub check_language { return exists $LANGUAGES->{lc($_[0])}; }

sub check_avoid { return exists $AVOID->{lc($_[0])}; }

sub check_units { return exists $UNITS->{lc($_[0])}; }

sub check_mode { return exists $MODE->{lc($_[0])}; }

sub check_latlng {
    my ($latlng) = @_;

    my $str = $latlng->[0];
    my ($lat, $lng);
    die "ERROR: Invalid data type 'latlng' found [$str]"
        unless (defined($str)
                &&
                ($str =~ /\,/)
                &&
                ((($lat, $lng) = split /\,/, $str, 2)
                 &&
                 (($lat =~ /^\-?\d+\.?\d+$/) && ($lng =~ /^\-?\d+\.?\d+$/))));
}

sub check_str {
    my ($str) = @_;

    die "ERROR: Invalid STR data type [$str]"
        if (defined $str && $str =~ /^\d+$/);
};

our $FIELDS = {
    'o_addr'       => { check => sub { check_str(@_)      }, type => 's' },
    'o_latlng'     => { check => sub { check_latlng(@_)   }, type => 's' },
    'd_addr'       => { check => sub { check_str(@_)      }, type => 's' },
    'd_latlng'     => { check => sub { check_latlng(@_)   }, type => 's' },
    'origins'      => { check => sub { check_str(@_)      }, type => 's' },
    'destinations' => { check => sub { check_str(@_)      }, type => 's' },
    'sensor'       => { check => sub { check_str(@_)      }, type => 's' },
    'avoid'        => { check => sub { check_str(@_)      }, type => 's' },
    'units'        => { check => sub { check_units(@_)    }, type => 's' },
    'mode'         => { check => sub { check_str(@_)      }, type => 's' },
    'language'     => { check => sub { check_language(@_) }, type => 's' },
};

sub validate {
    my ($fields, $values) = @_;

    die "ERROR: Missing params list." unless (defined $values);

    die "ERROR: Parameters have to be hash ref" unless (ref($values) eq 'HASH');

    foreach my $field (keys %{$fields}) {
        die "ERROR: Received invalid param: $field"
            unless (exists $FIELDS->{$field});

        die "ERROR: Received undefined mandatory param: $field"
            if ($fields->{$field} && !defined $values->{$field});

        die "ERROR: Missing mandatory param: $field"
            if ($fields->{$field} && !scalar(@{$values->{$field}}));

	$FIELDS->{$field}->{check}->($values->{$field})
            if defined $values->{$field};
    }
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-DistanceMatrix>

=head1 BUGS

Please  report any bugs or feature requests to C<bug-www-google-distancematrix at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-DistanceMatrix>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::DistanceMatrix

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-DistanceMatrix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-DistanceMatrix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-DistanceMatrix>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-DistanceMatrix/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WWW::Google::DistanceMatrix::Params
