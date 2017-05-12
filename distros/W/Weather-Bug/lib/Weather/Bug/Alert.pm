package Weather::Bug::Alert;

use warnings;
use strict;
use Moose;
use XML::LibXML;
use Weather::Bug;

our $VERSION = '0.25';

has 'type' => ( is => 'ro', isa => 'Str', init_arg => '-type' );
has 'title' => ( is => 'ro', isa => 'Str', init_arg => '-title' );

sub from_xml
{
    my $class = shift;
    my $node = shift;

    return Weather::Bug::Alert->new(
        -type => $node->findvalue( 'aws:type' ),
        -title => $node->findvalue( 'aws:title' ),
    );

}

1; # Magic true value required at end of module
__END__

=head1 NAME

Weather::Bug::Alert - Simple class interface to WeatherBug alerts.

=head1 VERSION

This document describes Weather::Bug::Alert version 0.25

=head1 SYNOPSIS

    use Weather::Bug;

    my $wbug = Weather::Bug->new( 'YOURAPIKEYHERE' );
    my @alerts = $wxbug->get_alerts( 77096 );

    foreach my $alert ( @alerts )
    {
        print "Alert type: ", $alert->alert(), "\n",
              $alert->title(), "\n";
    }

=head1 DESCRIPTION

The Alert class wraps the concept of a WeatherBug alert. Alerts are retrieved
with the Weather::Bug::getalerts method, passing the zip code of interest.

=head1 INTERFACE 

=head2 Factory Methods

Since the Alert object will almost always be created from an XML stream,
this class provides a method for constructing a Alert object from the XML
responses.

=over 4

=item from_xml

This method constructs a Weather::Bug::Alert object from the XML returned by the
WeatherBug getalert API call. It is a class method that takes an XML::LibXML node
object that points to the C<aws:alert> node.

The method constructs a new Weather::Bug::Alert object from this XML node.

=back

=head2 Accessor Methods

The Alert object provides accessor methods for the following fields:

=over 4

=item type

This method returns the type of the alert. The text returned is a high-level
description of the type of alert. (For example, I<Air Quality Alert>)

=item title

This method returns the alert itself.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Weather::Bug requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Moose>, C<XML::LibXML>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-weather-weatherbug@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

G. Wade Johnson  C<< <wade@anomaly.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, G. Wade Johnson C<< <wade@anomaly.org> >>. All rights reserved.

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
