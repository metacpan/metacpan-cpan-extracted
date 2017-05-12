package WSDL::Compile::Test::CT::ComplexTypeA;

use Moose;
use WSDL::Compile::Meta::Attribute::WSDL;
use MooseX::Types::XMLSchema qw( :all );

has 'ct_regular_attr_1' => (
    is => 'rw',
    isa => 'Str',
);
has 'ct_string1a' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Str',
    xs_type => 'xs:string',
);
has 'ct_string2a' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'xs:string',
);
has 'ct_string1b' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Str',
    xs_type => 'xs:string',
    xs_minOccurs => 1,
);
has 'ct_string2b' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'xs:string',
    xs_minOccurs => 1,
);
has 'ct_array1a' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[xs:string]',
);
has 'ct_array1b' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[Maybe[xs:string]]',
    xs_ref => 'ArrayOfCTANullableString',
    xs_minOccurs => 1,
    xs_maxOccurs => 2,
    required => 1,
);
has 'ct_array1c' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[xs:string]',
    xs_minOccurs => 1,
    xs_maxOccurs => 2,
    required => 1,
);


no Moose;


1;

