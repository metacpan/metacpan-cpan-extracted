package Example::Op::CreateCustomer::Request;

use Moose;

use MooseX::Types::XMLSchema qw( :all );
use WSDL::Compile::Meta::Attribute::WSDL;

has '_operation_documentation' => (
    is => 'ro',
    isa => 'Str',
    default => 'This is an example of documentation of an CreateCustomer operation',
);
has 'TemplateCode' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Maybe[xs:string]',
    required => 1,
    xs_minOccurs => 1,
    xs_maxOccurs => 1,
);
has 'CustomerID' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[xs:string]',
    xs_maxOccurs => undef,
);
has 'CustomerType' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[Maybe[xs:string]]',
    xs_minOccurs => 0,
    xs_maxOccurs => undef,
);
has 'Title' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'xs:string',
);
has 'Contact' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Example::CT::Contact',
    xs_minOccurs => 0,
);
has 'Contacts' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'ArrayRef[Example::CT::Contact]',
    xs_minOccurs => 0,
    xs_maxOccurs => undef,
);
has 'BuildingNumber' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Maybe[xs:int]',
);
has 'loaded' => (
    is => 'rw',
    isa => 'Bool',
);

=head3 BUILD

WSDL::Compile allows you to call your own methods - in this example just after
$self was created.

=cut

sub BUILD {
    my $self = shift;

    $self->loaded(1);
}

no Moose;

1;

