package VANAMBURG::SEMPROG::GeocodeRule;

use Moose;
use LWP::Simple qw/get/;
use URI::Escape qw/uri_escape/;
use English qw/ARG/;

sub getqueries
{
    my ($self) = shift;

    return [ ['?place', 'address', '?address'] ];
}


sub maketriples
{
    my ($self, $binding) = @ARG;
    
    my $address = uri_escape($binding->{address});
    
    my $geo_result = get("http://rpc.geocoder.us/service/csv?address=$address");
    
    my ($longitude, $latitude) = split ',', $geo_result;
    
    return [
	[$binding->{place}, 'longitude', $longitude],
	[$binding->{place},  'latitude', $latitude],
	];
}


with 'VANAMBURG::SEMPROG::InferenceRule';


# make moose fast and return a positive 
# value as required by perl for modules.
__PACKAGE__->meta->make_immutable;
1;


__END__;


=head1 GeocodeRule

A rule to retrieve  latitude and longitude for addresses and adds
two triples to the store.

=head2 getqueries

=head2 maketriples
