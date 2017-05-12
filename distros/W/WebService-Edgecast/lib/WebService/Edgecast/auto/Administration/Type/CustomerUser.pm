package WebService::Edgecast::auto::Administration::Type::CustomerUser;
BEGIN {
  $WebService::Edgecast::auto::Administration::Type::CustomerUser::VERSION = '0.01.00';
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

my %Id_of :ATTR(:get<Id>);
my %Email_of :ATTR(:get<Email>);
my %TimeZoneId_of :ATTR(:get<TimeZoneId>);
my %IsAdmin_of :ATTR(:get<IsAdmin>);
my %FirstName_of :ATTR(:get<FirstName>);
my %LastName_of :ATTR(:get<LastName>);
my %Password_of :ATTR(:get<Password>);
my %Title_of :ATTR(:get<Title>);
my %Phone_of :ATTR(:get<Phone>);
my %Fax_of :ATTR(:get<Fax>);
my %Mobile_of :ATTR(:get<Mobile>);
my %Address1_of :ATTR(:get<Address1>);
my %Address2_of :ATTR(:get<Address2>);
my %City_of :ATTR(:get<City>);
my %State_of :ATTR(:get<State>);
my %Zip_of :ATTR(:get<Zip>);
my %Country_of :ATTR(:get<Country>);

__PACKAGE__->_factory(
    [ qw(        Id
        Email
        TimeZoneId
        IsAdmin
        FirstName
        LastName
        Password
        Title
        Phone
        Fax
        Mobile
        Address1
        Address2
        City
        State
        Zip
        Country

    ) ],
    {
        'Id' => \%Id_of,
        'Email' => \%Email_of,
        'TimeZoneId' => \%TimeZoneId_of,
        'IsAdmin' => \%IsAdmin_of,
        'FirstName' => \%FirstName_of,
        'LastName' => \%LastName_of,
        'Password' => \%Password_of,
        'Title' => \%Title_of,
        'Phone' => \%Phone_of,
        'Fax' => \%Fax_of,
        'Mobile' => \%Mobile_of,
        'Address1' => \%Address1_of,
        'Address2' => \%Address2_of,
        'City' => \%City_of,
        'State' => \%State_of,
        'Zip' => \%Zip_of,
        'Country' => \%Country_of,
    },
    {
        'Id' => 'SOAP::WSDL::XSD::Typelib::Builtin::unsignedInt',
        'Email' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'TimeZoneId' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'IsAdmin' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'FirstName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'LastName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Password' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Title' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Phone' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Fax' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Mobile' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Address1' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Address2' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'City' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'State' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Zip' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Country' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'Id' => 'Id',
        'Email' => 'Email',
        'TimeZoneId' => 'TimeZoneId',
        'IsAdmin' => 'IsAdmin',
        'FirstName' => 'FirstName',
        'LastName' => 'LastName',
        'Password' => 'Password',
        'Title' => 'Title',
        'Phone' => 'Phone',
        'Fax' => 'Fax',
        'Mobile' => 'Mobile',
        'Address1' => 'Address1',
        'Address2' => 'Address2',
        'City' => 'City',
        'State' => 'State',
        'Zip' => 'Zip',
        'Country' => 'Country',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

WebService::Edgecast::auto::Administration::Type::CustomerUser

=head1 VERSION

version 0.01.00

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
CustomerUser from the namespace EC:WebServices.






=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * Id


=item * Email


=item * TimeZoneId


=item * IsAdmin


=item * FirstName


=item * LastName


=item * Password


=item * Title


=item * Phone


=item * Fax


=item * Mobile


=item * Address1


=item * Address2


=item * City


=item * State


=item * Zip


=item * Country




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # WebService::Edgecast::auto::Administration::Type::CustomerUser
   Id =>  $some_value, # unsignedInt
   Email =>  $some_value, # string
   TimeZoneId =>  $some_value, # int
   IsAdmin =>  $some_value, # boolean
   FirstName =>  $some_value, # string
   LastName =>  $some_value, # string
   Password =>  $some_value, # string
   Title =>  $some_value, # string
   Phone =>  $some_value, # string
   Fax =>  $some_value, # string
   Mobile =>  $some_value, # string
   Address1 =>  $some_value, # string
   Address2 =>  $some_value, # string
   City =>  $some_value, # string
   State =>  $some_value, # string
   Zip =>  $some_value, # string
   Country =>  $some_value, # string
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut