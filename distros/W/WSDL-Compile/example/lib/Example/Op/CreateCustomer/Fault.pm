package Example::Op::CreateCustomer::Fault;

use Moose;

use MooseX::Types::XMLSchema qw( :all );
use WSDL::Compile::Meta::Attribute::WSDL;


has 'CustomerID' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'xs:string',
);


no Moose;

1;
