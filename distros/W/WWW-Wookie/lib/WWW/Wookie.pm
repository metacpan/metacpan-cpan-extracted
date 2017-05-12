package WWW::Wookie 0.102;    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

use utf8;
use 5.020000;

1;

__END__

=encoding utf8

=for stopwords Wookie Readonly URI PHP Ipenburg MERCHANTABILITY

=head1 NAME

WWW::Wookie - Apache Wookie Connector Framework implementation

=head1 VERSION

This document describes WWW::Wookie version 0.102, which is probably the
latest version because the Wookie project is retired
L<http://attic.apache.org/projects/wookie.html>

=head1 SYNOPSIS

    use WWW::Wookie::Connector::Service;

    $w = WWW::Wookie::Connector::Service->new(
        $SERVER, $API_KEY, $SHARED_DATA_KEY, $USER
    );
    @available_widgets = $w->getAvailableWidgets;

=head1 DESCRIPTION

This is a Perl implementation of the Wookie Connector Framework. For more
information see: L<http://wookie.apache.org|http://wookie.apache.org>

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

The Wookie Connector Framework is supposed to connect to a Wookie server, see
L<http://wookie.apache.org|http://wookie.apache.org>.

=head1 DEPENDENCIES

=over 4

=item * L<Exception::Class|Exception::Class>

=item * L<HTTP::Headers|HTTP::Headers>

=item * L<HTTP::Request|HTTP::Request>

=item * L<HTTP::Request::Common|HTTP::Request::Common>

=item * L<HTTP::Status|HTTP::Status>

=item * L<LWP::UserAgent|LWP::UserAgent>

=item * L<Log::Log4perl|Log::Log4perl>

=item * L<Moose|Moose>

=item * L<Moose::Role|Moose::Role>

=item * L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>

=item * L<Readonly|Readonly>

=item * L<Regexp::Common|Regexp::Common>

=item * L<URI|URI>

=item * L<URI::Escape|URI::Escape>

=item * L<XML::Simple|XML::Simple>

=item * L<namespace::autoclean|namespace::autoclean>

=item * L<Test::More|Test::More>

=item * L<Test::NoWarnings|Test::NoWarnings>

=back

=head1 INCOMPATIBILITIES

This is a port based on the PHP version of the Wookie Connector Framework, not
a port of the reference Java version of the Wookie Connector Framework.

=head1 DIAGNOSTICS

This module uses L<Log::Log4perl|Log::Log4perl> for logging.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at L<RT for
rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Queue=WWW-Wookie>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
