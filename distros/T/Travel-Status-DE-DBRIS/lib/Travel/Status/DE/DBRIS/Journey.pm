package Travel::Status::DE::DBRIS::Journey;

use strict;
use warnings;
use 5.020;

use parent 'Class::Accessor';

use Travel::Status::DE::DBRIS::Location;

our $VERSION = '0.04';

Travel::Status::DE::DBRIS::Journey->mk_ro_accessors(qw(day train is_cancelled));

sub new {
	my ( $obj, %opt ) = @_;

	my $json     = $opt{json};
	my $strpdate = $opt{strpdate_obj};
	my $strptime = $opt{strptime_obj};

	my $ref = {
		day          => $strpdate->parse_datetime( $json->{reisetag} ),
		train        => $json->{zugName},
		is_cancelled => $json->{cancelled},
		raw_route    => $json->{halte},
		strptime_obj => $strptime,
	};

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

	my $ret = { %{$self} };

	return $ret;
}

1;
