package ThreatNet::Filter::ThreatCache;

=pod

=head1 NAME

ThreatNet::Filter::ThreatCache - A Threat Cache implementated as a filter

=head1 DESCRIPTION

A C<ThreatNet::Filter::ThreatCache> is a basic filter-based implementation
of a I<Threat Cache>, as defined in the ThreatNet concept paper.
(L<http://ali.as/threatnet/>)

The consistent use of Threat Caches by all nodes is the key to keeping
message quantities to a minimum, and allows the entire network to safely
run without any canonical state.

As each message is provided to the filter, it stores an IPs that it sees,
filtering out any ips that have already been seen in the last hour (or
custom period if provided).

=head1 METHODS

=cut

use strict;
use Params::Util '_INSTANCE';
use base 'ThreatNet::Filter';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}





#####################################################################
# ThreatNet::Filter Interface

=pod

=head2 new [ $param => $value, ... ]

The C<new> method creates a new Threat Cache object.

It takes a single optional parameter C<timeout> which should the
positive integer number of seconds the channel dictates as the mimumum
time before an event can be rementioned. The default value is 3600
(1 hour).

Returns a new C<ThreatNet::Filter::ThreatCache> object.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my %args  = @_;

	# Add the cache attributes to the base filter object
	my $self = $class->SUPER::new;
	$self->{cache_ip}   = {};
	$self->{cache_time} = [];

	# When we will be syncronised?
	# Add a couple of seconds to allow for small initialization delays.
	my $t = time();
	$self->{timeout} = defined $args{timeout} ? $args{timeout} : 3600;
	$self->{sync_at} = $self->{timeout} + $t + 2;

	# Collect some very basic statistic
	$self->{stats} = { time_start => $t, => seen => 0, kept => 0 };

	$self;
}

=pod

=head2 keep $Message

As in the parent L<ThreatNet::Filter> class, the C<keep> method takes as
argument a single C<ThreatNet::Message> object.

It returns true if the message can be kept, or false if the message should
be dropped.

=cut

sub keep {
	my $self    = shift;
	my $Message = _INSTANCE(shift, 'ThreatNet::Message') or return undef;
	$Message->can('ip') or return undef; # WTF is it if it can't?

	# Flush old events out of the cache
	while ( my $event = $self->{cache_time}->[0] ) {
		if ( time() > $event->{time} + $self->{timeout} ) {
			# Block has expired
			shift @{$self->{cache_time}};
			delete $self->{cache_ip}->{$event->{ip}};
		} else {
			# Because the events are added (we assume) in creation
			# order, as soon as we encounter one that has not expired,
			# we can assume the rest have not expired.
			last;
		}
	}

	# We only want the time and IP
	### Convert this to ->event_time later?
	my $created = $Message->created or return undef;
	my $ip      = $Message->ip      or return undef;

	# At this point, we've officially "seen" the message
	$self->{stats}->{seen}++;

	# If the ip is in the cache, don't keep it
	return '' if $self->{cache_ip}->{$ip};

	# Add to the cache and signal to keep.
	### Stricly speaking, just dropping it onto the end of the
	### queue is not good enough. Convert this to something that
	### ensures correct order once there is a chance that the events
	### may come in out of order, such as if we change from object
	### creation time to event time.
	$self->{cache_ip}->{$ip} = $created;
	push @{$self->{cache_time}}, { time => $created, ip => $ip };
	$self->{stats}->{kept}++;

	1;
}

=pod

=head2 synced

The C<synced> method checks to see if the Threat Cache has synchronised
with the channel.

Returns true if the current time is past the sync time, or false if not.

=cut

sub synced {
	my $self = shift;
	!! (time() > $self->{sync_at});
}

=pod

=head2 stats

The C<stats> method returns a hash with a variety of statistics from
the Threat Cache.

Returns the stats as a C<HASH> reference.

=cut

sub stats {
	my $self  = shift;
	my %stats = ();

	# Generate the general statistics
	$stats{size}    = scalar @{$self->{cache_time}};
	$stats{seen}    = $self->{stats}->{seen};
	$stats{kept}    = $self->{stats}->{kept};
	$stats{discard} = $stats{seen} - $stats{kept};
	$stats{expired} = $stats{kept} - $stats{size};
	
	# Add the time statistics
	$stats{time_start}   = $self->{stats}->{time_start};
	$stats{time_current} = time();
	$stats{time_running} = $stats{time_current} - $stats{time_start};

	# Percentages
	$stats{percent_kept}    = $self->_perc($stats{kept}, $stats{seen});
	$stats{percent_discard} = $self->_perc($stats{discard}, $stats{seen});

	# Rates
	$stats{rate_seen} = $self->_rate($stats{seen}, $stats{time_running});
	$stats{rate_kept} = $self->_rate($stats{kept}, $stats{time_running});

	\%stats;
}

sub _perc {
	my (undef, $items, $total) = @_;
	my $perc = $total ? ($items / $total) : 0;
	$perc = $perc * 100;
	sprintf("%0.1f", $perc) . '%';
}

sub _rate {
	my (undef, $items, $interval) = @_;
	my $rate = $interval ? ($items / $interval) : 0;
	sprintf("%0.1f", $rate);
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

L<http://ali.as/devel/threatnetwork.html>, L<ThreatNet::Filter>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
