
package WebService::Edgecast::auto::Administration::Element::CustomerUpdate;
BEGIN {
  $WebService::Edgecast::auto::Administration::Element::CustomerUpdate::VERSION = '0.01.00';
}
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'EC:WebServices' }

__PACKAGE__->__set_name('CustomerUpdate');
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
my %strCompanyName_of :ATTR(:get<strCompanyName>);
my %strWebsite_of :ATTR(:get<strWebsite>);
my %strAddress1_of :ATTR(:get<strAddress1>);
my %strAddress2_of :ATTR(:get<strAddress2>);
my %strCity_of :ATTR(:get<strCity>);
my %strState_of :ATTR(:get<strState>);
my %strZip_of :ATTR(:get<strZip>);
my %strCountry_of :ATTR(:get<strCountry>);
my %strBillingAddress1_of :ATTR(:get<strBillingAddress1>);
my %strBillingAddress2_of :ATTR(:get<strBillingAddress2>);
my %strBillingCity_of :ATTR(:get<strBillingCity>);
my %strBillingState_of :ATTR(:get<strBillingState>);
my %strBillingZip_of :ATTR(:get<strBillingZip>);
my %strBillingCountry_of :ATTR(:get<strBillingCountry>);
my %strNotes_of :ATTR(:get<strNotes>);
my %strContactFirstName_of :ATTR(:get<strContactFirstName>);
my %strContactLastName_of :ATTR(:get<strContactLastName>);
my %strContactTitle_of :ATTR(:get<strContactTitle>);
my %strContactEmail_of :ATTR(:get<strContactEmail>);
my %strContactPhone_of :ATTR(:get<strContactPhone>);
my %strContactFax_of :ATTR(:get<strContactFax>);
my %strContactMobile_of :ATTR(:get<strContactMobile>);
my %strBillingContactFirstName_of :ATTR(:get<strBillingContactFirstName>);
my %strBillingContactLastName_of :ATTR(:get<strBillingContactLastName>);
my %strBillingContactTitle_of :ATTR(:get<strBillingContactTitle>);
my %strBillingContactEmail_of :ATTR(:get<strBillingContactEmail>);
my %strBillingContactPhone_of :ATTR(:get<strBillingContactPhone>);
my %strBillingContactFax_of :ATTR(:get<strBillingContactFax>);
my %strBillingContactMobile_of :ATTR(:get<strBillingContactMobile>);

__PACKAGE__->_factory(
    [ qw(        strCredential
        strCustomerId
        strCustomId
        strCompanyName
        strWebsite
        strAddress1
        strAddress2
        strCity
        strState
        strZip
        strCountry
        strBillingAddress1
        strBillingAddress2
        strBillingCity
        strBillingState
        strBillingZip
        strBillingCountry
        strNotes
        strContactFirstName
        strContactLastName
        strContactTitle
        strContactEmail
        strContactPhone
        strContactFax
        strContactMobile
        strBillingContactFirstName
        strBillingContactLastName
        strBillingContactTitle
        strBillingContactEmail
        strBillingContactPhone
        strBillingContactFax
        strBillingContactMobile

    ) ],
    {
        'strCredential' => \%strCredential_of,
        'strCustomerId' => \%strCustomerId_of,
        'strCustomId' => \%strCustomId_of,
        'strCompanyName' => \%strCompanyName_of,
        'strWebsite' => \%strWebsite_of,
        'strAddress1' => \%strAddress1_of,
        'strAddress2' => \%strAddress2_of,
        'strCity' => \%strCity_of,
        'strState' => \%strState_of,
        'strZip' => \%strZip_of,
        'strCountry' => \%strCountry_of,
        'strBillingAddress1' => \%strBillingAddress1_of,
        'strBillingAddress2' => \%strBillingAddress2_of,
        'strBillingCity' => \%strBillingCity_of,
        'strBillingState' => \%strBillingState_of,
        'strBillingZip' => \%strBillingZip_of,
        'strBillingCountry' => \%strBillingCountry_of,
        'strNotes' => \%strNotes_of,
        'strContactFirstName' => \%strContactFirstName_of,
        'strContactLastName' => \%strContactLastName_of,
        'strContactTitle' => \%strContactTitle_of,
        'strContactEmail' => \%strContactEmail_of,
        'strContactPhone' => \%strContactPhone_of,
        'strContactFax' => \%strContactFax_of,
        'strContactMobile' => \%strContactMobile_of,
        'strBillingContactFirstName' => \%strBillingContactFirstName_of,
        'strBillingContactLastName' => \%strBillingContactLastName_of,
        'strBillingContactTitle' => \%strBillingContactTitle_of,
        'strBillingContactEmail' => \%strBillingContactEmail_of,
        'strBillingContactPhone' => \%strBillingContactPhone_of,
        'strBillingContactFax' => \%strBillingContactFax_of,
        'strBillingContactMobile' => \%strBillingContactMobile_of,
    },
    {
        'strCredential' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCustomId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCompanyName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strWebsite' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strAddress1' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strAddress2' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCity' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strState' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strZip' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCountry' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingAddress1' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingAddress2' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingCity' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingState' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingZip' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingCountry' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strNotes' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strContactFirstName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strContactLastName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strContactTitle' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strContactEmail' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strContactPhone' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strContactFax' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strContactMobile' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingContactFirstName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingContactLastName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingContactTitle' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingContactEmail' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingContactPhone' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingContactFax' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strBillingContactMobile' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'strCredential' => 'strCredential',
        'strCustomerId' => 'strCustomerId',
        'strCustomId' => 'strCustomId',
        'strCompanyName' => 'strCompanyName',
        'strWebsite' => 'strWebsite',
        'strAddress1' => 'strAddress1',
        'strAddress2' => 'strAddress2',
        'strCity' => 'strCity',
        'strState' => 'strState',
        'strZip' => 'strZip',
        'strCountry' => 'strCountry',
        'strBillingAddress1' => 'strBillingAddress1',
        'strBillingAddress2' => 'strBillingAddress2',
        'strBillingCity' => 'strBillingCity',
        'strBillingState' => 'strBillingState',
        'strBillingZip' => 'strBillingZip',
        'strBillingCountry' => 'strBillingCountry',
        'strNotes' => 'strNotes',
        'strContactFirstName' => 'strContactFirstName',
        'strContactLastName' => 'strContactLastName',
        'strContactTitle' => 'strContactTitle',
        'strContactEmail' => 'strContactEmail',
        'strContactPhone' => 'strContactPhone',
        'strContactFax' => 'strContactFax',
        'strContactMobile' => 'strContactMobile',
        'strBillingContactFirstName' => 'strBillingContactFirstName',
        'strBillingContactLastName' => 'strBillingContactLastName',
        'strBillingContactTitle' => 'strBillingContactTitle',
        'strBillingContactEmail' => 'strBillingContactEmail',
        'strBillingContactPhone' => 'strBillingContactPhone',
        'strBillingContactFax' => 'strBillingContactFax',
        'strBillingContactMobile' => 'strBillingContactMobile',
    }
);

} # end BLOCK






} # end of BLOCK



