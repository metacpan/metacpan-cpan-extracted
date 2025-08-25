package Travel::Status::DE::DBRIS::Formation;

use strict;
use warnings;
use 5.020;

use List::Util qw(uniq);

use parent 'Class::Accessor';

use Travel::Status::DE::DBRIS::Formation::Group;
use Travel::Status::DE::DBRIS::Formation::Sector;
use Travel::Status::DE::DBRIS::Formation::Carriage;

our $VERSION = '0.13';

Travel::Status::DE::DBRIS::Formation->mk_ro_accessors(
	qw(direction platform train_type));

sub new {
	my ( $obj, %opt ) = @_;

	my $json = $opt{json};

	my $ref = {
		json           => $opt{json},
		train_type     => $opt{train_type},
		platform       => $json->{departurePlatform},
		platform_sched => $json->{departurePlatformSchedule},
	};

	bless( $ref, $obj );

	$ref->parse_carriages;
	$ref->{destinations}  = $ref->merge_group_attr('destination');
	$ref->{train_numbers} = $ref->merge_group_attr('train_no');
	$ref->{trains}        = $ref->merge_group_attr('train');

	return $ref;
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
	  = $self->{json}{platform}{end} - $self->{json}{platform}{start};

	for my $sector ( @{ $self->{json}{platform}{sectors} } ) {
		push(
			@{ $self->{sectors} },
			Travel::Status::DE::DBRIS::Formation::Sector->new(
				json     => $sector,
				platform => {
					start => $self->{json}{platform}{start},
					end   => $self->{json}{platform}{end},
				}
			)
		);
	}

	my @groups;
	my @numbers;

	for my $group ( @{ $self->{json}{groups} // [] } ) {
		my @group_carriages;
		for my $carriage ( @{ $group->{vehicles} // [] } ) {
			my $carriage_object
			  = Travel::Status::DE::DBRIS::Formation::Carriage->new(
				json     => $carriage,
				platform => {
					start => $self->{json}{platform}{start},
					end   => $self->{json}{platform}{end},
				}
			  );
			push( @group_carriages,        $carriage_object );
			push( @{ $self->{carriages} }, $carriage_object );
		}
		@group_carriages
		  = sort { $a->start_percent <=> $b->start_percent } @group_carriages;
		my $group_obj = Travel::Status::DE::DBRIS::Formation::Group->new(
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

	my $ret = { %{$self} };

	return $ret;
}

1;
