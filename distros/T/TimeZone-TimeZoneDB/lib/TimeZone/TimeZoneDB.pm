package TimeZone::TimeZoneDB;

use strict;
use warnings;

use Carp;
use JSON::MaybeXS;
use LWP::UserAgent;
use URI;

=head1 NAME

TimeZone::TimeZoneDB - Interface to L<https://timezonedb.com> for looking up Timezone data

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use TimeZone::TimeZoneDB;

    my $tzdb = TimeZone::TimeZoneDB->new(key => 'XXXXXXXX');
    my $tz = $tzdb->get_time_zone({ latitude => 0.1, longitude => 0.2 });

=head1 DESCRIPTION

TimeZone::TimeZoneDB provides an interface to timezonedb.com
to look up timezones.

=head1 METHODS

=head2 new

    my $tzdb = TimeZone::TimeZoneDB->new();
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->env_proxy(1);
    $tzdb = TimeZone::TimeZoneDB->new(ua => $ua, key => 'XXXXX');

    my $tz = $tzdb->tz({ latitude => 51.34, longitude => 1.42 })->{'zoneName'};
    print "Ramsgate's timezone is $tz.\n";

=cut

sub new {
	my($class, %args) = @_;

	if(!defined($class)) {
		# TimeZone::TimeZoneDB::new() used rather than TimeZone::TimeZoneDB->new()
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	my $key = $args{'key'};

	if(!defined($key)) {
		Carp::carp(__PACKAGE__, ': "key" argument not given');
		return;
	}

	my $ua = $args{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
	}
	my $host = $args{host} || 'api.timezonedb.com';

	return bless { key => $key, ua => $ua, host => $host }, $class;
}

=head2 get_time_zone

    use Geo::Location::Point;

    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    # Find Ramsgate's timezone
    $tz = $tzdb->get_time_zone($ramsgate)->{'zoneName'}, "\n";

=cut

sub get_time_zone {
	my $self = shift;
	my %param;

	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif((@_ == 1) && (ref($_[0]) =~ /::/) && ($_[0]->can('latitude'))) {
		my $location = $_[0];
		$param{latitude} = $location->latitude();
		$param{longitude} = $location->longitude();
	} elsif(ref($_[0])) {
		Carp::carp('Usage: get_time_zone(latitude => $latitude, longitude => $logitude)');
		return;
	} elsif(@_ % 2 == 0) {
		%param = @_;
	}

	my $latitude = $param{latitude};
	my $longitude = $param{longitude};

	if((!defined($latitude)) || (!defined($longitude))) {
		Carp::carp('Usage: get_time_zone(latitude => $latitude, longitude => $logitude)');
		return;
	}

	my $uri = URI->new("https://$self->{host}/v2.1/get-time-zone");
	my %query_parameters = (
		by => 'position',
		lat => $latitude,
		lng => $longitude,
		format => 'json',
		key => $self->{'key'}
	);

	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();

	# $url =~ s/%2C/,/g;

	my $res = $self->{ua}->get($url);

	if($res->is_error()) {
		Carp::croak("$url API returned error: ", $res->status_line());
		return;
	}
	# $res->content_type('text/plain');	# May be needed to decode correctly

	if(my $rc = JSON::MaybeXS->new()->utf8()->decode($res->decoded_content())) {
		if($rc->{'status'} ne 'OK') {
			# TODO: print error code
			return;
		}
		return $rc;	# No support for list context, yet
	}

	# my @results = @{ $data || [] };
	# wantarray ? @results : $results[0];
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    $tzdb->ua()->env_proxy(1);

Free accounts are limited to one search a second,
so you can use L<LWP::UserAgent::Throttled> to keep within that limit.

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle('timezonedb.com' => 1);
    $tzdb->ua($ua);

=cut

sub ua {
	my $self = shift;
	if (@_) {
		$self->{ua} = shift;
	}
	$self->{ua};
}

=head1 AUTHOR

Nigel Horne, C<< <njh@bandsman.co.uk> >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at L<https://timezonedb.com>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-timezone-timezonedb at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TimeZone-TimeZoneDB>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

TimezoneDB API: L<https://timezonedb.com/api>

=head1 LICENSE AND COPYRIGHT

Copyright 2023-2024 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
