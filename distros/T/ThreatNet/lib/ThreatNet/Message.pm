package ThreatNet::Message;

=pod

=head1 NAME

ThreatNet::Message - An object representation of a ThreatNet channel message

=head1 DESCRIPTION

ThreatNet is an evolving idea. It's homepage at time of publishing is

L<http://ali.as/threatnet/>

This module is an abstract base class for a ThreatNet channel message,
and allows you to create objects representing threat messages in a channel.

ThreatNet itself is not yet available and this module has been uploaded
seperately so people working on ThreatNet can play with the various
compenents in different ways before we come to a decision about what
collection of modules will be included in a core ThreatNet.pm package.

=head1 METHODS

=cut

use strict;
use overload 'bool' => sub () { 1 },
             '""'   => 'message',
             '+0'   => 'event_time';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}





#####################################################################
# Base Constructor

=pod

=head2 new $message

The C<new> constructor takes a string containing the actual channel message
and creates a new object. Please be aware that this method is likely to be
heavily overloaded, so there may be additional requirements.

This base class is extremely flexible and makes absolutely no requirements
on the content of the message, even that is has length.

For an example of a potentially more useful Message class, see
L<ThreatNet::Message::GenericIPv4>

Returns a C<ThreatNet::Message> object on success, false if the message is
not a valid message for a particular message class, or C<undef> on error,
such as being passed a non-string.

=cut

sub new {
	my $class   = ref $_[0] ? ref shift : shift;
	my $message = _STRING0($_[0]) ? shift : return undef;

	# Create the object
	my $self = bless {
		message => $message,
		created => time(),
		}, $class;

	$self;
}

=pod

=head2 message

For any C<ThreatNet::Messsage> class, the C<message> accessor will always
return the message in string form, although it may have been canonicalised
and might not be identical to the original string.

=cut

sub message { $_[0]->{message} }

=pod

=head2 created

The C<created> method returns the unix epoch time that the
C<ThreatNet::Message> object was created (on the machine on which
the object was created).

For some situations, this will be sufficient for use as the time
at which the event occured. Please be aware however, that it is
C<not> the time at which the event actually occured.

Some protocols may supply the B<actual> event time independantly.

Returns the unix epoch time in seconds as an integer.

=cut

sub created { $_[0]->{created} }

=pod

=head2 event_time

The C<event_time> method returns the event time, or as close an estimate
as the object is capable of providing.

Unless the C<ThreatNet::Message> class is actually aware of the true
event time, it will generally estimate using the object creation time.

Returns the unix epoch time in seconds as an integer.

=cut

sub event_time { $_[0]->created(@_) }





#####################################################################
# Support Functions

sub _STRING0 ($) {
	!! (defined $_[0] and ! ref $_[0]);
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ThreatNet-Message>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/devel/threatnetwork.html>, L<ThreatNet::Topic>

=head1 COPYRIGHT

Copyright (c) 2004 - 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
