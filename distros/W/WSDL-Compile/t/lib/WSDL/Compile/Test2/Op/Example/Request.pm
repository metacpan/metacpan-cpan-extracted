package WSDL::Compile::Test2::Op::Example::Request;
use Moose;
use WSDL::Compile::Meta::Attribute::WSDL;
use MooseX::Types::XMLSchema qw( :all );

has 'ct_array1a' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[xs:string]',
    xs_minOccurs => 1,
    xs_maxOccurs => 2,
    required => 1,
);
has 'req_array1c' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[WSDL::Compile::Test2::CT::ComplexType]',
    xs_maxOccurs => 1,
);

no Moose;

1;

