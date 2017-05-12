package ThreatNet::IRC::Envelope;

=pod

=head1 NAME

ThreatNet::IRC::Envelope - IRC envelope for ThreatNet::Message objects

=head1 SYNOPSIS

  # Handle messages as provided from an IRC channel
  sub handle_message {
  	my $envelope = shift;
  	
  	# Only trust messages from our network
  	return unless $envelope->who =~ /\.mydomain.com$/;
  	
  	# Filter out anything local
  	my $message = $envelope->message;
  	return unless $LocalFilter->keep($message);
  	
  	do_something($message);
  }

=head1 DESCRIPTION

C<ThreatNet::Message> objects can be created and moved around from and
to a variety of places. However, when freshly recieved from an IRC channel,
you may wish to apply logic to them based on special IRC-specific
considerations.

The C<ThreatNet::IRC::Envelope> class provides special C<"envelope"> objects
containing the actual message objects. The channel listener is able to
apply specific logic to these envelopes, before the message itself is
extracted and moves further into a system.

The primary use for these envelopes is to allow for applying trust rules
on a sub-channel level. For example, trusting messages that come from a
specific bot in a channel when the channel as a whole is untrusted.

=head1 METHODS

=cut

use strict;
use Params::Util '_INSTANCE';
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new $Message, $who, $where

The C<new> constructor creates a new IRC envelope for a particular
message. It is most likely to happen inside the IRC/ThreatNet connector
code, rather than in your own code.

Takes as argument a L<ThreatNet::Message> object, the identifier of the
source node, and then channel name in which the message occured.

Returns a new C<ThreatNet::IRC::Envelope> object, or C<undef> on error.

=cut

sub new {
	my $class   = ref $_[0] ? ref shift : shift;
	my $Message = _INSTANCE(shift, 'ThreatNet::Message') or return undef;
	my $who     = (defined $_[0] and length $_[0]) ? shift : return undef;
	my $where   = (defined $_[0] and length $_[0]) ? shift : return undef;

	# Create the object
	my $self = bless {
		Message => $Message,
		who     => $who,
		where   => $where,
		}, $class;

	$self;
}

=pod

=head2 message

The C<message> accessor returns the contents of the envelope, a
L<ThreatNet::Message> (or sub-class) object.

=cut

sub message { $_[0]->{Message} }

=pod

=head2 who

The C<who> accessor returns the identification string of the source IRC
client.

=cut

sub who { $_[0]->{who} }

=pod

=head2 where

The C<where> accessor returns the name of the channel that the message
occured in.

=cut

sub where { $_[0]->{where} }





#####################################################################
# Params::Coerce Support

sub __as_ThreatNet_Message { shift->message(@_) }

sub __as_ThreatNet_Message_IPv4 {
	$_[0]->{Message}->isa('ThreatNet::Message::IPv4')
		? shift->message(@_)
		: undef;
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ThreatNet-IRC>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/threatnet/>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

