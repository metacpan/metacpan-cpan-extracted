package Travel::Status::DE::EFA;

use strict;
use warnings;
use 5.010;
use utf8;

no if $] >= 5.018, warnings => 'experimental::smartmatch';

our $VERSION = '1.17';

use Carp qw(confess cluck);
use Encode qw(encode);
use Travel::Status::DE::EFA::Line;
use Travel::Status::DE::EFA::Result;
use Travel::Status::DE::EFA::Stop;
use LWP::UserAgent;
use XML::LibXML;

sub new {
	my ( $class, %opt ) = @_;

	$opt{timeout} //= 10;
	if ( $opt{timeout} <= 0 ) {
		delete $opt{timeout};
	}

	my $ua  = LWP::UserAgent->new(%opt);
	my @now = localtime( time() );

	my @time = @now[ 2, 1 ];
	my @date = ( $now[3], $now[4] + 1, $now[5] + 1900 );

	if ( not( $opt{place} and $opt{name} ) ) {
		confess('You need to specify a place and a name');
	}
	if ( $opt{type} and not( $opt{type} ~~ [qw[stop address poi]] ) ) {
		confess('type must be stop, address or poi');
	}

	if ( not $opt{efa_url} ) {
		confess('efa_url is mandatory');
	}

	## no critic (RegularExpressions::ProhibitUnusedCapture)
	## no critic (Variables::ProhibitPunctuationVars)

	if (    $opt{time}
		and $opt{time} =~ m{ ^ (?<hour> \d\d? ) : (?<minute> \d\d ) $ }x )
	{
		@time = @+{qw{hour minute}};
	}
	elsif ( $opt{time} ) {
		confess('Invalid time specified');
	}

	if (
		    $opt{date}
		and $opt{date} =~ m{ ^ (?<day> \d\d? ) [.] (?<month> \d\d? ) [.]
			(?<year> \d{4} )? $ }x
	  )
	{
		if ( $+{year} ) {
			@date = @+{qw{day month year}};
		}
		else {
			@date[ 0, 1 ] = @+{qw{day month}};
		}
	}
	elsif ( $opt{date} ) {
		confess('Invalid date specified');
	}

	my $self = {
		post => {
			command                => q{},
			deleteAssignedStops_dm => '1',
			help                   => 'Hilfe',
			itdDateDay             => $date[0],
			itdDateMonth           => $date[1],
			itdDateYear            => $date[2],
			itdLPxx_id_dm          => ':dm',
			itdLPxx_mapState_dm    => q{},
			itdLPxx_mdvMap2_dm     => q{},
			itdLPxx_mdvMap_dm      => '3406199:401077:NAV3',
			itdLPxx_transpCompany  => 'vrr',
			itdLPxx_view           => q{},
			itdTimeHour            => $time[0],
			itdTimeMinute          => $time[1],
			language               => 'de',
			mode                   => 'direct',
			nameInfo_dm            => 'invalid',
			nameState_dm           => 'empty',
			name_dm                => encode( 'UTF-8', $opt{name} ),
			outputFormat           => 'XML',
			placeInfo_dm           => 'invalid',
			placeState_dm          => 'empty',
			place_dm               => encode( 'UTF-8', $opt{place} ),
			ptOptionsActive        => '1',
			requestID              => '0',
			reset                  => 'neue Anfrage',
			sessionID              => '0',
			submitButton           => 'anfordern',
			typeInfo_dm            => 'invalid',
			type_dm                => $opt{type} // 'stop',
			useProxFootSearch      => '0',
			useRealtime            => '1',
		},
		developer_mode => $opt{developer_mode},
	};

	if ( $opt{full_routes} ) {
		$self->{post}->{depType}                = 'stopEvents';
		$self->{post}->{includeCompleteStopSeq} = 1;
		$self->{want_full_routes}               = 1;
	}

	bless( $self, $class );

	$ua->env_proxy;

	my $response = $ua->post( $opt{efa_url}, $self->{post} );

	if ( $response->is_error ) {
		$self->{errstr} = $response->status_line;
		return $self;
	}

	if ( $opt{efa_encoding} ) {
		$self->{xml} = encode( $opt{efa_encoding}, $response->content );
	}
	else {
		$self->{xml} = $response->decoded_content;
	}

	if ( not $self->{xml} ) {

		# LibXML doesn't like empty documents
		$self->{errstr} = 'Server returned nothing (empty result)';
		return $self;
	}

	$self->{tree} = XML::LibXML->load_xml(
		string => $self->{xml},
	);

	if ( $self->{developer_mode} ) {
		say $self->{tree}->toString(1);
	}

	$self->check_for_ambiguous();

	return $self;
}

