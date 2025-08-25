package Travel::Status::DE::DBRIS::Journey;

use strict;
use warnings;
use 5.020;

use parent 'Class::Accessor';

use Travel::Status::DE::DBRIS::Location;

our $VERSION = '0.13';

# ->number is deprecated
# TODO: Rename ->train, ->train_no to ->trip, ->trip_no
Travel::Status::DE::DBRIS::Journey->mk_ro_accessors(
	qw(day id train train_no line_no type number is_cancelled));

sub new {
	my ( $obj, %opt ) = @_;

	my $json     = $opt{json};
	my $strpdate = $opt{strpdate_obj};
	my $strptime = $opt{strptime_obj};

	my $ref = {
		id           => $opt{id},
		day          => $strpdate->parse_datetime( $json->{reisetag} ),
		train        => $json->{zugName},
		is_cancelled => $json->{cancelled},
		raw_route    => $json->{halte},
		raw_polyline => $json->{polylineGroup}{polylineDescriptions},
		strptime_obj => $strptime,
	};

	if ( $json->{halte} and @{ $json->{halte} } ) {
		$ref->{train_no} = $json->{halte}[0]{nummer};
	}

	# Number is either train no (ICE, RE) or line no (S, U, Bus, ...)
	# with no way of distinguishing between those
	if ( $ref->{train} ) {
		( $ref->{type}, $ref->{number} ) = split( qr{\s+}, $ref->{train} );
	}

	# For some trains, the train type also contains the train number like "MEX19161"
	# If we can detect this, remove the number from the train type
	if ( $ref->{train_no} and $ref->{type}
		and $ref->{type} =~ qr{ (?<actualtype> [^\d]+ ) $ref->{train_no} $ }x )
	{
		$ref->{type} = $+{actualtype};
	}

	# The line number seems to be encoded in the trip ID
	if ( not defined $ref->{number}
		and $opt{id} =~ m{ [#] ZE [#] (?<line> [^#]+ ) [#] ZB [#] }x )
	{
		$ref->{number} = $+{line};
	}

	if (    defined $ref->{number}
		and defined $ref->{train_no}
		and $ref->{number} ne $ref->{train_no} )
	{
		$ref->{line_no} = $ref->{number};
	}

	bless( $ref, $obj );

	for my $message ( @{ $json->{himMeldungen} // [] } ) {
		push( @{ $ref->{messages} }, $message );
	}

	for my $message ( @{ $json->{priorisierteMeldungen} // [] } ) {
		push( @{ $ref->{messages} }, $message );
	}

	for my $attr ( @{ $json->{zugattribute} // [] } ) {
		push( @{ $ref->{attributes} }, $attr );
	}

	return $ref;
}

sub polyline {
	my ($self) = @_;

	if ( not $self->{raw_polyline} ) {
		return;
	}

	if ( $self->{polyline} ) {
		return @{ $self->{polyline} };
	}

	my $distance;
	my $polyline = [ map { { lon => $_->{lng}, lat => $_->{lat} } }
		  @{ $self->{raw_polyline}[0]{coordinates} } ];

	eval {
		require GIS::Distance;
		$distance = GIS::Distance->new;
	};

	if ($distance) {
		my %min_dist;
		for my $stop ( $self->route ) {
			for my $polyline_index ( 0 .. $#{$polyline} ) {
				my $pl = $polyline->[$polyline_index];
				my $dist
				  = $distance->distance_metal( $stop->{lat}, $stop->{lon},
					$pl->{lat}, $pl->{lon} );
				if ( not $min_dist{ $stop->{eva} }
					or $min_dist{ $stop->{eva} }{dist} > $dist )
				{
					$min_dist{ $stop->{eva} } = {
						dist  => $dist,
						index => $polyline_index,
					};
				}
			}
		}
		for my $stop ( $self->route ) {
			if ( $min_dist{ $stop->{eva} } ) {
				$polyline->[ $min_dist{ $stop->{eva} }{index} ]{stop}
				  = $stop;
			}
		}
	}

	$self->{polyline} = $polyline;

	return @{ $self->{polyline} };
}

sub route {
	my ($self) = @_;

	if ( $self->{route} ) {
		return @{ $self->{route} };
	}

	@{ $self->{route} }
	  = map {
		Travel::Status::DE::DBRIS::Location->new(
			json         => $_,
			strptime_obj => $self->{strptime_obj}
		)
	  } ( @{ $self->{raw_route} // [] },
		@{ $self->{raw_cancelled_route} // [] } );

	return @{ $self->{route} };
}

sub attributes {
	my ($self) = @_;

	return @{ $self->{attributes} // [] };
}

sub messages {
	my ($self) = @_;

	return @{ $self->{messages} // [] };
}

sub TO_JSON {
	my ($self) = @_;

	# transform raw_route into route (lazy accessor)
	$self->route;

	# transform raw_polyline into polyline (lazy accessor)
	$self->polyline;

	my $ret = { %{$self} };

	delete $ret->{strptime_obj};

	for my $k (qw(day)) {
		if ( $ret->{$k} ) {
			$ret->{$k} = $ret->{$k}->epoch;
		}
	}

	return $ret;
}

1;

__END__

=head1 NAME

Travel::Status::DE::DBRIS::Journey - Information about a single
journey received by Travel::Status::DE::DBRIS

=head1 SYNOPSIS

	my $status = Travel::Status::DE::DBRIS->new(journey => ...);
	my $journey = $status->result;

=head1 VERSION

version 0.13

=head1 DESCRIPTION

Travel::Status::DE::DBRIS::Journey describes a single journey that was obtained
by passing the B<journey> key to Travel::Status::DE::DBRIS->new or ->new_p.

=head1 METHODS

=head2 ACCESSORS

=over

=item $journey->day

DateTime(3pm) object encoding the day on which this journey departs at its
origin station.

=item $journey->id

Trip ID / journey ID, i.e., the argument passed to
Travel::Status::DE::DBRIS->new's B<journey> key.

=item $journey->train

Textual description of the departure, typically consisting of type identifier
(e.g. C<< S >>, C<< U >>) and line or trip number.

=item $journey->train_no

Trip number, if available. undef otherwise.

=item $journey->line_no

Line identifier, if available. undef otherwise. Note that the line identifier
is not necessarily numeric.

=item $journey->type

Trip type, e.g. C<< S >> (S-Bahn) or C<< U >> (U-Bahn / subway).
undef if unknown.

=item $journey->is_cancelled

True if this trip has been cancelled, false/undef otherwise.

=item $journey->polyline

List of geocoordinates that describe the trip's route. Only available if the
DBRIS constructor was called with B<with_polyline> set to a true value.  Each
list entry is a hash with the following keys.

=over

=item * lon (longitude)

=item * lat (latitude)

=item * stop (Travel::Status::DE::DBRIS::Location(3pm) object describing the stop at this location, if any)

=back

The B<stop> keys are only available if the optional dependency
GIS::Distance(3pm) is available. Note that the B<lon> and B<lat> keys in a
referenced stop may differ from the B<lon> and B<lat> keys in a polyline entry.

=item $journey->route

List of Travel::Status::DE::DBRIS::Location(3pm) objects that describe
individual stops along the trip.

=item $journey->attributes

List of attributes associated with this trip.
Each list entry is a hashref with some or all of the following keys.

=over

=item * value (textual description of attribute)

=item * teilstreckenHinweis (text describing that this attribute only applies to part of the trip's route)

=back

=item $journey->messages

List of attributes associated with this trip.
Each list entry is a hashref with some or all of the following keys.

=over

=item * prioritaet (priority, e.g. HOCH or NIEDRIG)

=item * ueberschrift (headline)

=item * text (message text)

=back

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item Class::Accessor(3pm)

=item GIS::Distance(3pm)

Optional, required for B<stop> keys in B<polyline> entries.

=back

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

Travel::Status::DE::DBRIS(3pm).

=head1 AUTHOR

Copyright (C) 2025 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
