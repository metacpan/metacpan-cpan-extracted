package WebService::Braintree::ValidationError;
$WebService::Braintree::ValidationError::VERSION = '0.9';
use Moose;

has 'attribute' => (is => 'ro');
has 'code' => (is => 'ro');
has 'message' => (is => 'ro');

__PACKAGE__->meta->make_immutable;
1;

