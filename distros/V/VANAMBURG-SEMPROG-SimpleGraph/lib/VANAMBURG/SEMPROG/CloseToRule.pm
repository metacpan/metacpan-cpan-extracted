package VANAMBURG::SEMPROG::CloseToRule;

use Moose;
use English qw/ARG/;

sub getqueries
{
    my ($self) = shift;

    return [ ['?place', 'latitude', '?latitude'],
	     ['?place', 'longitude', '?longitude'] 
	];
}


sub maketriples
{
    my ($self, $binding) = @ARG;
    
    my $distance = 
	sqrt
	(
	 (69.1*($self->latitude - $binding->{latitude}))**2 
	 + 
	 (53*($self->longitude - $binding->{longitude}))**2
	);

    if ($distance < 1){
	return [[$self->place, 'close_to', $binding->{place}]];
    }else{
	return [[$self->place, 'far_from', $binding->{place}]];
    }
}

with 'VANAMBURG::SEMPROG::InferenceRule';

sub BUILD{
    my $self = shift;
    
    $self->latitude(
	$self->graph->value($self->place, 'latitude',undef)
	);
    
    $self->longitude(
	$self->graph->value($self->place, 'longitude', undef)
	);


}

has 'place' => (is=>'ro', required=>1);
has 'graph' => (is=>'rw', isa=>'VANAMBURG::SEMPROG::SimpleGraph', required=>1);

has 'latitude' => (isa=>'Num', is=>'rw');
has 'longitude' => (isa=>'Num', is=>'rw');


# make moose fast and return a positive 
# value as required by perl for modules.
__PACKAGE__->meta->make_immutable;
no Moose;

1;


__END__;


=head1 CloseToRule

=head2 BUILD

Initialize latitude and longitude based on parameters
passed in constructor.

=head2 getqueries

=head2 maketriples
