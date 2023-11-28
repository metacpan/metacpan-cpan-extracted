package Travel::Status::DE::EFA::Line;

use strict;
use warnings;
use 5.010;

use parent 'Class::Accessor';

our $VERSION = '1.23';

Travel::Status::DE::EFA::Line->mk_ro_accessors(
	qw(direction mot name operator route type valid));

my @mot_mapping = qw{
  zug s-bahn u-bahn stadtbahn tram stadtbus regionalbus
  schnellbus seilbahn schiff ast sonstige
};

sub new {
	my ( $obj, %conf ) = @_;

	my $ref = \%conf;

	return bless( $ref, $obj );
}

sub mot_name {
	my ($self) = @_;

	return $mot_mapping[ $self->{mot} ] // 'sonstige';
}

sub TO_JSON {
	my ($self) = @_;

	return { %{$self} };
}

1;

__END__

=head1 NAME

Travel::Status::DE::EFA::Line - Information about a line departing at the
requested station

=head1 SYNOPSIS

    for my $line ($status->lines) {
        printf(
            "line %s -> %s\nRoute: %s\nType %s, operator %s\nValid: %s\n\n",
            $line->name, $line->direction, $line->route,
            $line->type, $line->operator, $line->valid
        );
    }

=head1 VERSION

version 1.23

=head1 DESCRIPTION

Travel::Status::DE::EFA::Line describes a tram/bus/train line departing at the
stop requested by Travel::Status::DE::EFA. Note that it only covers one
direction, so in most cases, you get two Travel::Status::DE::EFA::Line objects
per actual line.

=head1 METHODS

=head2 ACCESSORS

=over

=item $line->direction

Direction of the line.  Name of either the destination stop or one on the way.

=item $line->mot

Returns the "mode of transport" number for this line. This is usually an
integer between 0 and 11.

=item $line->mot_name

Returns the "mode of transport" for this line, for instance "zug", "s-bahn",
"tram" or "sonstige".

=item $line->name

Name of the line, e.g. "U11", "SB15", "107".

=item $line->operator

Operator of the line, as in the local transit company responsible for it.
May be undefined.

=item $line->route

Partial route of the line (as string), usually start and destination with two
stops in between. May be undefined.

Note that start means the actual start of the line, the stop requested by
Travel::Status::DE::EFA::Line may not even be included in this listing.

=item $line->type

Type of the line.  Observed values so far are "Bus", "NE", "StraE<szlig>enbahn",
"U-Bahn".

=item $line->valid

When / how long above information is valid.

=back

=head2 INTERNAL

=over

=item $line = Travel::Status::DE::EFA::Line->new(I<%data>)

Returns a new Travel::Status::DE::EFA::Line object.  You should not need to
call this.

=item $line->TO_JSON

Allows the object data to be serialized to JSON.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item Class::Accessor(3pm)

=back

=head1 BUGS AND LIMITATIONS

The B<route> accessor returns a simple string, an array might be better suited.

=head1 SEE ALSO

Travel::Status::DE::EFA(3pm).

=head1 AUTHOR

Copyright (C) 2011-2015 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
