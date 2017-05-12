package VANAMBURG::SEMPROG::TouristyRule;

use Moose;
use English qw/ARG/;

sub getqueries
{
    my ($self) = @ARG;

    return [ 
	['?ta', 'is_a', 'Tourist Attraction'],
	['?ta', 'close_to', '?restaurant'],
	['?restaurant', 'is_a', 'restaurant'],
	['?restaurant', 'cost', 'cheap'],
	];
}


sub maketriples
{
    my ($self, $binding) = @ARG;
    
    return [[$binding->{restaurant}, 'is_a', 'touristy restaurant']];
}

with 'VANAMBURG::SEMPROG::InferenceRule';

# make moose fast and return a positive 
# value as required by perl for modules.
__PACKAGE__->meta->make_immutable;
no Moose;

1; 


__END__;


=head1 TouristyRule

=head2 getqueries

=head2 maketriples
