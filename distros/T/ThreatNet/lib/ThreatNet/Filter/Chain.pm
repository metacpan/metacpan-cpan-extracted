package ThreatNet::Filter::Chain;

=pod

=head1 NAME

ThreatNet::Filter::Chain - Create a chain of ThreatNet filters

=head1 SYNOPSIS

    # After stripping junk ips, pass events through a Threat Cache,
    # and then keep only the events that have occured in an IP range
    # that we are responsible for.
    my $Chain = ThreatNet::Filter::Chain->new(
    	ThreatNet::Filter::Junk->new,
    	ThreatNet::Filter::ThreatCache->new,
    	ThreatNet::Filter::Network->new( '202.123.123.0/24' ),
    	);
    
    sub process_message {
    	my $Message = shift;
    	
    	unless ( $Chain->keep($Message) ) {
    		return;
    	}
    	
    	print "Threat spotted in our network at " . $Message->ip . "\n";
    }

=head1 DESCRIPTION

C<ThreatNet::Filter::Chain> lets you create filters that represent an
entire chain of filters. L<ThreatNet::Message> objects are checked against
each individual filter in the same order.

A message must pass the C<keep> method of each filter to move down the
chain. If a message is rejected at a point in chain, filters further down
the chain will not see them. This is mainly of importance to stateful
filters such as L<ThreatNet::Filter::ThreatCache>.

It is assumed you don't actual care B<which> filter rejects a message,
and as such there is no way to tell this :)

=head1 METHODS

The methods are the same as for the parent L<ThreatNet::Filter> class, but
with a change to the C<new> constructor.

=cut

use strict;
use Params::Util '_SET', '_INSTANCE';
use base 'ThreatNet::Filter';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}

=pod

=head2 new $Filter [, $Filter, ... ]

The C<new> constructor takes a set of (1 or more) L<ThreatNet::Filter>
objects, and creates a Filter object that acts as a I<"short-cutting
logical AND"> combination of them.

Returns a new C<ThreatNet::Filter::Chain> object, or C<undef> if not
provided with the correct params.

=cut

sub new {
	my $class   = ref $_[0] ? ref shift : shift;
	my $filters = _SET([ @_ ], 'ThreatNet::Filter') or return undef;

	my $self  = $class->SUPER::new;
	$self->{filters} = $filters;

	$self;
}

=pod

=head2 keep $Message

The C<keep> method takes a single L<ThreatNet::Message> object and checks
it against each of the child filters in turn, short-cutting if any of
them does not want to keep the message.

One small note - The C<keep> method returns B<exactly> the same false value
it recieves from the child filter, whether that is normal false or C<undef>.

Returns true if you should keep the message, or false to discard.

=cut

sub keep {
	my $self    = shift;
	my $Message = _INSTANCE(shift, 'ThreatNet::Message') or return undef;

	foreach my $Filter ( @{$self->{filters}} ) {
		my $rv = $Filter->keep($Message);
		return $rv unless $rv; # false or undef
	}

	1;
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

L<http://ali.as/threatnet/>, L<ThreatNet::Filter>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
	