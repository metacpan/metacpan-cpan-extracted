package Wiki::Toolkit::Plugin::Locator::Grid;

use strict;

use vars qw( $VERSION @ISA );
$VERSION = '0.05';

use Carp qw( croak );
use Wiki::Toolkit::Plugin;

@ISA = qw( Wiki::Toolkit::Plugin );

=head1 NAME

Wiki::Toolkit::Plugin::Locator::Grid - A Wiki::Toolkit plugin to manage co-ordinate data.

=head1 DESCRIPTION

Access to and calculations using co-ordinate metadata supplied to a
Wiki::Toolkit wiki when writing a node.

B<Note:> This is I<read-only> access. If you want to write to a node's
metadata, you need to do it using the C<write_node> method of
L<Wiki::Toolkit>.

We assume that the points are located on a flat, square grid with unit
squares of side 1 metre.

=head1 SYNOPSIS

  use Wiki::Toolkit;
  use Wiki::Toolkit::Plugin::Locator::Grid;

  my $wiki = Wiki::Toolkit->new( ... );
  my $locator = Wiki::Toolkit::Plugin::Locator::Grid->new;
  $wiki->register_plugin( plugin => $locator );

  $wiki->write_node( "Jerusalem Tavern", "A good pub", $checksum,
                     { x => 531674, y => 181950 } ) or die "argh";

  # Just retrieve the co-ordinates.
  my ( $x, $y ) = $locator->coordinates( node => "Jerusalem Tavern" );

  # Find the straight-line distance between two nodes, in metres.
  my $distance = $locator->distance( from_node => "Jerusalem Tavern",
                                     to_node   => "Calthorpe Arms" );

  # Find all the things within 200 metres of a given place.
  my @others = $locator->find_within_distance( node   => "Albion",
                                               metres => 200 );

  # Maybe our wiki calls the x and y co-ordinates something else.
  my $locator = Wiki::Toolkit::Plugin::Locator::Grid->new(
                                                       x => "os_x",
                                                       y => "os_y",
                                                     );

=head1 METHODS

=over 4

=item B<new>

  # By default we assume that x and y co-ordinates are stored in
  # metadata called "x" and "y".
  my $locator = Wiki::Toolkit::Plugin::Locator::Grid->new;

  # But maybe our wiki calls the x and y co-ordinates something else.
  my $locator = Wiki::Toolkit::Plugin::Locator::Grid->new(
                                                       x => "os_x",
                                                       y => "os_y",
                                                     );

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self->_init( @_ );
}

sub _init {
    my ($self, %args) = @_;
    $self->{x} = $args{x} || "x";
    $self->{y} = $args{y} || "y";
    return $self;
}

=item B<x_field>

  my $x_field = $locator->x_field;

An accessor, returns the name of the metadata field used to store the
x-coordinate.

=cut

sub x_field {
    my $self = shift;
    return $self->{x};
}

=item B<y_field>

  my $y_field = $locator->y_field;

An accessor, returns the name of the metadata field used to store the
y-coordinate.

=cut

sub y_field {
    my $self = shift;
    return $self->{y};
}

=item B<coordinates>

  my ($x, $y) = $locator->coordinates( node => "Jerusalem Tavern" );

Returns the x and y co-ordinates stored as metadata last time the node
was written.

=cut

sub coordinates {
    my ($self, %args) = @_;
    my $store = $self->datastore;
    # This is the slightly inefficient but neat and tidy way to do it -
    # calling on as much existing stuff as possible.
    my %node_data = $store->retrieve_node( $args{node} );
    my %metadata  = %{$node_data{metadata}};
    return ($metadata{$self->{x}}[0], $metadata{$self->{y}}[0]);
}

=item B<distance>

  # Find the straight-line distance between two nodes, in metres.
  my $distance = $locator->distance( from_node => "Jerusalem Tavern",
                                     to_node   => "Calthorpe Arms" );

  # Or in kilometres, and between a node and a point.
  my $distance = $locator->distance( from_x  => 531467,
                                     from_y  => 183246,
				     to_node => "Duke of Cambridge",
				     unit    => "kilometres" );

Defaults to metres if C<unit> is not supplied or is not recognised.
Recognised units at the moment: C<metres>, C<kilometres>.

Returns C<undef> if one of the endpoints does not exist, or does not
have both co-ordinates defined. The C<node> specification of an
endpoint overrides the x/y co-ords if both specified (but don't do
that).

B<Note:> Works to the nearest metre. Well, actually, calls C<int> and
rounds down, but if anyone cares about that they can send a patch.

=cut

