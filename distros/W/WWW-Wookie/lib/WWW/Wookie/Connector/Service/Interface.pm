# -*- cperl; cperl-indent-level: 4 -*-
package WWW::Wookie::Connector::Service::Interface;
use strict;
use warnings;

use utf8;
use 5.020000;

our $VERSION = '0.102';

use Moose::Role qw/requires/;
requires 'getAvailableServices';
requires 'getAvailableWidgets';
requires 'getConnection';
requires 'setUser';
requires 'getUser';
requires 'getOrCreateInstance';
requires 'addParticipant';
requires 'deleteParticipant';
requires 'getUsers';
requires 'addProperty';
requires 'setProperty';
requires 'getProperty';
requires 'deleteProperty';
requires 'setLocale';
requires 'getLocale';
requires 'getWidget';

1;

__END__

=encoding utf8

=for stopwords Wookie guid Ipenburg MERCHANTABILITY

=head1 NAME

WWW::Wookie::Connector::Service::Interface - Interface for
L<WWW::Wookie::Connector::Service|WWW::Wookie::Connector::Service>

=head1 VERSION

This document describes WWW::Wookie::Connector::Service::Interface version
0.102

=head1 SYNOPSIS

    use Moose;
    use Moose::Role;
    with 'WWW::Wookie::Connector::Service::Interface';

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<getAvailableServices>

Get a all available service categories in the server. Returns an array of
L<WWWW::Wookie::Widget::Category|WW::Wookie::Widget::Category> objects.
Throws a C<WookieConnectorException>.

=head2 C<getAvailableWidgets>

Get all available widgets in the server, or only the available widgets in the
specified service category. Returns an array of
L<WWW::Wookie::Widget|WWW::Wookie::Widget> objects, otherwise false. Throws a
C<WookieConnectorException>.

=over

=item 1. Service category name as string

=back

=head2 C<getWidget>

Get the details of the widget specified by it's identifier. Returns a
L<WWW::Wookie::Widget|WWW::Wookie::Widget> object.

=over

=item 1. The identifier of an available widget

=back

=head2 C<getConnection>

Get the currently active connection to the Wookie server. Returns a
L<WWW::Wookie::Server::Connection|WWW::Wookie::Server::Connection> object.

=head2 C<setUser>

Set the current user.

=over

=item 1. User name for the current Wookie connection 

=item 2. Screen name for the current Wookie connection

=back

=head2 C<getUser>

Retrieve the details of the current user. Returns an instance of the user as a
L<WWW::Wookie::User|WWW::Wookie::User> object.

=head2 C<getOrCreateInstance>

Get or create a new instance of a widget. The current user will be added as a
participant. Returns a
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object if
successful, otherwise false. Throws a C<WookieConnectorException>. 

=over

=item 1. Widget as guid string or a L<WWW::Wookie::Widget|WWW::Wookie::Widget>
object

=back

=head2 C<addParticipant>

Add a participant to a widget. Returns true if successful, otherwise false.
Throws a C<WookieWidgetInstanceException> or a C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of user as L<WWW::Wookie::User|WWW::Wookie::User> object

=back

=head2 C<deleteParticipant>

Delete a participant. Returns true if successful, otherwise false. Throws a
C<WookieWidgetInstanceException> or a C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of user as L<WWW::Wookie::User|WWW::Wookie::User> object

=back

=head2 C<getUsers>

Get all participants of the current widget. Returns an array of
L<WWW::Wookie::User|WWW::Wookie::User> instances. Throws a
C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=back

=head2 C<addProperty>

Adds a new property. Returns true if successful, otherwise false. Throws a
C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> object

=back

=head2 C<setProperty>

Set a new property. Returns the property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> if successful,
otherwise false. Throws a C<WookieWidgetInstanceException> or a
C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> object

=back

=head2 C<getProperty>

Get a property. Returns the property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> if successful,
otherwise false. Throws a C<WookieWidgetInstanceException> or a
C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> object

=back

=head2 C<deleteProperty>

Delete a property. Returns true if successful, otherwise false. Throws a
C<WookieWidgetInstanceException> or a C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> object

=back

=head2 C<setLocale>

Set a locale.

=over

=item 1. Locale as string

=back

=head2 C<getLocale>

Get the current locale setting. Returns current locale as string.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

L<Moose::Role|Moose::Role>

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

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
