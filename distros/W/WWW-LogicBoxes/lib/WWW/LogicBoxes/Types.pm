package WWW::LogicBoxes::Types;

use strict;
use warnings;

use Data::Validate::Domain qw( is_domain );
use Data::Validate::Email qw( is_email );
use Data::Validate::IP qw( is_ipv4 is_ipv6 );
use Data::Validate::URI qw( is_uri );

our $VERSION = '1.11.0'; # VERSION
# ABSTRACT: WWW::LogicBoxes Moose Type Library

use MooseX::Types -declare => [qw(
    ArrayRef
    Bool
    HashRef
    Int
    Str
    Strs

    ContactType
    CPR
    CPRIndividual
    CPRNonIndividual
    DateTime
    DomainName
    DomainNames
    DomainStatus
    EmailAddress
    InvoiceOption
    IP
    IPs
    IPv4
    IPv4s
    IPv6
    IPv6s
    IRTPFOAStatus
    IRTPStatus
    Language
    NexusCategory
    NexusPurpose
    NumberPhone
    Password
    PhoneNumber
    ResponseType
    URI
    VerificationStatus

    Contact
    Customer
    Domain
    DomainAvailability
    DomainAvailabilities
    DomainRegistration
    DomainTransfer
    IRTPDetail
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

enum ContactType, [qw(
    Contact
    AtContact
    CaContact
    CnContact
    CoContact
    CoopContact
    DeContact
    EsContact
    EuContact
    NlContact
    RuContact
    UkContact
)];
enum CPRIndividual,    [qw( ABO CCT LGR RES )];
enum CPRNonIndividual, [qw( ASS CCO EDU GOV HOP INB LAM MAJ OMK PLT PRT TDM TRD TRS )];
subtype CPR, as CPRIndividual | CPRNonIndividual;

enum DomainStatus,       [ 'InActive', 'Active', 'Suspended', 'Pending Delete Restorable',
    'QueuedForDeletion', 'Deleted', 'Archived' ];
enum InvoiceOption,      [qw( NoInvoice PayInvoice KeepInvoice )];
enum IRTPFOAStatus,      [qw( PENDING APPROVED DISAPPROVED )];
enum IRTPStatus,         [qw( PENDING REVOKED EXPIRED FAILED APPROVED SUCCESS REMOTE_FAILURE )];
enum Language,           [qw( en )];
enum NexusCategory,      [qw( C11 C12 C21 C31 C32 )];
enum NexusPurpose,       [qw( P1 P2 P3 P4 P5 )];
enum ResponseType,       [qw( xml json xml_simple )];
enum VerificationStatus, [qw( Verified Pending Suspended NA )];

class_type Contact, { class => 'WWW::LogicBoxes::Contact' };
coerce Contact, from HashRef, via {
    exists $_->{nexus_purpose} and return WWW::LogicBoxes::Contact::US->new( $_ );
    return WWW::LogicBoxes::Contact->new( $_ );
};

class_type Customer, { class => 'WWW::LogicBoxes::Customer' };
coerce Customer, from HashRef,
    via { WWW::LogicBoxes::Customer->new( $_ ) };

class_type DateTime, { class => 'DateTime' };

class_type Domain, { class => 'WWW::LogicBoxes::Domain' };
coerce Domain, from HashRef,
    via { WWW::LogicBoxes::Domain->new( $_ ) };

class_type DomainAvailability, { class => 'WWW::LogicBoxes::DomainAvailability' };
subtype DomainAvailabilities, as ArrayRef[DomainAvailability];

class_type DomainRegistration, { class => 'WWW::LogicBoxes::DomainRequest::Registration' };
coerce DomainRegistration, from HashRef,
    via { WWW::LogicBoxes::DomainRequest::Registration->new( $_ ) };

class_type DomainTransfer, { class => 'WWW::LogicBoxes::DomainRequest::Transfer' };
coerce DomainTransfer, from HashRef,
    via { WWW::LogicBoxes::DomainRequest::Transfer->new( $_ ) };

class_type IRTPDetail,  { class => 'WWW::LogicBoxes::IRTPDetail' };

class_type NumberPhone, { class => 'Number::Phone' };
class_type PhoneNumber, { class => 'WWW::LogicBoxes::PhoneNumber' };
coerce PhoneNumber, from Str,
    via { WWW::LogicBoxes::PhoneNumber->new( $_ ) };
coerce PhoneNumber, from NumberPhone,
    via { WWW::LogicBoxes::PhoneNumber->new( $_->format ) };

class_type PrivateNameServer, { class => 'WWW::LogicBoxes::PrivateNameServer' };
coerce PrivateNameServer, from HashRef,
    via { WWW::LogicBoxes::PrivateNameServer->new( $_ ) };
subtype PrivateNameServers, as ArrayRef[PrivateNameServer];

subtype DomainName, as Str,
    where { is_domain( $_ ) },
    message { "$_ is not a valid domain" };
subtype DomainNames, as ArrayRef[DomainName];

subtype EmailAddress, as Str,
    where { is_email( $_ ) },
    message { "$_ is not a valid email address" };

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

subtype Password, as Str,
    where {(
        $_ =~ m/([a-zA-Z0-9])+/                  # Alphanumeric
        && length($_) >= 8 && length($_) <= 15   # Between 8 and 15 Characters
    )},
    message { "$_ is not a valid password.  It must be alphanumeric and between 8 and 15 characters" };

subtype URI, as Str,
    where { is_uri( $_ ) },
    message { "$_ is not a valid URI" };

1;

__END__