sub new_from_xml {
	my ( $class, %opt ) = @_;

	my $self = {
		xml => $opt{xml},
	};

	$self->{tree} = XML::LibXML->load_xml(
		string => $self->{xml},
	);

	return bless( $self, $class );
}

sub errstr {
	my ($self) = @_;

	return $self->{errstr};
}

sub name_candidates {
	my ($self) = @_;

	if ( $self->{name_candidates} ) {
		return @{ $self->{name_candidates} };
	}
	return;
}

sub place_candidates {
	my ($self) = @_;

	if ( $self->{place_candidates} ) {
		return @{ $self->{place_candidates} };
	}
	return;
}

sub sprintf_date {
	my ($e) = @_;

	if ( $e->getAttribute('day') == -1 ) {
		return;
	}

	return sprintf( '%02d.%02d.%d',
		$e->getAttribute('day'),
		$e->getAttribute('month'),
		$e->getAttribute('year'),
	);
}

sub sprintf_time {
	my ($e) = @_;

	if ( $e->getAttribute('minute') == -1 ) {
		return;
	}

	return sprintf( '%02d:%02d',
		$e->getAttribute('hour'),
		$e->getAttribute('minute'),
	);
}

sub check_for_ambiguous {
	my ($self) = @_;

	my $xml = $self->{tree};

	my $xp_place = XML::LibXML::XPathExpression->new('//itdOdv/itdOdvPlace');
	my $xp_name  = XML::LibXML::XPathExpression->new('//itdOdv/itdOdvName');
	my $xp_mesg
	  = XML::LibXML::XPathExpression->new('//itdMessage[@type="error"]');

	my $xp_place_elem = XML::LibXML::XPathExpression->new('./odvPlaceElem');
	my $xp_name_elem  = XML::LibXML::XPathExpression->new('./odvNameElem');

	my $e_place = ( $xml->findnodes($xp_place) )[0];
	my $e_name  = ( $xml->findnodes($xp_name) )[0];
	my @e_mesg  = $xml->findnodes($xp_mesg);

	if ( not( $e_place and $e_name ) ) {

		# this should not happen[tm]
		cluck('skipping ambiguity check- itdOdvPlace/itdOdvName missing');
		return;
	}

	my $s_place = $e_place->getAttribute('state');
	my $s_name  = $e_name->getAttribute('state');

	if ( $s_place eq 'list' ) {
		$self->{place_candidates} = [ map { $_->textContent }
			  @{ $e_place->findnodes($xp_place_elem) } ];
		$self->{errstr} = 'ambiguous place parameter';
		return;
	}
	if ( $s_name eq 'list' ) {
		$self->{name_candidates}
		  = [ map { $_->textContent } @{ $e_name->findnodes($xp_name_elem) } ];

		$self->{errstr} = 'ambiguous name parameter';
		return;
	}
	if ( $s_place eq 'notidentified' ) {
		$self->{errstr} = 'invalid place parameter';
		return;
	}
	if ( $s_name eq 'notidentified' ) {
		$self->{errstr} = 'invalid name parameter';
		return;
	}
	if (@e_mesg) {
		$self->{errstr} = join( q{; }, map { $_->textContent } @e_mesg );
		return;
	}

	return;
}

