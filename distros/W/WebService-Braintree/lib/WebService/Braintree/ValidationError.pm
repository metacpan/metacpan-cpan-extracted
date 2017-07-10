package WebService::Braintree::ValidationError;
$WebService::Braintree::ValidationError::VERSION = '0.91';
use Moose;

has 'attribute' => (is => 'ro');
has 'code' => (is => 'ro');
has 'message' => (is => 'ro');

__PACKAGE__->meta->make_immutable;
1;

