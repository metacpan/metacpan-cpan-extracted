package Travel::Routing::DE::HAFAS;

# vim:foldmethod=marker

use strict;
use warnings;
use 5.014;
use utf8;

use Carp qw(confess);
use DateTime;
use DateTime::Format::Strptime;
use Digest::MD5 qw(md5_hex);
use Encode      qw(decode encode);
use JSON;
use LWP::UserAgent;
use Travel::Routing::DE::HAFAS::Connection;
use Travel::Status::DE::HAFAS::Location;
use Travel::Status::DE::HAFAS::Message;

our $VERSION = '0.06';

# {{{ Endpoint Definition

my %hafas_instance = (
	DB => {
		mgate       => 'https://reiseauskunft.bahn.de/bin/mgate.exe',
		name        => 'Deutsche Bahn',
		productbits => [qw[ice ic_ec d regio s bus ferry u tram ondemand]],
		salt        => 'bdI8UVj4' . '0K5fvxwf',
		languages   => [qw[de en fr es]],
		request     => {
			client => {
				id   => 'DB',
				v    => '20100000',
				type => 'IPH',
				name => 'DB Navigator',
			},
			ext  => 'DB.R21.12.a',
			ver  => '1.15',
			auth => {
				type => 'AID',
				aid  => 'n91dB8Z77' . 'MLdoR0K'
			},
		},
	},
	NAHSH => {
		mgate       => 'https://nah.sh.hafas.de/bin/mgate.exe',
		name        => 'Nahverkehrsverbund Schleswig-Holstein',
		productbits => [qw[ice ice ice regio s bus ferry u tram ondemand]],
		request     => {
			client => {
				id   => 'NAHSH',
				v    => '3000700',
				type => 'IPH',
				name => 'NAHSHPROD',
			},
			ver  => '1.16',
			auth => {
				type => 'AID',
				aid  => 'r0Ot9FLF' . 'NAFxijLW'
			},
		},
	},
	NASA => {
		mgate       => 'https://reiseauskunft.insa.de/bin/mgate.exe',
		name        => 'Nahverkehrsservice Sachsen-Anhalt',
		productbits => [qw[ice ice regio regio regio tram bus ondemand]],
		languages   => [qw[de en]],
		request     => {
			client => {
				id   => 'NASA',
				v    => '4000200',
				type => 'IPH',
				name => 'nasaPROD',
				os   => 'iPhone OS 13.1.2',
			},
			ver  => '1.18',
			auth => {
				type => 'AID',
				aid  => 'nasa-' . 'apps',
			},
			lang => 'deu',
		},
	},
	NVV => {
		mgate       => 'https://auskunft.nvv.de/auskunft/bin/app/mgate.exe',
		name        => 'Nordhessischer VerkehrsVerbund',
		productbits =>
		  [qw[ice ic_ec regio s u tram bus bus ferry ondemand regio regio]],
		request => {
			client => {
				id   => 'NVV',
				v    => '5000300',
				type => 'IPH',
				name => 'NVVMobilPROD_APPSTORE',
				os   => 'iOS 13.1.2',
			},
			ext  => 'NVV.6.0',
			ver  => '1.18',
			auth => {
				type => 'AID',
				aid  => 'Kt8eNOH7' . 'qjVeSxNA',
			},
			lang => 'deu',
		},
	},
	'ÖBB' => {
		mgate       => 'https://fahrplan.oebb.at/bin/mgate.exe',
		name        => 'Österreichische Bundesbahnen',
		productbits => [
			[ ice_rj => 'long distance trains' ],
			[ sev    => 'rail replacement service' ],
			[ ic_ec  => 'long distance trains' ],
			[ d_n    => 'night trains and rapid trains' ],
			[ regio  => 'regional trains' ],
			[ s      => 'suburban trains' ],
			[ bus    => 'busses' ],
			[ ferry  => 'maritime transit' ],
			[ u      => 'underground' ],
			[ tram   => 'trams' ],
			[ other  => 'other transit services' ]
		],
		request => {
			client => {
				id   => 'OEBB',
				v    => '6030600',
				type => 'IPH',
				name => 'oebbPROD-ADHOC',
			},
			ver  => '1.57',
			auth => {
				type => 'AID',
				aid  => 'OWDL4fE4' . 'ixNiPBBm',
			},
			lang => 'deu',
		},
	},
	VBB => {
		mgate       => 'https://fahrinfo.vbb.de/bin/mgate.exe',
		name        => 'Verkehrsverbund Berlin-Brandenburg',
		productbits => [qw[s u tram bus ferry ice regio]],
		languages   => [qw[de en]],
		request     => {
			client => {
				id   => 'VBB',
				type => 'WEB',
				name => 'VBB WebApp',
				l    => 'vs_webapp_vbb',
			},
			ext  => 'VBB.1',
			ver  => '1.33',
			auth => {
				type => 'AID',
				aid  => 'hafas-vb' . 'b-webapp',
			},
			lang => 'deu',
		},
	},
	VBN => {
		mgate       => 'https://fahrplaner.vbn.de/bin/mgate.exe',
		name        => 'Verkehrsverbund Bremen/Niedersachsen',
		productbits => [qw[ice ice regio regio s bus ferry u tram ondemand]],
		salt        => 'SP31mBu' . 'fSyCLmNxp',
		micmac      => 1,
		languages   => [qw[de en]],
		request     => {
			client => {
				id   => 'VBN',
				v    => '6000000',
				type => 'IPH',
				name => 'vbn',
			},
			ver  => '1.42',
			auth => {
				type => 'AID',
				aid  => 'kaoxIXLn' . '03zCr2KR',
			},
			lang => 'deu',
		},
	},
);

