package Weather::Underground::StationHistory;

use 5.006000;

use strict;
use warnings;

use version; our $VERSION = qv('v1.0.5');

use Exporter;
use base 'Exporter';

use Regexp::Common;

our @EXPORT_OK =
    qw{
        &generate_single_day_station_history_url
        &strip_garbage_from_station_history
    };
our %EXPORT_TAGS = (
    all => [@EXPORT_OK],
);

my $EMPTY_STRING = q<>;

sub generate_single_day_station_history_url {
    my ($station_id, $year, $month_number, $day_of_month) = @_;

    return
        sprintf
            'http://www.wunderground.com/weatherstation/WXDailyHistory.asp?ID=%s&year=%d&month=%d&day=%d&graphspan=day&format=1',
            $station_id,
            $year,
            $month_number,
            $day_of_month,
        ;
} # end generate_single_day_station_history_url()

sub strip_garbage_from_station_history {
    my $original_contents   = shift;
    my @original_lines      = split m/ [\r\n]+ /xms, $original_contents;
    my $resulting_contents  = $EMPTY_STRING;

    foreach my $original_line (@original_lines) {
        $original_line =~ s/ $RE{balanced}{-parens => '<>'} //xmsg;
        $original_line =~ s/ $RE{ws}{crop}                  //xmsg;

        if ($original_line ne $EMPTY_STRING) {
            $resulting_contents .= "$original_line\n";
        } # end if
    } # end foreach

    return $resulting_contents;
} # end strip_garbage_from_station_history()


1; # Magic true value required at end of module
__END__

=for stopwords CSV

=head1 NAME

Weather::Underground::StationHistory - Utility functions for dealing with weather station historical data from L<http://wunderground.com>.


=head1 VERSION

This document describes Weather::Underground::StationHistory version 1.0.5.


=head1 SYNOPSIS

    use Weather::Underground::StationHistory qw{ :all };

    use LWP::Simple;

    print
        strip_garbage_from_station_history(
            get(
                generate_single_day_station_history_url(
                    'KILCHICA52',
                    2006,
                    10,
                    27,
                )
            )
        );


=head1 DESCRIPTION

This module provides a URL generator function for retrieving historical data
for weather stations from Weather Underground (L<http://wunderground.com>).

Additionally, a function to clean up the data retrieved from said URLs is
provided.  Nominally, the content retrieved from the URLs is in CSV (Comma
Separated Values) format.  If you enter these URLs into a web browser, the data
does appear to be in that format.  However, the MIME type given for the data by
the web server is C<text/html> and the data contains C<< <br> >> tags and HTML
comments (though no C<< <html> >>, C<< <head> >>, or C<< <body> >> tags that
you would expect for an HTML document). Thus, if a user copies and pastes the
data from the web browser, the application receiving the data will get correct
CSV, but anything trying to directly parse the page content as CSV will
encounter problems.


=head1 INTERFACE

=over

=item C<generate_single_day_station_history_url($station_id, $year, $month_number, $day_of_month)>

Returns the URL to use for retrieving data for the station on the specified
day.

C<$year> needs to be the full year number; two digit years are not supported.

C<$month_number> needs to be in the range 1 to 12.


=item C<strip_garbage_from_station_history($original_contents)>

Takes a string containing the data retrieved from Weather Underground and
returns a string containing the same data, without the standard problematic
content.

Note: this function B<does not> ensure that the data is in valid CSV format.
It merely removes extraneous text that usually causes problems in parsing.

The returned value has lines delimited by whatever your platform translates
C<"\n"> to, which may be different from what Weather Underground is returning.


=back


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

Weather::Underground::StationHistory requires no configuration files or
environment variables.


=head1 DEPENDENCIES

L<Regexp::Common>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-weather-underground-stationhistory@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.


=head1 SEE ALSO

L<Weather::Underground> for retrieving current conditions.


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2008, Elliot Shank C<< <perl@galumph.com> >>. All rights
reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
