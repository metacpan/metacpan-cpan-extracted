
package WebService::Edgecast::auto::Administration::Element::CustomerUserUpdate;
BEGIN {
  $WebService::Edgecast::auto::Administration::Element::CustomerUserUpdate::VERSION = '0.01.00';
}
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'EC:WebServices' }

__PACKAGE__->__set_name('CustomerUserUpdate');
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
my %intCustomerUserId_of :ATTR(:get<intCustomerUserId>);
my %strFirstName_of :ATTR(:get<strFirstName>);
my %strLastName_of :ATTR(:get<strLastName>);
my %strEmail_of :ATTR(:get<strEmail>);
my %strPassword_of :ATTR(:get<strPassword>);
my %strTitle_of :ATTR(:get<strTitle>);
my %strAddress1_of :ATTR(:get<strAddress1>);
my %strAddress2_of :ATTR(:get<strAddress2>);
my %strCity_of :ATTR(:get<strCity>);
my %strState_of :ATTR(:get<strState>);
my %strZip_of :ATTR(:get<strZip>);
my %strCountry_of :ATTR(:get<strCountry>);
my %strPhone_of :ATTR(:get<strPhone>);
my %strFax_of :ATTR(:get<strFax>);
my %strMobile_of :ATTR(:get<strMobile>);
my %strTimeZoneId_of :ATTR(:get<strTimeZoneId>);

__PACKAGE__->_factory(
    [ qw(        strCredential
        strCustomerId
        strCustomId
        intCustomerUserId
        strFirstName
        strLastName
        strEmail
        strPassword
        strTitle
        strAddress1
        strAddress2
        strCity
        strState
        strZip
        strCountry
        strPhone
        strFax
        strMobile
        strTimeZoneId

    ) ],
    {
        'strCredential' => \%strCredential_of,
        'strCustomerId' => \%strCustomerId_of,
        'strCustomId' => \%strCustomId_of,
        'intCustomerUserId' => \%intCustomerUserId_of,
        'strFirstName' => \%strFirstName_of,
        'strLastName' => \%strLastName_of,
        'strEmail' => \%strEmail_of,
        'strPassword' => \%strPassword_of,
        'strTitle' => \%strTitle_of,
        'strAddress1' => \%strAddress1_of,
        'strAddress2' => \%strAddress2_of,
        'strCity' => \%strCity_of,
        'strState' => \%strState_of,
        'strZip' => \%strZip_of,
        'strCountry' => \%strCountry_of,
        'strPhone' => \%strPhone_of,
        'strFax' => \%strFax_of,
        'strMobile' => \%strMobile_of,
        'strTimeZoneId' => \%strTimeZoneId_of,
    },
    {
        'strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCustomId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'intCustomerUserId' => 'SOAP::WSDL::XSD::Typelib::Builtin::unsignedInt',
        'strFirstName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strLastName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strEmail' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strPassword' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strTitle' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strAddress1' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strAddress2' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCity' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strState' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strZip' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCountry' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strPhone' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strFax' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strMobile' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strTimeZoneId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'strCredential' => 'strCredential',
        'strCustomerId' => 'strCustomerId',
        'strCustomId' => 'strCustomId',
        'intCustomerUserId' => 'intCustomerUserId',
        'strFirstName' => 'strFirstName',
        'strLastName' => 'strLastName',
        'strEmail' => 'strEmail',
        'strPassword' => 'strPassword',
        'strTitle' => 'strTitle',
        'strAddress1' => 'strAddress1',
        'strAddress2' => 'strAddress2',
        'strCity' => 'strCity',
        'strState' => 'strState',
        'strZip' => 'strZip',
        'strCountry' => 'strCountry',
        'strPhone' => 'strPhone',
        'strFax' => 'strFax',
        'strMobile' => 'strMobile',
        'strTimeZoneId' => 'strTimeZoneId',
    }
);

} # end BLOCK






} # end of BLOCK



1;


=pod

=head1 NAME

WebService::Edgecast::auto::Administration::Element::CustomerUserUpdate

=head1 VERSION

version 0.01.00

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
CustomerUserUpdate from the namespace EC:WebServices.







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




=item * intCustomerUserId

 $element->set_intCustomerUserId($data);
 $element->get_intCustomerUserId();




=item * strFirstName

 $element->set_strFirstName($data);
 $element->get_strFirstName();




=item * strLastName

 $element->set_strLastName($data);
 $element->get_strLastName();




=item * strEmail

 $element->set_strEmail($data);
 $element->get_strEmail();




=item * strPassword

 $element->set_strPassword($data);
 $element->get_strPassword();




=item * strTitle

 $element->set_strTitle($data);
 $element->get_strTitle();




=item * strAddress1

 $element->set_strAddress1($data);
 $element->get_strAddress1();




=item * strAddress2

 $element->set_strAddress2($data);
 $element->get_strAddress2();




=item * strCity

 $element->set_strCity($data);
 $element->get_strCity();




=item * strState

 $element->set_strState($data);
 $element->get_strState();




=item * strZip

 $element->set_strZip($data);
 $element->get_strZip();




=item * strCountry

 $element->set_strCountry($data);
 $element->get_strCountry();




=item * strPhone

 $element->set_strPhone($data);
 $element->get_strPhone();




=item * strFax

 $element->set_strFax($data);
 $element->get_strFax();




=item * strMobile

 $element->set_strMobile($data);
 $element->get_strMobile();




=item * strTimeZoneId

 $element->set_strTimeZoneId($data);
 $element->get_strTimeZoneId();





=back


=head1 METHODS

=head2 new

 my $element = WebService::Edgecast::auto::Administration::Element::CustomerUserUpdate->new($data);

Constructor. The following data structure may be passed to new():

 {
   strCredential =>  $some_value, # string
   strCustomerId =>  $some_value, # string
   strCustomId =>  $some_value, # string
   intCustomerUserId =>  $some_value, # unsignedInt
   strFirstName =>  $some_value, # string
   strLastName =>  $some_value, # string
   strEmail =>  $some_value, # string
   strPassword =>  $some_value, # string
   strTitle =>  $some_value, # string
   strAddress1 =>  $some_value, # string
   strAddress2 =>  $some_value, # string
   strCity =>  $some_value, # string
   strState =>  $some_value, # string
   strZip =>  $some_value, # string
   strCountry =>  $some_value, # string
   strPhone =>  $some_value, # string
   strFax =>  $some_value, # string
   strMobile =>  $some_value, # string
   strTimeZoneId =>  $some_value, # string
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=cut