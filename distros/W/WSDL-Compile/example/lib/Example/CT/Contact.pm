
package Example::CT::Contact;

use Moose;

use MooseX::Types::XMLSchema qw( :all );
use WSDL::Compile::Meta::Attribute::WSDL;

has 'Street' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'xs:string',
);

has 'City' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'Maybe[xs:string]',
    xs_minOccurs => 1,
);

has 'County' => (
    metaclass => 'WSDL',
    is => 'rw',
    isa => 'xs:string',
);

no Moose;

1;
