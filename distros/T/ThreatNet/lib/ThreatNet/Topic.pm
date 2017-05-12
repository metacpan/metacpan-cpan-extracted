package ThreatNet::Topic;

=pod

=head1 NAME

ThreatNet::Topic - An object representation of a ThreatNet channel topic

=head1 DESCRIPTION

ThreatNet is an evolving idea. This standalone module defines a topic format
and an object to hold it. ThreatNet itself is not yet available.

A proposal generally defining what it B<might> be is available at:

L<http://ali.as/devel/threatnetwork.html>

=head1 METHODS

=cut

use strict;
use URI ();
use overload 'bool' => sub () { 1 },
             '""'   => 'topic';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new $topic

The C<new> constructor takes a new ThreatNet topic string and creates an
object that represents it.

A ThreatNet topic should look like the following

  threatnet://host/path configuration

That is, it should start with a 'threatnet' URI identifier in the same
style as XML namespace URIs, containing at least the host and path
components, following an arbitrary string most likely representing the
configuration and rules of the channel, with a format defined by the
protocol.

Returns a new ThreatNet::Topic object or C<undef> if the string is not a
valid ThreatNet topic string.

=cut

sub new {
	my $class  = ref $_[0] ? ref shift : shift;
	my $string = defined $_[0] ? shift : return undef;

	# Create the object
	my $self = bless {
		topic  => $string,
		config => $string,
		}, $class;

	# Extract the header URI
	$self->{config} =~ s/^(\S+)\s*// or return undef;
	$self->{URI} = URI->new("$1")    or return undef;

	# Check the URI
	$self->{URI}->scheme    and $self->{URI}->scheme eq 'threatnet' or return undef;
	$self->{URI}->authority and $self->{URI}->authority             or return undef;
	$self->{URI}->path      and $self->{URI}->path                  or return undef;

	$self;
}

=pod

=head2 topic

Accessor method that returns the Topic as a topic string.

=cut

sub topic  { $_[0]->{topic} }

=pod

=head2 URI

Accessor method that returns the protocol identifier as a URI object

=cut

sub URI    { $_[0]->{URI} }

=pod

=head2 config

Accessor method that returns the non-required protocol-specific part of
the topic, which is assumed to hold the channel configuration.

=cut

sub config { $_[0]->{config} }

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ThreatNet-Topic>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/devel/threatnetwork.html>

=head1 COPYRIGHT

Copyright (c) 2004 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
