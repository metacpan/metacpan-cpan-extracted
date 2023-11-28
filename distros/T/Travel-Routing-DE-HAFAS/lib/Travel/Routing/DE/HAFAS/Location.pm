package Travel::Routing::DE::HAFAS::Location;

use strict;
use warnings;
use 5.014;

use parent 'Class::Accessor';

our $VERSION = '0.01';

Travel::Routing::DE::HAFAS::Location->mk_ro_accessors(
	qw(lid type name eva state coordinate));

sub new {
	my ( $obj, %opt ) = @_;

	my $loc = $opt{loc};

	my $ref = {
		lid        => $loc->{lid},
		type       => $loc->{type},
		name       => $loc->{name},
		eva        => 0 + $loc->{extId},
		state      => $loc->{state},
		coordinate => $loc->{crd}
	};

	bless( $ref, $obj );

	return $ref;
}

sub TO_JSON {
	my ($self) = @_;

	my $ret = { %{$self} };

	return $ret;
}

1;

__END__

=head1 NAME

Travel::Routing::DE::HAFAS::Location - A single public transit stop

=head1 SYNOPSIS

	printf("Destination: %s  (%8d)\n", $stop->name, $stop->eva);

=head1 VERSION

version 0.01

=head1 DESCRIPTION

Travel::Routing::DE::HAFAS::Stop describes a HAFAS stop that is part of
a connection, connection section, or (partial) journey.

=head1 METHODS

=head2 ACCESSORS

=over

=item $stop->name

Stop name, e.g. "Essen Hbf" or "Unter den Linden/B75, Tostedt".

=item $stop->eva

EVA ID, e.g. 8000080.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item Class::Accessor(3pm)

=back

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

Travel::Routing::DE::HAFAS(3pm).

=head1 AUTHOR

Copyright (C) 2023 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
