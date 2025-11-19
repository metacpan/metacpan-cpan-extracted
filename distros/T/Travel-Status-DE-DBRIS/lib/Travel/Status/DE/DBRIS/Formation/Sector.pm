package Travel::Status::DE::DBRIS::Formation::Sector;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';

our $VERSION = '0.18';

Travel::Status::DE::DBRIS::Formation::Sector->mk_ro_accessors(
	qw(name start_percent end_percent length_percent start_meters end_meters length_meters cube_meters cube_percent)
);

sub new {
	my ( $obj, %opt ) = @_;

	my %section  = %{ $opt{json} };
	my %platform = %{ $opt{platform} };

	my $platform_length = $platform{end} - $platform{start};

	my $ref = {
		name          => $section{name},
		start_meters  => $section{start},
		end_meters    => $section{end},
		length_meters => $section{end} - $section{start},
		cube_meters   => $section{cubePosition},
		start_percent => ( $section{start} - $platform{start} )
		  * 100 / $platform_length,
		end_percent => ( $section{end} - $platform{start} )
		  * 100 / $platform_length,
		cube_percent => ( $section{cubePosition} - $platform{start} )
		  * 100 / $platform_length,
	};

	$ref->{length_percent} = $ref->{end_percent} - $ref->{start_percent};

	return bless( $ref, $obj );
}

sub TO_JSON {
	my ($self) = @_;

	my %copy = %{$self};

	return {%copy};
}

1;

