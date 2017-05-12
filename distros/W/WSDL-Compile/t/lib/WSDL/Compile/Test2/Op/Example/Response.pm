package WSDL::Compile::Test2::Op::Example::Response;
use Moose;
use WSDL::Compile::Meta::Attribute::WSDL;

has 'res_string1a' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Str',
    xs_type => 'xs:string',
);

no Moose;

1;

