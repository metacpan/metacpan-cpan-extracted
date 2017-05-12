package WWW::MelbourneBikeShare::Terminal;

use strict;
use warnings;

our @ATTRIBUTES = qw(coordinates featurename id nbbikes nbemptydoc uploaddate
terminalname);

our %ATTRIBUTES = (
	coordinates	=> 'coordinates',
	id		=> 'id',
	featurename	=> 'name',
	nbbikes		=> 'bikes',
	nbemptydoc	=> 'empty',
	terminalname	=> 'terminal',
	uploaddate	=> 'update'
);

{
	no strict 'refs';

	foreach my $attr ( keys %ATTRIBUTES ) {
		*{ __PACKAGE__ . "::$ATTRIBUTES{ $attr }" } = sub {
			my $self = shift;
			return $self->{ $ATTRIBUTES{ $attr } }
		}
	}

}

sub new {
	my ( $class, $d ) = @_;

	my $self = bless {}, $class;

	map { $self->{ $ATTRIBUTES{ $_ } } = $d->{ $_ } } keys %ATTRIBUTES;

	return $self
}

sub lat { $_[0]->__point( 1 ) }

sub lon { $_[0]->__point( 0 ) }

sub distance {
	my ( $self, $lat, $lon ) = @_;

	return unless $lat and $lon;

	return $self->__haversine( $lat, $lon )
}

sub __point { return $_[0]->{ coordinates }->{ coordinates }->[ $_[1] ] }

sub __asin { 
        my $x = shift; 
        atan2( $x, sqrt( 1 - $x * $x ) ) 
}
 
sub __haversine {
        my( $self, $lat, $lon ) = @_; 

	my $tlon = $lon;
        my $radius = 6372.8;
        my $radians = ( 22 / 7 ) / 180;
        my $dlat = ( $self->lat - $lat ) * $radians;
        my $dlon = ( $self->lon - $lon ) * $radians;
        my $a = sin( $dlat / 2 )** 2 
		+ cos( $self->lat * $radians ) 
		* cos( $lat * $radians ) 
                * sin( $dlon / 2 )**2;
        my $c = 2 * __asin( sqrt( $a ) );

        return $radius * $c; 
}


1;

__END__

=head1 NAME

WWW::MelbourneBikeShare::Terminal - Utility class for representing Melbourne 
Bike Share terminals.

=head1 SYNOPSIS

This module implements a utility class for representing Melbourne Bike Share 
terminals.  Note that you should not usually need to create a 
WWW::MelbourneBikeShare::Terminal object directly, rather, they will be created
for you automatically via calls to methods in the L<WWW::MelbourneBikeShare>
module.

=head1 METHODS

=head2 id

Returns the ID number of the terminal.  Note that the ID number of the terminal
is different from the terminal ID number (see the L</terminal> method below).

=head2 terminal

Returns the terminal ID number.  Note that the terminal ID number different 
from the ID number of the terminal (see the L</id> method above).

=head2 name

Returns the friendly name of the terminal (e.g. "Argyle Square - Lygon St - Carlton").

=head2 bikes

Returns the number of available bikes.

=head2 empty

Returns the number of available bike slots.

=head2 lat

Returns the geographical latitude coordinate of the terminal.

=head2 lon

Returns the geographical latitude coordinate of the terminal.

=head2 distance ( $LAT, $LON ) 

Returns the distance of the terminal from the provided latitude and longitude
parameters as expressed in kilometers.

=head2 update

Returns an ISO 8601 timestamp in the format:

    YYYY-MM-DDThh:mm:ss.sss

Note that no timezone information is provided and that all times are assumed to 
be local to the time zone AEST.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-melbournebikeshare at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-MelbourneBikeShare>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::MelbourneBikeShare

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-MelbourneBikeShare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-MelbourneBikeShare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-MelbourneBikeShare>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-MelbourneBikeShare/>

=item * Melbourne Bike Share open data set

L<https://data.melbourne.vic.gov.au/Transport-Movement/Melbourne-bike-share/tdvh-n9dv>

=back

=head1 SEE ALSO

L<WWW::MelbourneBikeShare>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

