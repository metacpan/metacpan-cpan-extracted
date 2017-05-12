package WSDL::Compile::Test3::Op::Example::Fault;
use Moose;
use WSDL::Compile::Meta::Attribute::WSDL;

has 'flt_string1a' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Str',
    xs_type => 'xs:string',
);

no Moose;

1;

