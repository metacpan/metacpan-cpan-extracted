package WebService::Edgecast::auto::Administration::Type::Customer;
BEGIN {
  $WebService::Edgecast::auto::Administration::Type::Customer::VERSION = '0.01.00';
}
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'EC:WebServices' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %intId_of :ATTR(:get<intId>);
my %strHex_of :ATTR(:get<strHex>);
my %strName_of :ATTR(:get<strName>);
my %strCustomId_of :ATTR(:get<strCustomId>);
my %intStatus_of :ATTR(:get<intStatus>);
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
    [ qw(        intId
        strHex
        strName
        strCustomId
        intStatus
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
        'intId' => \%intId_of,
        'strHex' => \%strHex_of,
        'strName' => \%strName_of,
        'strCustomId' => \%strCustomId_of,
        'intStatus' => \%intStatus_of,
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
        'intId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'strHex' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'strCustomId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'intStatus' => 'SOAP::WSDL::XSD::Typelib::Builtin::short',
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

        'intId' => 'intId',
        'strHex' => 'strHex',
        'strName' => 'strName',
        'strCustomId' => 'strCustomId',
        'intStatus' => 'intStatus',
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







1;


=pod

=head1 NAME

WebService::Edgecast::auto::Administration::Type::Customer

=head1 VERSION

version 0.01.00

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Customer from the namespace EC:WebServices.






=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * intId


=item * strHex


=item * strName


=item * strCustomId


=item * intStatus


=item * strWebsite


=item * strAddress1


=item * strAddress2


=item * strCity


=item * strState


=item * strZip


=item * strCountry


=item * strBillingAddress1


=item * strBillingAddress2


=item * strBillingCity


=item * strBillingState


=item * strBillingZip


=item * strBillingCountry


=item * strNotes


=item * strContactFirstName


=item * strContactLastName


=item * strContactTitle


=item * strContactEmail


=item * strContactPhone


=item * strContactFax


=item * strContactMobile


=item * strBillingContactFirstName


=item * strBillingContactLastName


=item * strBillingContactTitle


=item * strBillingContactEmail


=item * strBillingContactPhone


=item * strBillingContactFax


=item * strBillingContactMobile




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # WebService::Edgecast::auto::Administration::Type::Customer
   intId =>  $some_value, # int
   strHex =>  $some_value, # string
   strName =>  $some_value, # string
   strCustomId =>  $some_value, # string
   intStatus =>  $some_value, # short
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