sub identified_data {
	my ($self) = @_;

	if ( not $self->{tree} ) {
		return;
	}

	my $xp_place
	  = XML::LibXML::XPathExpression->new('//itdOdv/itdOdvPlace/odvPlaceElem');
	my $xp_name
	  = XML::LibXML::XPathExpression->new('//itdOdv/itdOdvName/odvNameElem');

	my $e_place = ( $self->{tree}->findnodes($xp_place) )[0];
	my $e_name  = ( $self->{tree}->findnodes($xp_name) )[0];

	return ( $e_place->textContent, $e_name->textContent );
}

sub lines {
	my ($self) = @_;
	my @lines;

	if ( $self->{lines} ) {
		return @{ $self->{lines} };
	}

	if ( not $self->{tree} ) {
		return;
	}

	my $xp_element
	  = XML::LibXML::XPathExpression->new('//itdServingLines/itdServingLine');

	my $xp_info  = XML::LibXML::XPathExpression->new('./itdNoTrain');
	my $xp_route = XML::LibXML::XPathExpression->new('./itdRouteDescText');
	my $xp_oper  = XML::LibXML::XPathExpression->new('./itdOperator/name');

	for my $e ( $self->{tree}->findnodes($xp_element) ) {

		my $e_info  = ( $e->findnodes($xp_info) )[0];
		my $e_route = ( $e->findnodes($xp_route) )[0];
		my $e_oper  = ( $e->findnodes($xp_oper) )[0];

		if ( not($e_info) ) {
			cluck( 'node with insufficient data. This should not happen. '
				  . $e->getAttribute('number') );
			next;
		}

		my $line       = $e->getAttribute('number');
		my $direction  = $e->getAttribute('direction');
		my $valid      = $e->getAttribute('valid');
		my $type       = $e_info->getAttribute('name');
		my $mot        = $e->getAttribute('motType');
		my $route      = ( $e_route ? $e_route->textContent : undef );
		my $operator   = ( $e_oper ? $e_oper->textContent : undef );
		my $identifier = $e->getAttribute('stateless');

		push(
			@lines,
			Travel::Status::DE::EFA::Line->new(
				name       => $line,
				direction  => $direction,
				valid      => $valid,
				type       => $type,
				mot        => $mot,
				route      => $route,
				operator   => $operator,
				identifier => $identifier,
			)
		);
	}

	$self->{lines} = \@lines;

	return @lines;
}

sub parse_route {
	my ( $self, @nodes ) = @_;
	my $xp_routepoint_date
	  = XML::LibXML::XPathExpression->new('./itdDateTime/itdDate');
	my $xp_routepoint_time
	  = XML::LibXML::XPathExpression->new('./itdDateTime/itdTime');

	my @ret;

	for my $e (@nodes) {
		my @dates = $e->findnodes($xp_routepoint_date);
		my @times = $e->findnodes($xp_routepoint_time);

		# note that the first stop has an arrival node with an invalid
		# timestamp and the terminal stop has a departure node with an
		# invalid timestamp.  sprintf_{date,time} return undef in these
		# cases.
		push(
			@ret,
			Travel::Status::DE::EFA::Stop->new(
				arr_date => sprintf_date( $dates[0] ),
				arr_time => sprintf_time( $times[0] ),
				dep_date => sprintf_date( $dates[-1] ),
				dep_time => sprintf_time( $times[-1] ),
				name     => $e->getAttribute('name'),
				name_suf => $e->getAttribute('nameWO'),
				platform => $e->getAttribute('platformName'),
			)
		);
	}

	return @ret;
}

