
package WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedUpdate;
BEGIN {
  $WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedUpdate::VERSION = '0.01.00';
}
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'EC:WebServices' }

__PACKAGE__->__set_name('CustomerOriginAdvancedUpdate');
__PACKAGE__->__set_nillable();
__PACKAGE__->__set_minOccurs();
__PACKAGE__->__set_maxOccurs();
__PACKAGE__->__set_ref();

use base qw(
    SOAP::WSDL::XSD::Typelib::Element
    SOAP::WSDL::XSD::Typelib::ComplexType
);

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %strCredential_of :ATTR(:get<strCredential>);
my %strCustomerId_of :ATTR(:get<strCustomerId>);
my %strCustomId_of :ATTR(:get<strCustomId>);
my %intCustomerOriginId_of :ATTR(:get<intCustomerOriginId>);
my %strDirName_of :ATTR(:get<strDirName>);
my %strHttpLoadBalMode_of :ATTR(:get<strHttpLoadBalMode>);
my %strHttpHostnames_of :ATTR(:get<strHttpHostnames>);
my %strHttpsLoadBalMode_of :ATTR(:get<strHttpsLoadBalMode>);
my %strHttpsHostnames_of :ATTR(:get<strHttpsHostnames>);
my %strHostHeaderValue_of :ATTR(:get<strHostHeaderValue>);
my %strShieldPopCodes_of :ATTR(:get<strShieldPopCodes>);

__PACKAGE__->_factory(
    [ qw(        strCredential
        strCustomerId
        strCustomId
        intCustomerOriginId
        strDirName
        strHttpLoadBalMode
        strHttpHostnames
        strHttpsLoadBalMode
        strHttpsHostnames
        strHostHeaderValue
        strShieldPopCodes

    ) ],
    {
        'strCredential' => \%strCredential_of,
        'strCustomerId' => \%strCustomerId_of,
        'strCustomId' => \%strCustomId_of,
        'intCustomerOriginId' => \%intCustomerOriginId_of,
        'strDirName' => \%strDirName_of,
        'strHttpLoadBalMode' => \%strHttpLoadBalMode_of,
        'strHttpHostnames' => \%strHttpHostnames_of,
        'strHttpsLoadBalMode' => \%strHttpsLoadBalMode_of,
        'strHttpsHostnames' => \%strHttpsHostnames_of,
        'strHostHeaderValue' => \%strHostHeaderValue_of,
        'strShieldPopCodes' => \%strShieldPopCodes_of,
    },
    {
        'strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCustomId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'intCustomerOriginId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'strDirName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strHttpLoadBalMode' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strHttpHostnames' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strHttpsLoadBalMode' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strHttpsHostnames' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strHostHeaderValue' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strShieldPopCodes' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'strCredential' => 'strCredential',
        'strCustomerId' => 'strCustomerId',
        'strCustomId' => 'strCustomId',
        'intCustomerOriginId' => 'intCustomerOriginId',
        'strDirName' => 'strDirName',
        'strHttpLoadBalMode' => 'strHttpLoadBalMode',
        'strHttpHostnames' => 'strHttpHostnames',
        'strHttpsLoadBalMode' => 'strHttpsLoadBalMode',
        'strHttpsHostnames' => 'strHttpsHostnames',
        'strHostHeaderValue' => 'strHostHeaderValue',
        'strShieldPopCodes' => 'strShieldPopCodes',
    }
);

} # end BLOCK






} # end of BLOCK



1;


=pod

=head1 NAME

WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedUpdate

=head1 VERSION

version 0.01.00

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
CustomerOriginAdvancedUpdate from the namespace EC:WebServices.







=head1 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * strCredential

 $element->set_strCredential($data);
 $element->get_strCredential();




=item * strCustomerId

 $element->set_strCustomerId($data);
 $element->get_strCustomerId();




=item * strCustomId

 $element->set_strCustomId($data);
 $element->get_strCustomId();




=item * intCustomerOriginId

 $element->set_intCustomerOriginId($data);
 $element->get_intCustomerOriginId();




=item * strDirName

 $element->set_strDirName($data);
 $element->get_strDirName();




=item * strHttpLoadBalMode

 $element->set_strHttpLoadBalMode($data);
 $element->get_strHttpLoadBalMode();




=item * strHttpHostnames

 $element->set_strHttpHostnames($data);
 $element->get_strHttpHostnames();




=item * strHttpsLoadBalMode

 $element->set_strHttpsLoadBalMode($data);
 $element->get_strHttpsLoadBalMode();




=item * strHttpsHostnames

 $element->set_strHttpsHostnames($data);
 $element->get_strHttpsHostnames();




=item * strHostHeaderValue

 $element->set_strHostHeaderValue($data);
 $element->get_strHostHeaderValue();




=item * strShieldPopCodes

 $element->set_strShieldPopCodes($data);
 $element->get_strShieldPopCodes();





=back


=head1 METHODS

=head2 new

 my $element = WebService::Edgecast::auto::Administration::Element::CustomerOriginAdvancedUpdate->new($data);

Constructor. The following data structure may be passed to new():

 {
   strCredential =>  $some_value, # string
   strCustomerId =>  $some_value, # string
   strCustomId =>  $some_value, # string
   intCustomerOriginId =>  $some_value, # int
   strDirName =>  $some_value, # string
   strHttpLoadBalMode =>  $some_value, # string
   strHttpHostnames =>  $some_value, # string
   strHttpsLoadBalMode =>  $some_value, # string
   strHttpsHostnames =>  $some_value, # string
   strHostHeaderValue =>  $some_value, # string
   strShieldPopCodes =>  $some_value, # string
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=cut