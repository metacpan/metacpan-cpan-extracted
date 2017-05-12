package Example::Op::CreateCustomer::Response;

use Moose;

use MooseX::Types::XMLSchema qw( :all );
use WSDL::Compile::Meta::Attribute::WSDL;

has 'CustomerID' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[xs:string]',
    xs_maxOccurs => undef,
);

no Moose;

1;