# }}}
# {{{ Constructors

sub new {
	my ( $obj, %conf ) = @_;
	my $service = $conf{service};

	my $ua = $conf{user_agent};

	if ( not $ua ) {
		my %lwp_options = %{ $conf{lwp_options} // { timeout => 10 } };
		$ua = LWP::UserAgent->new(%lwp_options);
		$ua->env_proxy;
	}

	if ( not( $conf{from_stop} and $conf{to_stop} ) ) {
		confess('from_stop and to_stop must be specified');
	}

	if ( not defined $service ) {
		$service = $conf{service} = 'DB';
	}

	if ( defined $service and not exists $hafas_instance{$service} ) {
		confess("The service '$service' is not supported");
	}

	my $now  = DateTime->now( time_zone => 'Europe/Berlin' );
	my $self = {
		active_service => $service,
		cache          => $conf{cache},
		developer_mode => $conf{developer_mode},
		exclusive_mots => $conf{exclusive_mots},
		excluded_mots  => $conf{excluded_mots},
		messages       => [],
		results        => [],
		from_stop      => $conf{from_stop},
		via_stops      => $conf{via_stops} // [],
		to_stop        => $conf{to_stop},
		ua             => $ua,
		now            => $now,
	};

	bless( $self, $obj );

	my $req;

	my $date    = ( $conf{datetime} // $now )->strftime('%Y%m%d');
	my $time    = ( $conf{datetime} // $now )->strftime('%H%M%S');
	my $outFrwd = $conf{arrival} ? \0 : undef;

	my @via_locs = map { $self->stop_to_hafas($_) } @{ $self->{via_stops} };

	$req = {
		svcReqL => [
			{
				meth => 'TripSearch',
				req  => {
					depLocL => [ $self->stop_to_hafas( $self->{from_stop} ) ],
					arrLocL => [ $self->stop_to_hafas( $self->{to_stop} ) ],
					numF    => 6,
					maxChg  => $conf{max_change},
					minChgTime => $conf{min_change_time},
					outFrwd    => $outFrwd,
					viaLocL    => @via_locs
					? [ map { { loc => $_ } } @via_locs ]
					: undef,
					trfReq => {
						cType    => 'PK',
						tvlrProf => [ { type => 'E' } ],
					},
					outDate  => $date,
					outTime  => $time,
					jnyFltrL => [
						{
							type  => "PROD",
							mode  => "INC",
							value => $self->mot_mask
						}
					]
				},
			},
		],
		%{ $hafas_instance{$service}{request} }
	};

	if ( $conf{language} ) {
		$req->{lang} = $conf{language};
	}

	$self->{strptime_obj} //= DateTime::Format::Strptime->new(
		pattern   => '%Y%m%dT%H%M%S',
		time_zone => 'Europe/Berlin',
	);

	my $json = $self->{json} = JSON->new->utf8;

	# The JSON request is the cache key, so if we have a cache we must ensure
	# that JSON serialization is deterministic.
	if ( $self->{cache} ) {
		$json->canonical;
	}

	$req = $json->encode($req);
	$self->{post} = $req;

	my $url = $conf{url} // $hafas_instance{$service}{mgate};

	if ( my $salt = $hafas_instance{$service}{salt} ) {
		if ( $hafas_instance{$service}{micmac} ) {
			my $mic = md5_hex( $self->{post} );
			my $mac = md5_hex( $mic . $salt );
			$url .= "?mic=$mic&mac=$mac";
		}
		else {
			$url .= '?checksum=' . md5_hex( $self->{post} . $salt );
		}
	}

	if ( $conf{async} ) {
		$self->{url} = $url;
		return $self;
	}

	if ( $conf{json} ) {
		$self->{raw_json} = $conf{json};
	}
	else {
		if ( $self->{developer_mode} ) {
			say "requesting $req from $url";
		}

		my ( $content, $error ) = $self->post_with_cache($url);

		if ($error) {
			$self->{errstr} = $error;
			return $self;
		}

		if ( $self->{developer_mode} ) {
			say decode( 'utf-8', $content );
		}

		$self->{raw_json} = $json->decode($content);
	}

	$self->check_mgate;
	$self->parse_trips;

	return $self;
}

sub new_p {
	my ( $obj, %conf ) = @_;
	my $promise = $conf{promise}->new;

	if ( not( $conf{from_stop} and $conf{to_stop} ) ) {
		confess('from_stop and to_stop must be specified');
		return $promise->reject('from_stop and to_stop must be specified');
	}

	my $self = $obj->new( %conf, async => 1 );
	$self->{promise} = $conf{promise};

	$self->post_with_cache_p( $self->{url} )->then(
		sub {
			my ($content) = @_;
			$self->{raw_json} = $self->{json}->decode($content);
			$self->check_mgate;
			$self->parse_trips;
			if ( $self->errstr ) {
				$promise->reject( $self->errstr, $self );
			}
			else {
				$promise->resolve($self);
			}
			return;
		}
	)->catch(
		sub {
			my ($err) = @_;
			$promise->reject($err);
			return;
		}
	)->wait;

	return $promise;
}

# }}}
# {{{ Internal Helpers

sub mot_mask {
	my ($self) = @_;

	my $service  = $self->{active_service};
	my $mot_mask = 2**@{ $hafas_instance{$service}{productbits} } - 1;

	my %mot_pos;
	for my $i ( 0 .. $#{ $hafas_instance{$service}{productbits} } ) {
		if ( ref( $hafas_instance{$service}{productbits}[$i] ) eq 'ARRAY' ) {
			$mot_pos{ $hafas_instance{$service}{productbits}[$i][0] } = $i;
		}
		else {
			$mot_pos{ $hafas_instance{$service}{productbits}[$i] } = $i;
		}
	}

	if ( my @mots = @{ $self->{exclusive_mots} // [] } ) {
		$mot_mask = 0;
		for my $mot (@mots) {
			$mot_mask |= 1 << $mot_pos{$mot};
		}
	}

	if ( my @mots = @{ $self->{excluded_mots} // [] } ) {
		for my $mot (@mots) {
			$mot_mask &= ~( 1 << $mot_pos{$mot} );
		}
	}

	return $mot_mask;
}

sub stop_to_hafas {
	my ( $self, $stop ) = @_;

	if ( $stop =~ m{ ^ [0-9]+ $ }x ) {
		return { lid => 'A=1@L=' . $stop . '@' };
	}
	else {
		return { lid => 'A=1@O=' . $stop . '@' };
	}
}

sub post_with_cache {
	my ( $self, $url ) = @_;
	my $cache = $self->{cache};

	if ( $self->{developer_mode} ) {
		say "POST $url";
	}

	if ($cache) {
		my $content = $cache->thaw( $self->{post} );
		if ($content) {
			if ( $self->{developer_mode} ) {
				say '  cache hit';
			}
			return ( ${$content}, undef );
		}
	}

	if ( $self->{developer_mode} ) {
		say '  cache miss';
	}

	my $reply = $self->{ua}->post(
		$url,
		'Content-Type' => 'application/json',
		Content        => $self->{post}
	);

	if ( $reply->is_error ) {
		return ( undef, $reply->status_line );
	}
	my $content = $reply->content;

	if ($cache) {
		$cache->freeze( $self->{post}, \$content );
	}

	return ( $content, undef );
}

sub post_with_cache_p {
	my ( $self, $url ) = @_;
	my $cache = $self->{cache};

	if ( $self->{developer_mode} ) {
		say "POST $url";
	}

	my $promise = $self->{promise}->new;

	if ($cache) {
		my $content = $cache->thaw( $self->{post} );
		if ($content) {
			if ( $self->{developer_mode} ) {
				say '  cache hit';
			}
			return $promise->resolve( ${$content} );
		}
	}

	if ( $self->{developer_mode} ) {
		say '  cache miss';
	}

	$self->{ua}->post_p( $url, $self->{post} )->then(
		sub {
			my ($tx) = @_;
			if ( my $err = $tx->error ) {
				$promise->reject(
					"POST $url returned HTTP $err->{code} $err->{message}");
				return;
			}
			my $content = $tx->res->body;
			if ($cache) {
				$cache->freeze( $self->{post}, \$content );
			}
			$promise->resolve($content);
			return;
		}
	)->catch(
		sub {
			my ($err) = @_;
			$promise->reject($err);
			return;
		}
	)->wait;

	return $promise;
}

sub check_mgate {
	my ($self) = @_;

	if ( $self->{raw_json}{err} and $self->{raw_json}{err} ne 'OK' ) {
		$self->{errstr} = $self->{raw_json}{errTxt}
		  // 'error code is ' . $self->{raw_json}{err};
		$self->{errcode} = $self->{raw_json}{err};
	}
	elsif ( defined $self->{raw_json}{cInfo}{code}
		and $self->{raw_json}{cInfo}{code} ne 'OK'
		and $self->{raw_json}{cInfo}{code} ne 'VH' )
	{
		$self->{errstr}  = 'cInfo code is ' . $self->{raw_json}{cInfo}{code};
		$self->{errcode} = $self->{raw_json}{cInfo}{code};
	}
	elsif ( @{ $self->{raw_json}{svcResL} // [] } == 0 ) {
		$self->{errstr} = 'svcResL is empty';
	}
	elsif ( $self->{raw_json}{svcResL}[0]{err} ne 'OK' ) {
		$self->{errstr}
		  = 'svcResL[0].err is ' . $self->{raw_json}{svcResL}[0]{err};
		$self->{errcode} = $self->{raw_json}{svcResL}[0]{err};
	}

	return $self;
}

sub parse_trips {
	my ($self) = @_;

	my $common = $self->{raw_json}{svcResL}[0]{res}{common};

	my @locL = map { Travel::Status::DE::HAFAS::Location->new( loc => $_ ) }
	  @{ $common->{locL} // [] };

	my @prodL = map {
		Travel::Status::DE::HAFAS::Product->new(
			common  => $common,
			product => $_
		)
	} @{ $common->{prodL} // [] };

	my @conL = @{ $self->{raw_json}{svcResL}[0]{res}{outConL} // [] };
	for my $con (@conL) {
		push(
			@{ $self->{results} },
			Travel::Routing::DE::HAFAS::Connection->new(
				common     => $self->{raw_json}{svcResL}[0]{res}{common},
				locL       => \@locL,
				prodL      => \@prodL,
				connection => $con,
				hafas      => $self,
			)
		);
	}
}

sub add_message {
	my ( $self, $json, $is_him ) = @_;

	my $text = $json->{txtN};
	my $code = $json->{code};

	if ($is_him) {
		$text = $json->{text};
		$code = $json->{hid};
	}

	# Some backends use remL for operator information. We don't want that.
	if ( $code eq 'OPERATOR' ) {
		return;
	}

	for my $message ( @{ $self->{messages} } ) {
		if ( $code eq $message->{code} and $text eq $message->{text} ) {
			$message->{ref_count}++;
			return $message;
		}
	}

	my $message = Travel::Status::DE::HAFAS::Message->new(
		json      => $json,
		ref_count => 1,
	);
	push( @{ $self->{messages} }, $message );
	return $message;
}

# }}}
# {{{ Public Functions

sub errcode {
	my ($self) = @_;

	return $self->{errcode};
}

sub errstr {
	my ($self) = @_;

	return $self->{errstr};
}

sub messages {
	my ($self) = @_;
	return @{ $self->{messages} };
}

sub connections {
	my ($self) = @_;
	return @{ $self->{results} };
}

# static
sub get_services {
	my @services;
	for my $service ( sort keys %hafas_instance ) {
		my %desc = %{ $hafas_instance{$service} };
		$desc{shortname} = $service;
		push( @services, \%desc );
	}
	return @services;
}

# static
sub get_service {
	my ($service) = @_;

	if ( defined $service and exists $hafas_instance{$service} ) {
		return $hafas_instance{$service};
	}
	return;
}

sub get_active_service {
	my ($self) = @_;

	if ( defined $self->{active_service} ) {
		return $hafas_instance{ $self->{active_service} };
	}
	return;
}

# }}}

1;

__END__

=head1 NAME

Travel::Routing::DE::HAFAS - Interface to HAFAS itinerary services

=head1 SYNOPSIS

	use Travel::Routing::DE::HAFAS;

	my $hafas = Travel::Routing::DE::HAFAS->new(
		from_stop => 'Eichlinghofen H-Bahn, Dortmund',
		to_stop => 'Essen-Kupferdreh',
	);

	if (my $err = $hafas->errstr) {
		die("Request error: ${err}\n");
	}

	for my $con ( $hafas->connections ) {
		for my $sec ($con->sections) {
			if ( $sec->type eq 'JNY' ) {
				printf("%s -> %s\n%s ab %s\n%s an %s\n\n",
					$sec->journey->name,
					$sec->journey->direction,
					$sec->dep->strftime('%H:%M'),
					$sec->dep_loc->name,
					$sec->arr->strftime('%H:%M'),
					$sec->arr_loc->name,
				);
			}
		}
		print "\n\n";
	}

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Travel::Routing::DE::HAFAS is an interface to HAFAS itinerary services
using the mgate.exe interface. It works best with the legacy instance of
Deutsche Bahn, but supports other transit services as well.

=head1 METHODS

=over

=item $hafas = Travel::Routing::DE::HAFAS->new(I<%opt>)

Request connections as specified by I<%opt> and return a new
Travel::Routing::DE::HAFAS instance with the results. Dies if the wrong
I<%opt> were passed. I<%opt> must contain B<from_stop> and B<to_stop> and
supports the following additional flags:

=over

=item B<from_stop> => I<stop> (mandatory)

Origin stop, e.g. "Essen HBf" or "Alfredusbad, Essen (Ruhr)". The stop
must be specified either by name or by EVA ID (e.g. 8000080 for Dortmund Hbf).

=item B<to_stop> => I<stop> (mandatory)

Destination stop, e.g. "Essen HBf" or "Alfredusbad, Essen (Ruhr)". The stop
must be specified either by name or by EVA ID (e.g. 8000080 for Dortmund Hbf).

=item B<via_stops> => [I<stop1>, I<stop2>, ...]

Only return connections that pass all specified stops. Individual stops are
identified by name or by EVA ID (e.g. 8000080 for Dortmund Hbf).

=item B<arrival> => I<bool>

If true: request connections that arrive at the destination before the
specified time. If false (default): request connections that leave at the
origin after the specified time.

=item B<cache> => I<Cache::File object>

Store HAFAS replies in the provided cache object.  This module works with
real-time data, so the object should be configured for an expiry of one to two
minutes.

=item B<datetime> => I<DateTime object>

Date and time for itinerary request.  Defaults to now.

=item B<excluded_mots> => [I<mot1>, I<mot2>, ...]

By default, all modes of transport (trains, trams, buses etc.) are considered.
If this option is set, all modes appearing in I<mot1>, I<mot2>, ... will
be excluded. The supported modes depend on B<service>, use
B<get_services> or B<get_service> to get the supported values.

=item B<exclusive_mots> => [I<mot1>, I<mot2>, ...]

If this option is set, only the modes of transport appearing in I<mot1>,
I<mot2>, ...  will be considered.  The supported modes depend on B<service>,
use B<get_services> or B<get_service> to get the supported values.

=item B<language> => I<language>

Request text messages to be provided in I<language>. Supported languages depend
on B<service>, use B<get_services> or B<get_service> to get the supported
values. Providing an unsupported or invalid value may lead to garbage output.

=item B<lwp_options> => I<\%hashref>

Passed on to C<< LWP::UserAgent->new >>. Defaults to C<< { timeout => 10 } >>,
pass an empty hashref to call the LWP::UserAgent constructor without arguments.

=item B<max_change> => I<count>

Request connections with no more than I<count> changeovers.

=item B<min_change_time> => I<minutes>

Request connections with scheduled changeover durations of at least I<minutes>.
Note that this does not account for real-time data: the backend may return
delayed connections that violate the specified changeover duration.

=item B<service> => I<service>

Request results from I<service>, defaults to "DB".
See B<get_services> (and C<< hafas-m --list >>) for a list of supported
services.

=back

=item $hafas_p = Travel::Routing::DE::HAFAS->new_p(I<%opt>)

Return a promise that resolves into a Travel::Routing::DE::HAFAS instance
($hafas) on success and rejects with an error message on failure. If the
failure occured after receiving a response from the HAFAS backend, the rejected
promise contains a Travel::Routing::DE::HAFAS instance as a second argument.
In addition to the arguments of B<new>, the following mandatory arguments must
be set.

=over

=item B<promise> => I<promises module>

Promises implementation to use for internal promises as well as B<new_p> return
value.  Recommended: Mojo::Promise(3pm).

=item B<user_agent> => I<user agent>

User agent instance to use for asynchronous requests. The object must implement
a B<post_p> function. Recommended: Mojo::UserAgent(3pm).

=back

=item $hafas->errcode

In case of an error in the HAFAS backend, returns the corresponding error code
as string. If no backend error occurred, returns undef.

=item $hafas->errstr

In case of an error in the HTTP request or HAFAS backend, returns a string
describing it.  If no error occurred, returns undef.

=item $hafas->connections

Returns a list of Travel::Routing::DE::HAFAS::Connection(3pm) objects, each of
which describes a single connection from I<origin> to I<destination>.

Returns a false value if no connections were found or the parser / http request
failed.

=item $hafas->messages

Returns a list of Travel::Status::DE::HAFAS::Message(3pm) objects with service
messages. Each message belongs to at least one connection, connection section,
or stop along a section's journey.

=item $hafas->get_active_service

Returns a hashref describing the active service when a service is active and
nothing otherwise. The hashref contains the keys B<url> (URL to the station
board service), and B<productbits> (arrayref describing the supported modes of
transport, may contain duplicates).

=item Travel::Routing::DE::HAFAS::get_services()

Returns an array containing all supported HAFAS services. Each element is a
hashref and contains all keys mentioned in B<get_active_service>.
It also contains a B<shortname> key, which is the service name used by
the constructor's B<service> parameter.

=item Travel::Routing::DE::HAFAS::get_service(I<$service>)

Returns a hashref describing the service I<$service>. Returns nothing if
I<$service> is not supported. See B<get_active_service> for the hashref layout.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item * Class::Accessor(3pm)

=item * DateTime(3pm)

=item * DateTime::Format::Strptime(3pm)

=item * LWP::UserAgent(3pm)

=item * Travel::Status::DE::HAFAS::Message(3pm)

=back

=head1 BUGS AND LIMITATIONS

The non-default services (anything other than DB) are not well tested.

=head1 SEE ALSO

Travel::Routing::DE::HAFAS::Connection(3pm)

=head1 AUTHOR

Copyright (C) 2023 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
