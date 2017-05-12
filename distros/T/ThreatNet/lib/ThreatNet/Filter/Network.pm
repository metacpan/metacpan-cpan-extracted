package ThreatNet::Filter::Network;

=pod

=head1 NAME

ThreatNet::Filter::Network - Filter events within a set of IP ranges

=head1 SYNOPSIS

  # Filter for IPs in our broadband customers' range
  my $Broadband = ThreatNet::Filter::Network->new( keep => '123.123.0.0/16' );
  
  # Create a filter for "local" and other things we want to discard
  # (including our own personal broadband IP in the above network)
  my $NotLocal = ThreatNet::Filter::Network->new( discard => qw{
      123.123.123.123
      LOCAL
      111.245.76.248/29
      222.234.52.192/29
      } );
  
  sub boot_zombies {
  	my $Msg = shift;
  	if ( $Broadband->keep($Msg) and $NotLocal->keep($Msg) ) {
  		my $account = $RadiusServer->ip_to_account($Msg->ip);
  		$account->disable();
  		$account->disconnect();
  		$account->add_support_note("You are infected with a virus");
  	}
  }

=head1 DESCRIPTION

C<ThreatNet::Filter::Network> is a filter class for creating network
filters.

That is, for filtering event streams to just those events that did
(or did not) occur within a particular network.

The objects only check in two modes.

The C<keep> keyword as first argument indicates events should be kept if
they match B<any> of the networks.

The C<discard> keyword as first argument indicates events should be kept
only if they do B<not> match any of networks.

For more complex network masks, see the L<ThreatNet::Filter::Chain> class
for chaining groups of C<keep> and C<discard> filters together.

=head2 Specifying the Networks

The actual matching is done using the L<Net::IP::Match::XS> module. Any
values that can be used by it can also be used with it can thus also be
used with C<ThreatNet::Filter::Network>.

=head2 Keyword Expansion

In addition to the normal IP specification above,
C<ThreatNet::Filter::Network> also supports keyword expansion for a
number of standard sets of network masks.

When specified by name, they will be expanded into a list of IP ranges.

Thus you can do something like the following.

  my $Remove = ThreatNet::Filter::Network->new(
      discard => 'RFC1918', '123.123.123.0/24'
      );

This will filter out the three standard "local" IP blocks specified by
RFC1918, plus the addition range 123.123.123.0 - 123.123.123.255.

All keywords are case-insensitive.

=head3 RFC1918

The C<RFC1918> keyword is expanded to the three network blocks reserved
for local intranets. This specifically does NOT include the localhost
address space.

=head3 RFC3330

The C<RFC3330> keyword is expanded to a larger set of network blocks
restricted for various purposes as identifier in RFC3330. This includes
those from C<RFC1918>, the localhost block, and several additional
blocks reserved for benchmarking, IP 6to4 identifiers and various other
blocks that should not appear in threat messages.

Where correctness is a factor, such as posting to a non-C<tolerant>
channel, this filter should be applied before issuing messages, as they
are highly likely to be fraudulent or technically nonsensical.

=head3 LOCAL

The C<LOCAL> keyword is expanded to represent the most common
interpretation of a "local" address, which is the RFC1918 addresses,
plus the C<127.0.0.0/8> localhost block.

=head2 Message Compatibility

Please note that because the module on which this filter is based only
supports IPv4 ranges, this filter class is B<only> capable of processing
L<ThreatNet::Message::IPv4> (or subclass) objects.

Any other message types passed to C<keep> will be returns C<undef>, and
thus will act as a null filter in most configurations.

=head1 METHODS

=cut

use strict;
use Params::Util '_INSTANCE',
                 '_IDENTIFIER';
use base 'ThreatNet::Filter';
use Net::IP::Match::XS ();
use ThreatNet::Message::IPv4 ();

use vars qw{$VERSION %KEYWORD};
BEGIN {
	$VERSION = '0.20';

	# Expandable network keywords
	%KEYWORD = ();
	$KEYWORD{RFC1918} = [qw{
		10.0.0.0/8
		172.16.0.0/12
		192.168.0.0/16
		}];
	$KEYWORD{RFC3330} = [qw{
		0.0.0.0/8
		10.0.0.0/8
		127.0.0.0/8
		169.254.0.0/16
		172.16.0.0/12
		192.0.2.0/24
		192.168.0.0/16
		192.88.99.0/24
		198.18.0.0/15
		224.0.0.0/4
		240.0.0.0/4
		}];
	$KEYWORD{LOCAL} = [qw{
		127.0.0.0/8
		10.0.0.0/8
		172.16.0.0/12
		192.168.0.0/16
		}];			
}





####################################################################3
# Constructor and Accessors

=pod

=head2 new ('keep' | 'discard'), $network, ...

The C<new> constructor takes a param of either C<keep> or C<discard>,
followed by a list of one or more values which are either an expandable
keyword or an ip ranges compatible with L<Net::IP::Match::XS>.

A ThreatNet filter is created which limits a message stream to events
either inside or outside of the resulting network.

Returns a new C<ThreatNet::Filter::Network> object, or C<undef> if given
invalid params.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	# Check we are either a 'keep' or 'discard' filter
	my $type  = lc _IDENTIFIER(shift)     or return undef;
	$type eq 'keep' or $type eq 'discard' or return undef;

	# Get the list of values, filter and keyword-expand
	my @network = map { $KEYWORD{$_} ? @{$KEYWORD{$_}} : $_ }
		map { uc $_ } grep { defined $_ } @_;

	# Initial version doesn't check the IP ranges.
	# It just makes sure we have at least one.
	@network or return undef;

	# Create the object
	my $self = bless {
		keep    => $type eq 'keep',
		network => [ @network ],
		}, $class;

	$self;
}

=pod

=head2 type

The C<type> accessor returns the type of the network filter.

Returns either C<'keep'> or C<'discard'>.

=cut

sub type {
	$_[0]->{keep} ? 'keep' : 'discard';
}

=pod

=head2 network

The C<network> accessor returns the list of ip ranges as provided to
the constructor.

=cut

sub network {
	@{$_[0]->{network}};
}





#####################################################################
# ThreatNet::Filter Methods

=pod

=head2 keep $Message

The C<keep> method takes a C<ThreatNet::Message::IPv4> message as per the
L<ThreatNet::Filter> specification, and checks it against the network
specification and C<keep>|C<discard> type.

Returns true if the message should be kept, false if not, or C<undef> on
error.

=cut

sub keep {
	my $self    = shift;
	my $Message = _INSTANCE(shift, 'ThreatNet::Message::IPv4') or return undef;
	my $rv = Net::IP::Match::XS::match_ip( $Message->ip, @{$self->{network}} );
	defined $rv ? $self->{keep} ? !! $rv : ! $rv : undef;
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ThreatNet-Filter>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/devel/threatnetwork.html>, L<ThreatNet::Filter>,
L<ThreatNet::Message::IPv4>.

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
