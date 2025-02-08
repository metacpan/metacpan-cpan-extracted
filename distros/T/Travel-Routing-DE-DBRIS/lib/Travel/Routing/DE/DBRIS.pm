package Travel::Routing::DE::DBRIS;

# vim:foldmethod=marker

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';

use DateTime;
use DateTime::Format::Strptime;
use Encode qw(decode encode);
use JSON;
use LWP::UserAgent;
use Travel::Status::DE::DBRIS;
use Travel::Routing::DE::DBRIS::Connection;
use Travel::Routing::DE::DBRIS::Offer;

our $VERSION = '0.04';

Travel::Routing::DE::DBRIS->mk_ro_accessors(qw(earlier later));

my %passenger_type_map = (
	adult  => 'ERWACHSENER',
	junior => 'JUGENDLICHER',
	senior => 'SENIOR',
);

# {{{ Constructors

sub new {
	my ( $obj, %conf ) = @_;

	my $ua = $conf{user_agent};

	if ( not $ua ) {
		my %lwp_options = %{ $conf{lwp_options} // { timeout => 10 } };
		$ua = LWP::UserAgent->new(%lwp_options);
		$ua->env_proxy;
	}

	# Supported Languages: de cs da en es fr it nl pl

	my $self = {
		cache          => $conf{cache},
		developer_mode => $conf{developer_mode},
		from           => $conf{from},
		to             => $conf{to},
		language       => $conf{language} // 'de',
		ua             => $ua,
	};

	bless( $self, $obj );

	my $dt = $conf{datetime} // DateTime->now( time_zone => 'Europe/Berlin' );
	my @mots
	  = (qw(ICE EC_IC IR REGIONAL SBAHN BUS SCHIFF UBAHN TRAM ANRUFPFLICHTIG));
	if ( $conf{modes_of_transit} ) {
		@mots = @{ $conf{modes_of_transit} // [] };
	}

	my ($req_url, $req);

	if ($conf{from} and $conf{to}) {
		$req_url
		= $self->{language} eq 'de'
		? 'https://www.bahn.de/web/api/angebote/fahrplan'
		: 'https://int.bahn.de/web/api/angebote/fahrplan';
		$req = {
			abfahrtsHalt     => $conf{from}->id,
			ankunftsHalt     => $conf{to}->id,
			anfrageZeitpunkt => $dt->strftime('%Y-%m-%dT%H:%M:00'),
			ankunftSuche     => $conf{arrival}     ? 'ANKUNFT'  : 'ABFAHRT',
			klasse           => $conf{first_class} ? 'KLASSE_1' : 'KLASSE_2',
			produktgattungen => \@mots,
			reisende         => [
				{
					typ            => 'ERWACHSENER',
					ermaessigungen => [
						{
							art    => 'KEINE_ERMAESSIGUNG',
							klasse => 'KLASSENLOS'
						},
					],
					alter  => [],
					anzahl => 1,
				}
			],
			schnelleVerbindungen              => \1,
			sitzplatzOnly                     => \0,
			bikeCarriage                      => \0,
			reservierungsKontingenteVorhanden => \0,
			nurDeutschlandTicketVerbindungen  => \0,
			deutschlandTicketVorhanden        => \0
		};
	}
	elsif ($conf{offers}) {
		$req_url
		= $self->{language} eq 'de'
		? 'https://www.bahn.de/web/api/angebote/recon'
		: 'https://int.bahn.de/web/api/angebote/recon';
		$req = {
			klasse           => $conf{first_class} ? 'KLASSE_1' : 'KLASSE_2',
			ctxRecon => $conf{offers}{recon},
			reisende         => [
				{
					typ            => 'ERWACHSENER',
					ermaessigungen => [
						{
							art    => 'KEINE_ERMAESSIGUNG',
							klasse => 'KLASSENLOS'
						},
					],
					alter  => [],
					anzahl => 1,
				}
			],
			reservierungsKontingenteVorhanden => \0,
			nurDeutschlandTicketVerbindungen  => \0,
			deutschlandTicketVorhanden        => \0
		};
	}

	for my $via ( @{ $conf{via} } ) {
		my $via_stop = { id => $via->{stop}->id };
		if ( $via->{duration} ) {
			$via_stop->{aufenthaltsdauer} = 0 + $via->{duration};
		}
		push( @{ $req->{zwischenhalte} }, $via_stop );
	}

	if ( @{ $conf{passengers} // [] } ) {
		$req->{reisende} = [];
	}

	for my $passenger ( @{ $conf{passengers} // [] } ) {
		if ( not $passenger_type_map{ $passenger->{type} } ) {
			die("Unknown passenger type: '$passenger->{type}'");
		}
		my $entry = {
			typ    => $passenger_type_map{ $passenger->{type} },
			alter  => [],
			anzahl => 1
		};
		for my $discount ( @{ $passenger->{discounts} // [] } ) {
			my ( $type, $class );
			for my $num (qw(25 50 100)) {
				if ( $discount eq "bc${num}" ) {
					$type  = "BAHNCARD${num}";
					$class = 'KLASSE_2';
				}
				elsif ( $discount eq "bc${num}-first" ) {
					$type  = "BAHNCARD${num}";
					$class = 'KLASSE_1';
				}
			}
			if ($type) {
				push(
					@{ $entry->{ermaessigungen} },
					{
						art    => $type,
						klasse => $class,
					}
				);
			}
		}
		if ( not @{ $entry->{ermaessigungen} // [] } ) {
			$entry->{ermaessigungen} = [
				{
					art    => 'KEINE_ERMAESSIGUNG',
					klasse => 'KLASSENLOS'
				}
			];
		}
		push( @{ $req->{reisende} }, $entry );
	}

	$self->{strptime_obj} //= DateTime::Format::Strptime->new(
		pattern   => '%Y-%m-%dT%H:%M:%S',
		time_zone => 'Europe/Berlin',
	);

	$self->{strpdate_obj} //= DateTime::Format::Strptime->new(
		pattern   => '%Y-%m-%d',
		time_zone => 'Europe/Berlin',
	);

	my $json = $self->{json} = JSON->new->utf8->canonical;

	if ( $conf{async} ) {
		$self->{req} = $req;
		return $self;
	}

	if ( $conf{json} ) {
		$self->{raw_json} = $conf{json};
	}
	else {
		my $req_str = $json->encode($req);
		if ( $self->{developer_mode} ) {
			say "requesting $req_str";
		}

		my ( $content, $error ) = $self->post_with_cache( $req_url, $req_str );

		if ($error) {
			$self->{errstr} = $error;
			return $self;
		}

		if ( $self->{developer_mode} ) {
			say decode( 'utf-8', $content );
		}

		$self->{raw_json} = $json->decode($content);
		if ($conf{from} and $conf{to}) {
			$self->parse_connections;
		}
		elsif ($conf{offers}) {
			$self->parse_offers;
		}
	}

	return $self;
}

sub new_p {
	my ( $obj, %conf ) = @_;
	my $promise = $conf{promise}->new;

	if (
		not(    $conf{from}
			and $conf{to} )
	  )
	{
		return $promise->reject('"from" and "to" opts are mandatory');
	}

	my $self = $obj->new( %conf, async => 1 );
	$self->{promise} = $conf{promise};

	$self->post_with_cache_p( $self->{url} )->then(
		sub {
			my ($content) = @_;
			$self->{raw_json} = $self->{json}->decode($content);
			$self->parse_connections;
			$promise->resolve($self);
			return;
		}
	)->catch(
		sub {
			my ($err) = @_;
			$promise->reject( $err, $self );
			return;
		}
	)->wait;

	return $promise;
}

# }}}
# {{{ Internal Helpers

sub post_with_cache {
	my ( $self, $url, $req ) = @_;
	my $cache = $self->{cache};

	if ( $self->{developer_mode} ) {
		say "POST $url $req";
	}

	if ($cache) {
		my $content = $cache->thaw("$url $req");
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
		Accept            => 'application/json',
		'Accept-Language' => $self->{language},
		'Content-Type'    => 'application/json; charset=utf-8',
		Content           => $req,
	);

	if ( $reply->is_error ) {
		return ( undef, $reply->status_line );
	}
	my $content = $reply->content;

	if ($cache) {
		$cache->freeze( "$url $req", \$content );
	}

	return ( $content, undef );
}

sub post_with_cache_p {
	...;
}

sub parse_connections {
	my ($self) = @_;

	my $json = $self->{raw_json};

	$self->{earlier} = $json->{verbindungReference}{earlier};
	$self->{later}   = $json->{verbindungReference}{later};

	for my $connection ( @{ $json->{verbindungen} // [] } ) {
		push(
			@{ $self->{connections} },
			Travel::Routing::DE::DBRIS::Connection->new(
				json         => $connection,
				strpdate_obj => $self->{strpdate_obj},
				strptime_obj => $self->{strptime_obj}
			)
		);
	}
}

sub parse_offers {
	my ($self) = @_;

	for my $offer (@{$self->{raw_json}{verbindungen}[0]{reiseAngebote} // []}) {
		push(@{$self->{offers}}, Travel::Routing::DE::DBRIS::Offer->new(
			json => $offer
		));
	}
}

# }}}
# {{{ Public Functions

sub errstr {
	my ($self) = @_;

	return $self->{errstr};
}

sub connections {
	my ($self) = @_;
	return @{ $self->{connections} // []};
}

sub offers {
	my ($self) = @_;
	return @{$self->{offers} // [] };
}

# }}}

1;

__END__

=head1 NAME

Travel::Routing::DE::DBRIS - Interface to the bahn.de itinerary service

=head1 SYNOPSIS

	use Travel::Routing::DE::DBRIS;

	# use Travel::Status::DE::DBRIS to obtain $from and $to objects
	# (must be Travel::Status::DE::DBRIS::Location instances)

	my $ris = Travel::Routing::DE::DBRIS->new(
		from => $from_location,
		to => $to_location,
	);

	if (my $err = $ris->errstr) {
		die("Request error: ${err}\n");
	}

	for my $con ( $ris->connections ) {
		for my $seg ($con->segments) {
			if ( not ($seg->is_transfer or $seg->is_walk) ) {
				printf("%s -> %s\n%s ab %s\n%s an %s\n\n",
					$seg->train_mid,
					$seg->direction,
					$seg->dep->strftime('%H:%M'),
					$seg->dep_name,
					$seg->arr->strftime('%H:%M'),
					$seg->arr_name,
				);
			}
		}
		print "\n\n";
	}

=head1 VERSION

version 0.04

=head1 DESCRIPTION

Travel::Routing::DE::DBRIS is an interface to the bahn.de itinerary service.

=head1 METHODS

=over

=item $ris = Travel::Routing::DE::DBRIS->new(I<%opt>)

Request connections as specified by I<%opt> and return a new
Travel::Routing::DE::DBRIS instance with the results. Dies if the wrong I<%opt>
were passed. The B<origin> and B<destination> keys are mandatory.

=over

=item B<origin> => I<stop> (mandatory)

A Travel::Status::DE::DBRIS::Location(3pm) instance describing the origin of
the requested itinerary.

=item B<destination> => I<stop> (mandatory)

A Travel::Status::DE::DBRIS::Location(3pm) instance describing the destination
of the requested itinerary.

=item B<via> => I<arrayref>

An arrayref containing up to two hashrefs that describe stopovers which must
be part of the requested itinerary. Each hashref consists of two keys:
B<stop> (Travel::Status::DE::DBRIS::Location(3pm) object, mandatory) and
B<duration> (stopover duration in minutes, optional, default: 0).

=item B<cache> => I<cache>

A Cache::File(3pm) instance used for caching bahn.de requests.

=item B<datetime> => I<datetime>

Request departures on or after I<datetime> (DateTime(3pm) instance).
Default: now.

=item B<language> => I<lang>

Request text components to be provided in I<lang> (ISO 639-1 language code).
Known supported languages are: cs da de en es fr it nl pl.
Default: de.

=item B<modes_of_transit> => I<arrayref>

Only request connections using the modes of transit specified in I<arrayref>.
Default: ICE, EC_IC, IR, REGIONAL, SBAHN, BUS, SCHIFF, UBAHN, TRAM, ANRUFPFLICHTIG.

=item B<passengers> => I<arrayref>

Use passengers as defined by I<arrayref> when determining offer prices.  Each
entry describes a single person with a B<type> (string) and B<discounts>
(arrayref). B<type> must be B<adult> (27 to 64 years old), B<junior> (15 to 26
years old), or B<senior> (65 years or older). Supported discounts are: bc25,
bc25-first, bc50, bc50-first, bc100, bc100-first.

Default: single adult, no discounts.

=item B<user_agent> => I<user agent>

Use I<user agent> for requests.
Default: A new LWP::UserAgent(3pm) object with env_proxy enabled and a timeout
of ten seconds.

=item B<lwp_options> => I<hashref>

Pass I<hashref> to C<< LWP::UserAgent->new >>.
Default: C<< { timeout => 10 } >>.

=back

=item $ris->errstr

Returns a string describing a HTTP or bahn.de error, if any such error occured.
Returns undef otherwise.

=item $ris->connections

Returns a list of Travel::Routing::DE::DBRIS::Connection(3pm) objects, each of
which describes a singre connction from I<origin> to I<destination>.

=back

=head1 DIAGNOSTICS

when the B<developer_mode> argument to B<new> is set to a true value,
Travel::Routing::DE::DBRIS prints raw bahn.de requests and responses to stdout.

None.

=head1 DEPENDENCIES

=over

=item * Class::Accessor(3pm)

=item * DateTime(3pm)

=item * DateTime::Format::Strptime(3pm)

=item * LWP::UserAgent(3pm)

=item * Travel::Status::DE::DBRIS(3pm)

=back

=head1 BUGS AND LIMITATIONS

This module is very much work-in-progress.

=head1 SEE ALSO

Travel::Routing::DE::DBRIS::Connection(3pm)

=head1 AUTHOR

Copyright (C) 2025 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
