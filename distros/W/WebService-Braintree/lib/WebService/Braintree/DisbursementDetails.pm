package WebService::Braintree::DisbursementDetails;
$WebService::Braintree::DisbursementDetails::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::ResultObject';

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}

sub is_valid {
    my $self = shift;
    if (defined($self->disbursement_date)) {
        1;
    } else {
        0;
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
