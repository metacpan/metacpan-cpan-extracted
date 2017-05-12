package WSDL::Compile::Test::Op::Example::Request;
use Moose;
use WSDL::Compile::Meta::Attribute::WSDL;
use MooseX::Types::XMLSchema qw( :all );

has '_operation_documentation' => (
    is => 'ro',
    isa => 'Str',
    default => 'This is an example of documentation of an Example operation',
);
has 'req_regular_attr' => (
    is => 'rw',
    isa => 'Str',
);
has 'req_string' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Str',
    xs_type => 'xs:string',
);
has 'req_string_xs' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'xs:string',
);
has 'req_string_minoccurs' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Str',
    xs_type => 'xs:string',
    xs_minOccurs => 1,
);
has 'req_string_xs_minoccurs' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'xs:string',
    xs_minOccurs => 1,
);
has 'req_ct_a' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'WSDL::Compile::Test::CT::ComplexType',
);
has 'req_ct_b' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'WSDL::Compile::Test::CT::ComplexType',
);
has 'req_array_str' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[xs:string]',
    xs_minOccurs => 1,
    xs_maxOccurs => 2,
    required => 1,
);
has 'req_array_maybe_str' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[Maybe[xs:string]]',
    xs_minOccurs => 1,
    xs_maxOccurs => 2,
);
has 'req_array_str_ref' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[xs:string]',
    xs_ref => 'ArrayOfReqStr',
    xs_minOccurs => 1,
    xs_maxOccurs => 2,
    required => 1,
);
has 'req_array_ct' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[WSDL::Compile::Test::CT::ComplexType]',
    xs_maxOccurs => 1,
);

no Moose;

1;