sub results {
	my ($self) = @_;
	my @results;

	if ( $self->{results} ) {
		return @{ $self->{results} };
	}

	if ( not $self->{tree} ) {
		return;
	}

	my $xp_element = XML::LibXML::XPathExpression->new('//itdDeparture');

	my $xp_date  = XML::LibXML::XPathExpression->new('./itdDateTime/itdDate');
	my $xp_time  = XML::LibXML::XPathExpression->new('./itdDateTime/itdTime');
	my $xp_rdate = XML::LibXML::XPathExpression->new('./itdRTDateTime/itdDate');
	my $xp_rtime = XML::LibXML::XPathExpression->new('./itdRTDateTime/itdTime');
	my $xp_line  = XML::LibXML::XPathExpression->new('./itdServingLine');
	my $xp_info
	  = XML::LibXML::XPathExpression->new('./itdServingLine/itdNoTrain');
	my $xp_prev_route
	  = XML::LibXML::XPathExpression->new('./itdPrevStopSeq/itdPoint');
	my $xp_next_route
	  = XML::LibXML::XPathExpression->new('./itdOnwardStopSeq/itdPoint');

	$self->lines;

	for my $e ( $self->{tree}->findnodes($xp_element) ) {

		my $e_date = ( $e->findnodes($xp_date) )[0];
		my $e_time = ( $e->findnodes($xp_time) )[0];
		my $e_line = ( $e->findnodes($xp_line) )[0];
		my $e_info = ( $e->findnodes($xp_info) )[0];

		my $e_rdate = ( $e->findnodes($xp_rdate) )[0];
		my $e_rtime = ( $e->findnodes($xp_rtime) )[0];

		if ( not( $e_date and $e_time and $e_line ) ) {
			cluck('node with insufficient data. This should not happen');
			next;
		}

		my $date = sprintf_date($e_date);
		my $time = sprintf_time($e_time);

		my $rdate = $e_rdate ? sprintf_date($e_rdate) : $date;
		my $rtime = $e_rtime ? sprintf_time($e_rtime) : $time;

		my $platform      = $e->getAttribute('platform');
		my $platform_name = $e->getAttribute('platformName');
		my $line          = $e_line->getAttribute('number');
		my $dest          = $e_line->getAttribute('direction');
		my $info          = $e_info->textContent;
		my $key           = $e_line->getAttribute('key');
		my $countdown     = $e->getAttribute('countdown');
		my $delay         = $e_info->getAttribute('delay');
		my $type          = $e_info->getAttribute('name');
		my $mot           = $e_line->getAttribute('motType');

		my $platform_is_db = 0;

		my @prev_route;
		my @next_route;

		if ( $self->{want_full_routes} ) {
			@prev_route
			  = $self->parse_route( @{ [ $e->findnodes($xp_prev_route) ] } );
			@next_route
			  = $self->parse_route( @{ [ $e->findnodes($xp_next_route) ] } );
		}

		my @line_obj
		  = grep { $_->{identifier} eq $e_line->getAttribute('stateless') }
		  @{ $self->{lines} };

		# platform / platformName are inconsistent. The following cases are
		# known:
		#
		# * platform="int", platformName="" : non-DB platform
		# * platform="int", platformName="Bstg. int" : non-DB platform
		# * platform="#int", platformName="Gleis int" : non-DB platform
		# * platform="#int", platformName="Gleis int" : DB platform?
		# * platform="", platformName="Gleis int" : DB platform
		# * platform="DB", platformName="Gleis int" : DB platform
		# * platform="gibberish", platformName="Gleis int" : DB platform

		if ( ( $platform_name and $platform_name =~ m{ ^ Gleis }ox )
			and not( $platform and $platform =~ s{ ^ \# }{}ox ) )
		{
			$platform_is_db = 1;
		}

		if ( $platform_name and $platform_name =~ m{ ^ (Gleis | Bstg[.])}ox ) {
			$platform = ( split( / /, $platform_name ) )[1];
		}
		elsif ( $platform_name and not $platform ) {
			$platform = $platform_name;
		}

		push(
			@results,
			Travel::Status::DE::EFA::Result->new(
				date          => $rdate,
				time          => $rtime,
				platform      => $platform,
				platform_db   => $platform_is_db,
				platform_name => $platform_name,
				key           => $key,
				lineref       => $line_obj[0] // undef,
				line          => $line,
				destination   => $dest,
				countdown     => $countdown,
				info          => $info,
				delay         => $delay,
				sched_date    => $date,
				sched_time    => $time,
				type          => $type,
				mot           => $mot,
				prev_route    => \@prev_route,
				next_route    => \@next_route,
			)
		);
	}

	@results = map { $_->[0] }
	  sort { $a->[1] <=> $b->[1] }
	  map { [ $_, $_->countdown ] } @results;

	$self->{results} = \@results;

	return @results;
}

# static
sub get_efa_urls {

	# sorted lexically by shortname
	return (
		{
			url       => 'https://bsvg.efa.de/bsvagstd/XML_DM_REQUEST',
			name      => 'Braunschweiger Verkehrs-GmbH',
			shortname => 'BSVG',
		},
		{
			url       => 'https://www.ding.eu/ding3/XSLT_DM_REQUEST',
			name      => 'Donau-Iller Nahverkehrsverbund',
			shortname => 'DING',
		},
		{
			url  => 'https://projekte.kvv-efa.de/sl3-alone/XSLT_DM_REQUEST',
			name => 'Karlsruher Verkehrsverbund',
			shortname => 'KVV',
		},
		{
			url       => 'https://www.linzag.at/static/XSLT_DM_REQUEST',
			name      => 'Linz AG',
			shortname => 'LinzAG',
			encoding  => 'iso-8859-15',
		},
		{
			url       => 'https://efa.mvv-muenchen.de/mobile/XSLT_DM_REQUEST',
			name      => 'Münchner Verkehrs- und Tarifverbund',
			shortname => 'MVV',
		},
		{
			url       => 'https://www.efa-bw.de/nvbw/XSLT_DM_REQUEST',
			name      => 'Nahverkehrsgesellschaft Baden-Württemberg',
			shortname => 'NVBW',
		},

		# HTTPS not supported
		{
			url       => 'http://efa.svv-info.at/sbs/XSLT_DM_REQUEST',
			name      => 'Salzburger Verkehrsverbund',
			shortname => 'SVV',
		},

		# HTTPS: invalid certificate
		{
			url  => 'http://www.travelineeastmidlands.co.uk/em/XSLT_DM_REQUEST',
			name => 'Traveline East Midlands',
			shortname => 'TLEM',
		},
		{
			url       => 'https://efa.vagfr.de/vagfr3/XSLT_DM_REQUEST',
			name      => 'Freiburger Verkehrs AG',
			shortname => 'VAG',
		},

		# HTTPS: unsupported protocol
		{
			url       => 'http://mobil.vbl.ch/vblmobil/XML_DM_REQUEST',
			name      => 'Verkehrsbetriebe Luzern',
			shortname => 'VBL',
		},

		# HTTPS not supported
		{
			url       => 'http://fahrplan.verbundlinie.at/stv/XSLT_DM_REQUEST',
			name      => 'Verkehrsverbund Steiermark',
			shortname => 'Verbundlinie',
		},
		{
			url       => 'https://efa.vgn.de/vgnExt_oeffi/XML_DM_REQUEST',
			name      => 'Verkehrsverbund Grossraum Nuernberg',
			shortname => 'VGN',
		},

		# HTTPS: certificate verification fails
		{
			url       => 'http://efa.vmv-mbh.de/vmv/XML_DM_REQUEST',
			name      => 'Verkehrsgesellschaft Mecklenburg-Vorpommern',
			shortname => 'VMV',
		},
		{
			url       => 'https://efa.vor.at/wvb/XSLT_DM_REQUEST',
			name      => 'Verkehrsverbund Ost-Region',
			shortname => 'VOR',
			encoding  => 'iso-8859-15',
		},

		# HTTPS not supported
		{
			url       => 'http://fahrplanauskunft.vrn.de/vrn/XML_DM_REQUEST',
			name      => 'Verkehrsverbund Rhein-Neckar',
			shortname => 'VRN',
		},
		{
			url       => 'https://efa.vrr.de/vrr/XSLT_DM_REQUEST',
			name      => 'Verkehrsverbund Rhein-Ruhr',
			shortname => 'VRR',
		},
		{
			url       => 'https://app.vrr.de/standard/XML_DM_REQUEST',
			name      => 'Verkehrsverbund Rhein-Ruhr (alternative)',
			shortname => 'VRR2',
		},

		# HTTPS not supported
		{
			url       => 'http://efa.vvo-online.de:8080/dvb/XSLT_DM_REQUEST',
			name      => 'Verkehrsverbund Oberelbe',
			shortname => 'VVO',
		},
		{
			url       => 'https://www2.vvs.de/vvs/XSLT_DM_REQUEST',
			name      => 'Verkehrsverbund Stuttgart',
			shortname => 'VVS',
		},

	);
}

1;

__END__

=head1 NAME

Travel::Status::DE::EFA - unofficial EFA departure monitor

=head1 SYNOPSIS

    use Travel::Status::DE::EFA;

    my $status = Travel::Status::DE::EFA->new(
        efa_url => 'https://efa.vrr.de/vrr/XSLT_DM_REQUEST',
        place => 'Essen', name => 'Helenenstr'
    );

    for my $d ($status->results) {
        printf(
            "%s %-8s %-5s %s\n",
            $d->time, $d->platform_name, $d->line, $d->destination
        );
    }

=head1 VERSION

version 1.17

=head1 DESCRIPTION

Travel::Status::DE::EFA is an unofficial interface to EFA-based departure
monitors.

It reports all upcoming tram/bus/train departures at a given place.

=head1 METHODS

=over

=item my $status = Travel::Status::DE::EFA->new(I<%opt>)

Requests the departures as specified by I<opts> and returns a new
Travel::Status::DE::EFA object.  B<efa_url>, B<place> and B<name> are
mandatory.  Dies if the wrong I<opts> were passed.

Arguments:

=over

=item B<efa_url> => I<url>

URL to the EFA service. See C<< efa-m --list >> for known URLs.
If you found a URL not listed there, please notify
E<lt>derf+efa@finalrewind.orgE<gt>.

=item B<place> => I<place>

Name of the place/city

=item B<type> => B<address>|B<poi>|B<stop>

Type of the following I<name>.  B<poi> means "point of interest".  Defaults to
B<stop> (stop/station name).

=item B<name> => I<name>

address / poi / stop name to list departures for.

=item B<efa_encoding> => I<encoding>

Some EFA servers do not correctly specify their response encoding. If you
observe encoding issues, you can manually specify it here. Example:
iso-8859-15.

=item B<full_routes> => B<0>|B<1>

If true: Request full routes for all departures from the backend. This
enables the B<route_pre>, B<route_post> and B<route_interesting> accessors in
Travel::Status::DE::EFA::Result(3pm).

=item B<timeout> => I<seconds>

Request timeout, the argument is passed on to LWP::UserAgent(3pm).
Default: 10 seconds. Set to 0 or a negative value to disable it.

=back

=item $status->errstr

In case of an HTTP request or EFA error, returns a string describing it. If
none occured, returns undef.

=item $status->identified_data

Returns a list of the identified values for I<place> and I<name>.
For instance, when requesting data for "E", "MartinSTR", B<identified_data>
will return ("Essen", "Martinstr.").

=item $status->lines

Returns a list of Travel::Status::DE::EFA::Line(3pm) objects, each one
describing one line servicing the selected station.

=item $status->name_candidates

Returns a list of B<name> candidates if I<name> is ambiguous. Returns
nothing (undef / empty list) otherwise.

=item $status->place_candidates

Returns a list of B<place> candidates if I<place> is ambiguous. Returns
nothing (undef / empty list) otherwise.

=item $status->results

Returns a list of Travel::Status::DE::EFA::Result(3pm) objects, each one describing
one departure.

=item Travel::Status::DE::EFA::get_efa_urls()

Returns a list of known EFA entry points. Each list element is a hashref with
the following elements.

=over

=item B<url>: service URL as passed to B<efa_url>

=item B<name>: Name of the entity operating this service

=item B<shortname>: Short name of the entity

=item B<encoding>: Server-side encoding override for B<efa_encoding> (optional)

=back

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item * Class::Accessor(3pm)

=item * LWP::UserAgent(3pm)

=item * XML::LibXML(3pm)

=back

=head1 BUGS AND LIMITATIONS

Not all features of the web interface are supported.

=head1 SEE ALSO

efa-m(1), Travel::Status::DE::EFA::Result(3pm).

=head1 AUTHOR

Copyright (C) 2011-2015 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
