package WebService::Braintree::Dispute::Evidence;
$WebService::Braintree::Dispute::Evidence::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose;
extends "WebService::Braintree::ResultObject";

=pod

has comment => (is => 'rw');
has created_at => (is => 'rw');
has id => (is => 'rw');
has sent_to_processor_at => (is => 'rw');
has url => (is => 'rw');

=cut

sub BUILD {
    my ($self, $attrs) = @_;

    $self->set_attributes_from_hash($self, $attrs);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