sub distance {
    my ($self, %args) = @_;

    $args{unit} ||= "metres";
    my (@from, @to);

    if ( $args{from_node} ) {
        @from = $self->coordinates( node => $args{from_node} );
    } elsif ( $args{from_x} and $args{from_y} ) {
        @from = @args{ qw( from_x from_y ) };
    }

    if ( $args{to_node} ) {
        @to = $self->coordinates( node => $args{to_node} );
    } elsif ( $args{to_x} and $args{to_y} ) {
        @to = @args{ qw( to_x to_y ) };
    }

    return undef unless ( $from[0] and $from[1] and $to[0] and $to[1] );

    my $metres = int( sqrt(   ($from[0] - $to[0])**2
                            + ($from[1] - $to[1])**2 ) + 0.5 );

    if ( $args{unit} eq "metres" ) {
        return $metres;
    } else {
        return $metres/1000;
    }
}

=item B<find_within_distance>

  # Find all the things within 200 metres of a given place.
  my @others = $locator->find_within_distance( node   => "Albion",
                                               metres => 200 );

  # Or within 200 metres of a given location.
  my @things = $locator->find_within_distance( x      => 530774,
                                               y      => 182260,
                                               metres => 200 );

Units currently understood: C<metres>, C<kilometres>. If both C<node>
and C<x>/C<y> are supplied then C<node> takes precedence. Croaks if
insufficient start point data supplied.

=cut

sub find_within_distance {
    my ($self, %args) = @_;
    my $store = $self->datastore;
    my $dbh = eval { $store->dbh; }
      or croak "find_within_distance is only implemented for database stores";
    my $metres = $args{metres}
               || ($args{kilometres} * 1000)
               || croak "Please supply a distance";
    my ($sx, $sy);
    if ( $args{node} ) {
        ($sx, $sy) = $self->coordinates( node => $args{node} );
    } elsif ( $args{x} and $args{y} ) {
        ($sx, $sy) = @args{ qw( x y ) };
    } else {
        croak "Insufficient start location data supplied";
    }

    # Only consider nodes within the square containing the circle of
    # radius $distance.  The SELECT DISTINCT is needed because we might
    # have multiple versions in the table.
    my $sql = "SELECT DISTINCT x.name ".
			  "FROM node AS x ".
			  "INNER JOIN metadata AS mx ".
			  "   ON (mx.node_id = x.id AND mx.version = x.version) ".
			  "INNER JOIN node AS y ".
			  "   ON (x.id = y.id) ".
			  "INNER JOIN metadata my ".
              "   ON (my.node_id = y.id AND my.version = y.version) ".
			  " WHERE mx.metadata_type = '$self->{x}' ".
              "   AND my.metadata_type = '$self->{y}' ".
              "   AND mx.metadata_value >= " . ($sx - $metres) .
              "   AND mx.metadata_value <= " . ($sx + $metres) .
              "   AND my.metadata_value >= " . ($sy - $metres) .
              "   AND my.metadata_value <= " . ($sy + $metres);
    $sql .= "     AND x.name != " . $dbh->quote($args{node})
        if $args{node};
    # Postgres is a fussy bugger.
    if ( ref $store eq "Wiki::Toolkit::Store::Pg" ) {
        $sql =~ s/metadata_value/metadata_value::integer/gs;
    }
    # SQLite 3 is even fussier.
    if ( ref $store eq "Wiki::Toolkit::Store::SQLite"
         && $DBD::SQLite::VERSION >= "1.00" ) {
        $sql =~ s/metadata_value/metadata_value+0/gs; # yuck
    }
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    my @results;
    while ( my ($result) = $sth->fetchrow_array ) {
        my $dist = $self->distance( from_x  => $sx,
                                    from_y  => $sy,
				    to_node => $result,
				    unit    => "metres" );
        if ( defined $dist && $dist <= $metres ) {
            push @results, $result;
	}
    }
    return @results;
}

=head1 SEE ALSO

=over 4

=item * L<Wiki::Toolkit>

=item * L<OpenGuides> - an application that uses this plugin.

=back

=head1 AUTHOR

Kake Pugh (kake@earth.li).
The Wiki::Toolkit team (http://www.wiki-toolkit.org/)

=head1 COPYRIGHT

     Copyright (C) 2004 Kake L Pugh.  All Rights Reserved.
     Copyright (C) 2006 the Wiki::Toolkit Team. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

This module is based heavily on (and is the replacement for)
L<Wiki::Toolkit::Plugin::Locator::UK>.

The following thanks are due to people who helped with
L<Wiki::Toolkit::Plugin::Locator::UK>: Nicholas Clark found a very silly
bug in a pre-release version, oops :) Stephen White got me thinking in
the right way to implement C<find_within_distance>. Marcel Gruenauer
helped me make C<find_within_distance> work properly with postgres.

=cut


1;