1;


=pod

=head1 NAME

WebService::Edgecast::auto::Administration::Element::CustomerUpdate

=head1 VERSION

version 0.01.00

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
CustomerUpdate from the namespace EC:WebServices.







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




=item * strCompanyName

 $element->set_strCompanyName($data);
 $element->get_strCompanyName();




=item * strWebsite

 $element->set_strWebsite($data);
 $element->get_strWebsite();




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




=item * strBillingAddress1

 $element->set_strBillingAddress1($data);
 $element->get_strBillingAddress1();




=item * strBillingAddress2

 $element->set_strBillingAddress2($data);
 $element->get_strBillingAddress2();




=item * strBillingCity

 $element->set_strBillingCity($data);
 $element->get_strBillingCity();




=item * strBillingState

 $element->set_strBillingState($data);
 $element->get_strBillingState();




=item * strBillingZip

 $element->set_strBillingZip($data);
 $element->get_strBillingZip();




=item * strBillingCountry

 $element->set_strBillingCountry($data);
 $element->get_strBillingCountry();




=item * strNotes

 $element->set_strNotes($data);
 $element->get_strNotes();




=item * strContactFirstName

 $element->set_strContactFirstName($data);
 $element->get_strContactFirstName();




=item * strContactLastName

 $element->set_strContactLastName($data);
 $element->get_strContactLastName();




=item * strContactTitle

 $element->set_strContactTitle($data);
 $element->get_strContactTitle();




=item * strContactEmail

 $element->set_strContactEmail($data);
 $element->get_strContactEmail();




=item * strContactPhone

 $element->set_strContactPhone($data);
 $element->get_strContactPhone();




=item * strContactFax

 $element->set_strContactFax($data);
 $element->get_strContactFax();




=item * strContactMobile

 $element->set_strContactMobile($data);
 $element->get_strContactMobile();




=item * strBillingContactFirstName

 $element->set_strBillingContactFirstName($data);
 $element->get_strBillingContactFirstName();




=item * strBillingContactLastName

 $element->set_strBillingContactLastName($data);
 $element->get_strBillingContactLastName();




=item * strBillingContactTitle

 $element->set_strBillingContactTitle($data);
 $element->get_strBillingContactTitle();




=item * strBillingContactEmail

 $element->set_strBillingContactEmail($data);
 $element->get_strBillingContactEmail();




=item * strBillingContactPhone

 $element->set_strBillingContactPhone($data);
 $element->get_strBillingContactPhone();




=item * strBillingContactFax

 $element->set_strBillingContactFax($data);
 $element->get_strBillingContactFax();




=item * strBillingContactMobile

 $element->set_strBillingContactMobile($data);
 $element->get_strBillingContactMobile();





=back


=head1 METHODS

=head2 new

 my $element = WebService::Edgecast::auto::Administration::Element::CustomerUpdate->new($data);

Constructor. The following data structure may be passed to new():

 {
   strCredential =>  $some_value, # string
   strCustomerId =>  $some_value, # string
   strCustomId =>  $some_value, # string
   strCompanyName =>  $some_value, # string
   strWebsite =>  $some_value, # string
   strAddress1 =>  $some_value, # string
   strAddress2 =>  $some_value, # string
   strCity =>  $some_value, # string
   strState =>  $some_value, # string
   strZip =>  $some_value, # string
   strCountry =>  $some_value, # string
   strBillingAddress1 =>  $some_value, # string
   strBillingAddress2 =>  $some_value, # string
   strBillingCity =>  $some_value, # string
   strBillingState =>  $some_value, # string
   strBillingZip =>  $some_value, # string
   strBillingCountry =>  $some_value, # string
   strNotes =>  $some_value, # string
   strContactFirstName =>  $some_value, # string
   strContactLastName =>  $some_value, # string
   strContactTitle =>  $some_value, # string
   strContactEmail =>  $some_value, # string
   strContactPhone =>  $some_value, # string
   strContactFax =>  $some_value, # string
   strContactMobile =>  $some_value, # string
   strBillingContactFirstName =>  $some_value, # string
   strBillingContactLastName =>  $some_value, # string
   strBillingContactTitle =>  $some_value, # string
   strBillingContactEmail =>  $some_value, # string
   strBillingContactPhone =>  $some_value, # string
   strBillingContactFax =>  $some_value, # string
   strBillingContactMobile =>  $some_value, # string
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=cut