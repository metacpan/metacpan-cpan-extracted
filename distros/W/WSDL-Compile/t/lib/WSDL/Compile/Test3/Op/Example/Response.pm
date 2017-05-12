package WSDL::Compile::Test3::Op::Example::Response;
use Moose;
use WSDL::Compile::Meta::Attribute::WSDL;

has 'res_string1a' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Str',
    xs_type => 'xs:string',
);
has 'ct_array1a' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[xs:int]',
);

no Moose;

1;

