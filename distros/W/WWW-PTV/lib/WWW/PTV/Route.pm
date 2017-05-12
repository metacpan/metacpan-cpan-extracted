package WWW::PTV::Route;

use strict;
use warnings;

use WWW::PTV::TimeTable;
use HTML::TreeBuilder;
use Scalar::Util qw(weaken);
use Carp qw(croak);

our $STOP = {};
our @ATTR = qw(	id direction_out direction_in direction_out_link direction_in_link
		description_out description_in name operator operator_ph );

foreach my $attr ( @ATTR ) { 
        {   
                no strict 'refs';
                *{ __PACKAGE__ .'::'. $attr } = sub {
                        my( $self, $val ) = @_; 
                        $self->{$attr} = $val if $val;
                        return $self->{$attr}
                }   
        }   
}

sub new {
        my ( $class, %args ) = @_;

        my $self = bless {}, $class;
        $args{id} or croak 'Constructor failed: mandatory id argument not supplied';

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

	$self->{uri} = $args{uri};
	$args{ua} ? weaken( $self->{ua} = $args{ua} ) : croak 'Mandatory argument ua not supplied';

        return $self
}

sub get_inbound_tt	{ $_[0]->__get_tt( 'in' )	} 

sub get_outbound_tt	{ $_[0]->__get_tt( 'out' )	} 

sub __get_tt {
        my ( $self, $direction ) = @_;

	return unless $direction =~ /(in|out)/;

	my $tt = $self->__request( $direction eq 'out' 
		? $self->{direction_out_link} 
		: $self->{direction_in_link}
	);

	my $t = HTML::TreeBuilder->new_from_content( $tt );

	for ( $t->look_down( _tag => 'meta' ) ) {

		if( ( defined $_->attr( 'http-equiv' ) ) 
			and ( $_->attr( 'http-equiv' ) eq 'refresh' ) 
		) {
			( my $url = $_->attr( 'content' ) ) =~ s/^.*url=//;
			$url .= '&itdLPxx_scrollOffset=118';

			$t = HTML::TreeBuilder->new_from_content( $self->__request( $self->{uri}.'/tt/'.$url ) );

			last
		}
	}

	$tt = $t->look_down( _tag => 'img', title => 'Expand' );

	if ( $tt && $tt->attr( 'onclick' ) && $tt->attr( 'onclick' ) =~ /TTB_REQUEST/ ) {
		( $tt = $tt->attr( 'onclick' ) ) =~ s/^.*\('//;
		$tt =~ s/'.*$//;
		$t = HTML::TreeBuilder->new_from_content( $self->__request( "http://tt.ptv.vic.gov.au/tt/$tt" ) )
	}

	$t = $t->look_down( _tag => 'div', id => qr/tt(Bus|Tram|Train|Regional)/ );
	my @stops = $t->look_down( _tag => 'div', class => qr/^ma_stop/ );
	my @stop_names = map { $_->as_text } @stops;
	my @stop_links = map { my ($r) = $_->look_down( _tag => 'a' )->attr( 'href' ) =~ /.*\/(\d*$)/ } @stops;
	my $stop_times;
	my $c = 0;

	foreach my $t ( $t->look_down( _tag => 'div', class => qr/^ttBodyN?TP$/ ) ) {
		my $s;

		foreach my $t ( $t->look_down( _tag => 'span' ) ) {
			my ( $h, $m ) = split /:/, $t->as_text;
			push @{ $s }, $h and next if $h !~ /\d/;
			my $is_pm = $t->look_down( _tag => 'b' );

			push @{ $s }, ( $h == 12 
					? ( $is_pm ? "$h:$m" : "00:$m" )
					: ( $is_pm ? $h + 12 .":$m" : "$h:$m" )
				);
		}

		$self->{ STOP }->{ $stop_links[$c] }->{ $direction } = $s;
		$self->{ STOP }->{ $stop_links[$c] }->{ name } = $stop_names[$c];
		$c++;
		push @{ $stop_times }, $s
	}

	my $ret = WWW::PTV::TimeTable->new( \@stop_names, \@stop_links, $stop_times );
	$self->{timetable}->{$direction} = $ret;
	return $ret;
}

sub __request {
        my ( $self, $uri ) = @_;

        my $res = ( $uri !~ /^http:/
                ? $self->{ua}->get( $self->{uri} . $uri )
                : $self->{ua}->get( $uri ) );

	return $res->content if $res->is_success;

	croak 'Unable to retrieve content: ' . $res->status_line
}

sub get_stop_names_and_ids {
	my ( $self, $direction ) = @_;

	$direction ||= 'out';
	$self->{timetable}->{$direction} || $self->__get_tt($direction);

	return $self->{timetable}->{$direction}->stop_names_and_ids;
}

1;

__END__

=pod

=head1 NAME

WWW::PTV::Route - Class for operations with Public Transport Victoria (PTV) routes

=cut

=head1 SYNOPSIS

	# Create a new WWW::PTV object
	my $ptv = WWW::PTV->new();

	# Return a WWW::PTV::Route object for route ID 1
	my $route = $ptv->get_route_by_id(1);

	# Print the route name and outbound description
	print $route->name .":". $route->description ."\n";

	# Get the route outbound timetable as a WWW::PTV::TimeTable object
	my $tt = $route->get_outbound_tt;

	# Get the route stop names and IDs as a hash in the inbound direction
	my %stops = $route->get_stop_names_and_ids( 'in' );


=head1 METHODS

=head3 id ()

Returns the route numerical ID.

=head3 name ()

Returns the route name - this is a free-form textual description of the route.

=head3 direction_out ()

Returns the outbound route description - this is freeform text that will probably
take the form 'To $LINE_NAME/$SUBURB_NAME/$LOCALITY'.

=head3 direction_in ()

Returns the inbound route description - this is freeform text that will probably
take the form 'To $LINE_NAME/$SUBURB_NAME/$LOCALITY'.

=head3 direction_out ()

Returns the outbound route description.

=head3 direction_in_link ()

Returns the URI for the timetable for the route in the inbound direction.

=head3 direction_out_link ()

Returns the URI for the timetable for the route in the outbound direction.

=head3 description_in ()

Returns the inbound route description - this is freeform text that typically
describes the major stops of the route and major direction changes.

=head3 description_out ()

Returns the outbound route description - this is freeform text that typically
describes the major stops of the route and major direction changes.

=head3 get_inbound_tt ()

Returns the inbound timetable for the route as a L<WWW::PTV::TimeTable> object.

=head3 get_outbound_tt ()

Returns the outbound timetable for the route as a L<WWW::PTV::TimeTable> object.

=head3 get_stop_names_and_ids ( in|out )

Returns an array of lists with each list containing two elements; a stop ID,
and a stop descriptive name.  The elements of the list represent the in-order
list of the stops on the route in the direction specified.

=head3 operator ()

Returns the line operator (i.e. the service provider).

=head3 operator_ph ()

Returns the phone number of the line operator.

=head1 SEE ALSO

L<WWW::PTV>, L<WWW::PTV::Area>, L<WWW::PTV::Stop>, L<WWW::PTV::TimeTable>,
L<WWW::PTV::TimeTable::Schedule>.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-ptv-route at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PTV-Route>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PTV::Route


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PTV-Route>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PTV-Route>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PTV-Route>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PTV-Route/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
