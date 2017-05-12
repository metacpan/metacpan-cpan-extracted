package WWW::Tracking;

use warnings;
use strict;

our $VERSION = '0.05';

use base 'Class::Accessor::Fast';

use Carp::Clan 'croak';
use Scalar::Util 'weaken';
use WWW::Tracking::Data;

__PACKAGE__->mk_accessors(qw{
	tracker_account
	tracker_type
	tracker_url
	data
});

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new({
		@_
	});
	
	return $self;
}

sub from {
	my $self = shift;
	my $type = shift;
	my $args = shift;
	
	my $from_type = 'from_'.$type;
	
	croak 'no such data plugin for "'.$type.'"'
		unless WWW::Tracking::Data->can($from_type);
	
	my $tracking_data = WWW::Tracking::Data->$from_type($args);
	weaken($self);
	$tracking_data->_tracking($self);
	$tracking_data->new_visitor_id
		unless $tracking_data->visitor_id;
	
	$self->data($tracking_data);
	
	return $self;
}

sub make_tracking_request {
	my $self = shift;
	
	my $tracker_type = $self->tracker_type or croak 'tracker type not set';
	my $tracker_function = 'make_tracking_request_'.$tracker_type;
	
	croak 'no tracking with '.$tracker_type.'possible'
		unless $self->data->can($tracker_function);
	
	return $self->data->$tracker_function;
}

1;


__END__

=head1 NAME

WWW::Tracking - universal website visitors tracking

=head1 SYNOPSIS

	use WWW::Tracking;
	use WWW::Tracking::Data::Plugin::GoogleAnalytics;

	my $wt = WWW::Tracking->new(
		tracker_account => 'MO-9226801-5',
		tracker_type    => 'ga',
	);

	$wt->from(
		headers => {
			headers             => $c->request->headers,
			'request_uri'       => $c->request->uri,
			'remote_ip'         => $c->address,
			visitor_cookie_name => '__vcid',
		},
	);
	
	eval { $wt->make_tracking_request; };
	warn 'tracking request failed - '.$@
		if $@;
	
	say $wt->data->visitor_id;
	say $wt->data->hostname;
	say $wt->data->request_uri;
	say $wt->data->referer;
	say $wt->data->user_agent;
	say $wt->data->browser_language;
	say $wt->data->remote_ip;

	my $data = $wt->data->as_hash;
	my $wt2 = $wt->from(hash => $data);

	my $ga_url = $wt->data->as_ga;

	###
	# TODO

	my $wt3 = $wt->from(ga => $ga_url);
	
	use WWW::Tracking::Data::Plugin::Piwik;
	my $piwik_url = $wt->data->as_piwik;
	my $wt3 = $wt->from(piwik => $piwik_url);

	use WWW::Tracking::Data::Plugin::ECSV;
	my $line = $wt->data->as_ecsv;
	my $wt4 = $wt->from(ecsv => $line));

	use WWW::Tracking::Data::Plugin::Log;
	my $line2 = $wt->data->as_log;
	my $wt5 = $wt->from(log => $line2));

=head1 NOTE

Work in progress, designed to be pluggable, but for now only things that
I need (headers parsing and server-side Google Analytics) are implemented.

=head1 DESCRIPTION

=head2 GOAL

Server-side web hits tracking, generic and flexible enough so that 
many tracking services like Google Analytics, Piwik, local file, etc.
can be used depending on configuration.

=head2 VISION

Universal enough to process many sources (headers, logs, tracking URL-s, ...)
and covert or relay them to different other destinations (GA, Piwik, ...)
making use of the fact that the tracking data information is the same or
nearly the same for all the sources and destinations.

=head2 IMPLEMENTATION

Initially tracking data needs to be gathered. Look at L<WWW::Tracking::Data>
for the complete list. Most of these data can be found in headers of the
http request. Then these data can be serialized and passed on to one of
the tracking services.

Bare L<WWW::Tracking::Data> offers just C<as_hash> and C<from_hash>, the
rest can be done by one or more plugins, like for example parsing the
http headers with L<WWW::Tracking::Data::Plugin::Headers> and passing it
to L<WWW::Tracking::Data::Plugin::GoogleAnalytics>.

=head2 USE CASES

=over 4

=item *

tracking browsers that doesn't support JavaScript (ex. mobile browsing)

=item *

store the tracking data in local logs or files and replay it later to
Piwik or Google Analytics

=item *

track web browsing simultaneous to more tracking services (compare the
results, choose the one that fits)

=item *

aid with transition from one tracking service to another 

=back

=head1 PROPERTIES

	tracker_account
	tracker_type
	data

=head1 METHODS

=head2 new()

Object constructor.

=head2 from($type, $args)

Will call one of the C<from_$type> functions provided by
C<WWW::Tracking::Data::Plugin::*> passing on C<$args>.

=head2 make_tracking_request

Makes request (http, write to file, ...) to the tracking API via
calling one of the C<make_tracking_request_$tracker_type> that are
provided by C<WWW::Tracking::Data::Plugin::*>.

=head1 SEE ALSO

L<http://code.google.com/apis/analytics/docs/tracking/gaTrackingTroubleshooting.html#gifParameters>

L<http://piwik.org/docs/tracking-api/>

=head1 AUTHOR

Jozef Kutej

=cut
