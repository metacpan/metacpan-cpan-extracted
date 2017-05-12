package WWW::eNom::Types;

use strict;
use warnings;

use Data::Validate::IP qw( is_ipv4 is_ipv6 );
use Data::Validate::Domain qw( is_domain );
use Data::Validate::Email qw( is_email );
use URI;

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: WWW::eNom Moose Type Library

use MooseX::Types -declare => [qw(
    ArrayRef
    Bool
    HashRef
    Int
    PositiveInt
    Str
    Strs

    IP
    IPs
    IPv4
    IPv4s
    IPv6
    IPv6s

    ContactType
    DateTime
    DomainName
    DomainNames
    EmailAddress
    HTTPTiny
    NexusPurpose
    NexusCategory
    NumberPhone
    ResponseType
    TransferVerificationMethod
    URI

    Contact
    Domain
    DomainAvailability
    DomainAvailabilities
    DomainRegistration
    DomainTransfer
    IRTPDetail
    PhoneNumber
    PrivateNameServer
    PrivateNameServers
)];

use MooseX::Types::Moose
    ArrayRef => { -as => 'MooseArrayRef' },
    Bool     => { -as => 'MooseBool' },
    HashRef  => { -as => 'MooseHashRef' },
    Int      => { -as => 'MooseInt' },
    Str      => { -as => 'MooseStr' };

subtype ArrayRef, as MooseArrayRef;
subtype Bool,     as MooseBool;
subtype HashRef,  as MooseHashRef;
subtype Int,      as MooseInt;
subtype Str,      as MooseStr;
subtype Strs,     as ArrayRef[Str];

enum ContactType,   [qw( Registrant Tech Admin AuxBilling )];
enum NexusCategory, [qw( C11 C12 C21 C31 C32 )];
enum NexusPurpose,  [qw( P1 P2 P3 P4 P5 )];

subtype DomainName, as Str,
    where { is_domain( $_ ) },
    message { "$_ is not a valid domain" };
subtype DomainNames, as ArrayRef[DomainName];

subtype EmailAddress, as Str,
    where { is_email( $_ ) },
    message { "$_ is not a valid email address" };

subtype PositiveInt, as Int,
    where { $_ > 0 },
    message { "$_ is not a positive integer" };

my @response_types = qw( xml xml_simple html text );
subtype ResponseType, as Str,
    where {
        my $response_type = $_;
        grep { $response_type eq $_ } @response_types;
    },
    message { 'response_type must be one of: ' . join ', ', @response_types };

class_type DateTime,    { class => 'DateTime' };
class_type HTTPTiny,    { class => 'HTTP::Tiny' };
class_type NumberPhone, { class => 'Number::Phone' };
class_type URI,         { class => 'URI' };
coerce URI, from Str, via { URI->new( $_ ) };

enum TransferVerificationMethod, [qw( Fax Autoverification )];

class_type Contact,            { class => 'WWW::eNom::Contact' };
class_type Domain,             { class => 'WWW::eNom::Domain' };
class_type DomainAvailability, { class => 'WWW::eNom::DomainAvailability' };
subtype DomainAvailabilities, as ArrayRef[DomainAvailability];

class_type DomainRegistration, { class => 'WWW::eNom::DomainRequest::Registration' };
coerce DomainRegistration, from HashRef, via { WWW::eNom::DomainRequest::Registration->new( $_ ) };

class_type DomainTransfer,     { class => 'WWW::eNom::DomainRequest::Transfer' };
coerce DomainTransfer, from HashRef, via { WWW::eNom::DomainRequest::Transfer->new( $_ ) };

class_type PhoneNumber,        { class => 'WWW::eNom::PhoneNumber' };
coerce PhoneNumber, from Str,
    via { WWW::eNom::PhoneNumber->new( $_ ) };
coerce PhoneNumber, from NumberPhone,
    via { WWW::eNom::PhoneNumber->new( $_->format ) };

class_type PrivateNameServer, { class => 'WWW::eNom::PrivateNameServer' };
coerce PrivateNameServer, from HashRef,
    via { WWW::eNom::PrivateNameServer->new( $_ ) };
subtype PrivateNameServers, as ArrayRef[PrivateNameServer];

subtype IPv4, as Str,
    where { is_ipv4( $_ ) },
    message { "$_ is not a valid ipv4 IP Address" };
subtype IPv4s, as ArrayRef[IPv4];

subtype IPv6, as Str,
    where { is_ipv6( $_ ) },
    message { "$_ is not a valid ipv6 IP Address" };
subtype IPv6s, as ArrayRef[IPv6];

subtype IP, as IPv4 | IPv6;
subtype IPs, as ArrayRef[IP];

class_type IRTPDetail, { class => 'WWW::eNom::IRTPDetail' };

1;

__END__
