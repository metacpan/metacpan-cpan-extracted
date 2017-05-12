package WWW::EFA::DateFactory;
use Moose;
use Class::Date qw/date/;


=head1 NAME

A Factory for creating L<Class::Date> objects

=head1 SYNOPSIS

  my $factory = WWW::EFA::DateFactory->new();

=cut

=head1 METHODS

=head2 date_from_itdDateTime

  my $date = $factory->date_from_itdDateTime( $doc->findnodes( 'itdDateTime' ) );

Expects an XML::LibXML::Element of XML like this:
  
<itdDateTime>
  <itdDate year="2011" month="11" day="15" weekday="3"/>
  <itdTime hour="9" minute="59"/>
</itdDateTime>

Returns a L<WWW::EFA::Departure> object

=cut
sub date_from_itdDateTime {
    my $self    = shift;
    my $elem    = shift;

    my( $date_elem ) = $elem->findnodes( 'itdDate' );
    my( $time_elem ) = $elem->findnodes( 'itdTime' );

    # Sometimes the day is '-1'.... this is not valid...
    if( $date_elem->getAttribute( 'day' ) < 0 ){
        return undef;
    }

    # TODO: RCL 2011-11-13 Test that attributes exist and are valid
    my $date = date( {
        year    => $date_elem->getAttribute( 'year' ),
        month   => $date_elem->getAttribute( 'month' ),
        day     => $date_elem->getAttribute( 'day' ),
        hour    => $time_elem->getAttribute( 'hour' ),
        min     => $time_elem->getAttribute( 'minute' ),
        } );

    return $date;
}


1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

