package Travel::Status::DE::DBWagenreihung;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';

use Carp qw(cluck confess);
use JSON;
use List::Util qw(uniq);
use LWP::UserAgent;
use Travel::Status::DE::DBWagenreihung::Group;
use Travel::Status::DE::DBWagenreihung::Sector;
use Travel::Status::DE::DBWagenreihung::Carriage;

our $VERSION = '0.18';

Travel::Status::DE::DBWagenreihung->mk_ro_accessors(
	qw(direction platform train_type));

# {{{ Constructors

sub new {
	my ( $class, %opt ) = @_;

	if ( not $opt{train_number} and not $opt{from_json} ) {
		confess('train_number option must be set');
	}

	if ( not $opt{departure} and not $opt{from_json} ) {
		confess('departure option must be set');
	}

	my $self = {
		api_base =>
'https://www.bahn.de/web/api/reisebegleitung/wagenreihung/vehicle-sequence',
		developer_mode => $opt{developer_mode},
		cache          => $opt{cache},
		departure      => $opt{departure},
		eva            => $opt{eva},
		from_json      => $opt{from_json},
		json           => JSON->new,
		train_type     => $opt{train_type},
		train_number   => $opt{train_number},
		user_agent     => $opt{user_agent},
	};

	bless( $self, $class );

	if ( not $self->{user_agent} ) {
		my %lwp_options = %{ $opt{lwp_options} // { timeout => 10 } };
		$self->{user_agent} = LWP::UserAgent->new(%lwp_options);
		$self->{user_agent}->env_proxy;
	}

	$self->get_wagonorder;

	return $self;
}

sub get_wagonorder {
	my ($self) = @_;

	my $api_base     = $self->{api_base};
	my $cache        = $self->{cache};
	my $eva          = $self->{eva};
	my $train_type   = $self->{train_type};
	my $train_number = $self->{train_number};

	my $json = $self->{from_json};

	if ( not $json ) {
		my $datetime = $self->{departure}->clone->set_time_zone('UTC');
		my $date     = $datetime->strftime('%Y-%m-%d');
		my $time     = $datetime->rfc3339 =~ s{(?=Z)}{.000}r;
		$self->{param} = {
			administrationId => 80,
			category         => $train_type,
			date             => $date,
			evaNumber        => $eva,
			number           => $train_number,
			time             => $time
		};
		my $url
		  = $api_base . '?'
		  . join( '&',
			map { $_ . '=' . $self->{param}{$_} } keys %{ $self->{param} } );
		my ( $content, $err ) = $self->get_with_cache( $cache, $url );

		if ($err) {
			$self->{errstr} = "GET $url: $err";
			return;
		}
		$json = $self->{from_json} = $self->{json}->utf8->decode($content);
	}

	if ( exists $json->{error} ) {
		$self->{errstr} = 'Backend error: ' . $json->{error}{msg};
		return;
	}

	if ( not $json->{departureID} ) {
		$self->{errstr} = 'No carriage formation available';
		return;
	}

	return $self->parse_wagonorder;
}

# }}}
# {{{ Internal Helpers

sub get_with_cache {
	my ( $self, $cache, $url ) = @_;

	if ( $self->{developer_mode} ) {
		say "GET $url";
	}

	if ($cache) {
		my $content = $cache->thaw($url);
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

	my $ua  = $self->{user_agent};
	my $res = $ua->get($url);

	if ( $res->is_error ) {
		return ( undef, $res->status_line );
	}
	my $content = $res->decoded_content;

	if ($cache) {
		$cache->freeze( $url, \$content );
	}

	return ( $content, undef );
}

sub parse_wagonorder {
	my ($self) = @_;

	$self->{platform}       = $self->{from_json}{departurePlatform};
	$self->{platform_sched} = $self->{from_json}{departurePlatformSchedule};

	$self->parse_carriages;
	$self->{destinations}  = $self->merge_group_attr('destination');
	$self->{train_numbers} = $self->merge_group_attr('train_no');
	$self->{trains}        = $self->merge_group_attr('train');
}

sub merge_group_attr {
	my ( $self, $attr ) = @_;

	my @attrs;
	my %attr_to_group;
	my %attr_to_sectors;

	for my $group ( $self->groups ) {
		push( @attrs,                                   $group->{$attr} );
		push( @{ $attr_to_group{ $group->{$attr} } },   $group );
		push( @{ $attr_to_sectors{ $group->{$attr} } }, $group->sectors );
	}

	@attrs = uniq @attrs;

	return [
		map {
			{
				name    => $_,
				groups  => $attr_to_group{$_},
				sectors => $attr_to_sectors{$_}
			}
		} @attrs
	];
}

sub parse_carriages {
	my ($self) = @_;

	my $platform_length
	  = $self->{from_json}{platform}{end} - $self->{from_json}{platform}{start};

	for my $sector ( @{ $self->{from_json}{platform}{sectors} } ) {
		push(
			@{ $self->{sectors} },
			Travel::Status::DE::DBWagenreihung::Sector->new(
				json     => $sector,
				platform => {
					start => $self->{from_json}{platform}{start},
					end   => $self->{from_json}{platform}{end},
				}
			)
		);
	}

	my @groups;
	my @numbers;

	for my $group ( @{ $self->{from_json}{groups} // [] } ) {
		my @group_carriages;
		for my $carriage ( @{ $group->{vehicles} // [] } ) {
			my $carriage_object
			  = Travel::Status::DE::DBWagenreihung::Carriage->new(
				json     => $carriage,
				platform => {
					start => $self->{from_json}{platform}{start},
					end   => $self->{from_json}{platform}{end},
				}
			  );
			push( @group_carriages,        $carriage_object );
			push( @{ $self->{carriages} }, $carriage_object );
		}
		@group_carriages
		  = sort { $a->start_percent <=> $b->start_percent } @group_carriages;
		my $group_obj = Travel::Status::DE::DBWagenreihung::Group->new(
			json      => $group,
			carriages => \@group_carriages,
		);
		push( @groups,  $group_obj );
		push( @numbers, $group_obj->train_no );
	}

	@groups = sort { $a->start_percent <=> $b->start_percent } @groups;

	@numbers = uniq @numbers;
	$self->{train_numbers} = \@numbers;

	if ( @{ $self->{carriages} // [] } > 1 ) {
		if ( $self->{carriages}[0]->{start_percent}
			> $self->{carriages}[-1]->{start_percent} )
		{
			$self->{direction} = 100;
		}
		else {
			$self->{direction} = 0;
		}
	}

	$self->{groups} = [@groups];
}

# }}}
# {{{ Public Functions

sub errstr {
	my ($self) = @_;

	return $self->{errstr};
}

sub destinations {
	my ($self) = @_;

	return @{ $self->{destinations} // [] };
}

sub train_numbers {
	my ($self) = @_;

	return @{ $self->{train_numbers} // [] };
}

sub trains {
	my ($self) = @_;

	return @{ $self->{trains} // [] };
}

sub sectors {
	my ($self) = @_;

	return @{ $self->{sectors} // [] };
}

sub groups {
	my ($self) = @_;
	return @{ $self->{groups} // [] };
}

sub carriages {
	my ($self) = @_;
	return @{ $self->{carriages} // [] };
}

sub TO_JSON {
	my ($self) = @_;

	my %copy = %{$self};

	delete $copy{from_json};

	return {%copy};
}

# }}}

1;

__END__

=head1 NAME

Travel::Status::DE::DBWagenreihung - Interface to Deutsche Bahn carriage formation API.

=head1 SYNOPSIS

    use Travel::Status::DE::DBWagenreihung;

    my $wr = Travel::Status::DE::DBWagenreihung->new(
        eva => 8000080,
        departure => $datetime,
        train_type => 'IC',
        train_number => 2045,
    );

    for my $carriage ( $wr->carriages ) {
        printf("Wagen %s: Abschnitt %s\n", $carriage->number // '?', $carriage->sector);
    }

=head1 VERSION

version 0.18

This is beta software. The API may change without notice.

=head1 DESCRIPTION

Travel:Status:DE::DBWagenreihung is an unofficial interface to the Deutsche
Bahn carriage formation API.  It returns station-specific carriage formations
(also kwnown as coach sequences) for a variety of trains in the rail network
associated with Deutsche Bahn.  Data includes carriage positions on the
platform, train type (e.g. ICE series), carriage-specific attributes such as
first/second class, and the internal type and number of each carriage.

Positions on the platform are given both in meters and percent (relative to
platform length).

Note that carriage formation data reported by the API is known to be bogus
from time to time. This module does not perform thorough sanity checking.

=head1 METHODS

=over

=item my $wr = Travel::Status::DE::DBWagenreihung->new(I<%opts>)

Requests carriage formation for a specific train at a specific scheduled
departure time and date, which implicitly encodes the requested station. Use
L<Travel::Status::DE::IRIS> or similar to map station name and train number to
scheduled departure.

Arguments:

=over

=item B<departure> => I<datetime-obj>

Scheduled departure at the station of interest. Must be a L<DateTime> object.
Mandatory.

=item B<eva> => I<number>

EVA ID of the station of interest.

=item B<train_type> => I<string>

Train type, e.g. "S" or "ICE".

=item B<train_number> => I<number>

Train number.

=back

=item $wr->errstr

In case of a fatal HTTP or backend error, returns a string describing it.
Returns undef otherwise.

=item $wr->groups

Returns a list of Travel::Status::DE::DBWagenreihung::Group(3pm) objects which
describe the groups making up the carriage formation. Individual groups may
have distinct destinations or train numbers. Each group contains a set of
carriages.

=item $wr->carriages

Describes the individual carriages the train consists of. Returns a list of
L<Travel::Status::DE::DBWagenreihung::carriage> objects.

=item $wr->direction

Gives the train's direction of travel. Returns 0 if the train will depart
towards position 0 and 100 if the train will depart towards the other platform
end (mnemonic: towards the 100% position).

=item $wr->destinations

Returns a list describing the unique destinations of this train's carriage
groups.  Each destination is a hashref that contains its B<name>, a B<groups>
arrayref to the corresponding Travel::Status::DE::DBWagenreihung::Group(3pm)
objects, and a B<sections> arrayref to section identifiers (subject to change).

=item $wr->platform

Returns the platform name.

=item $wr->sectors

Describes the sectors of the platform this train will depart from.
Returns a list of L<Travel::Status::DE::DBWagenreihung::Sector> objects.

=item $wr->train_numbers

Returns a list describing the unique train numbers associated with this train's
carriage groups.  Each train number is a hashref that contains its B<name>
(i.e., number), a B<groups> arrayref to the corresponding
Travel::Status::DE::DBWagenreihung::Group(3pm) objects, and a B<sections>
arrayref to section identifiers (subject to change).

=item $wr->train_type

Returns a string describing the train type, e.g. "ICE" or "IC".

=back

=head1 DEPENDENCIES

=over

=item * L<JSON>

=item * L<LWP::UserAgent>

=back

=head1 BUGS AND LIMITATIONS

Many. This is beta software.

=head1 REPOSITORY

L<https://github.com/derf/Travel-Status-DE-DBWagenreihung>

=head1 AUTHOR

Copyright (C) 2018-2024 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
