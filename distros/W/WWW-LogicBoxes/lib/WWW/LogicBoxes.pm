package WWW::LogicBoxes;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Aliases;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( Bool ResponseType Str URI );

use Data::Util qw( is_hash_ref );
use Carp;

our $VERSION = '1.10.0'; # VERSION
# ABSTRACT: Interact with LogicBoxes reseller API

use Readonly;
Readonly my $LIVE_BASE_URI => 'https://httpapi.com';
Readonly my $TEST_BASE_URI => 'https://test.httpapi.com';

has username => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has password => (
    is        => 'ro',
    isa       => Str,
    required  => 0,
    predicate => 'has_password',
);

has api_key => (
    is        => 'ro',
    isa       => Str,
    required  => 0,
    alias     => 'apikey',
    predicate => 'has_api_key',
);

has sandbox => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has response_type => (
    is       => 'rw',
    isa      => ResponseType,
    default  => 'xml',
);

has _base_uri => (
    is       => 'ro',
    isa      => URI,
    lazy     => 1,
    builder  => '_build_base_uri',
);

with 'WWW::LogicBoxes::Role::Command';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args = @_ == 1 && is_hash_ref( $_[0] ) ? %{ $_[0] } : @_;

    # Assign since api_key or apikey are both valid due to backwards compaitability
    my $password = $args{password};
    my $api_key  = $args{apikey} // $args{api_key};

    if( !$password && !$api_key ) {
        croak 'A password or api_key must be specified';
    }

    if( $password && $api_key ) {
        croak "You must specify a password or an api_key, not both";
    }

    return $class->$orig(%args);
};

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _build_base_uri {
    my $self = shift;

    return $self->sandbox ? $TEST_BASE_URI : $LIVE_BASE_URI;
}
## use critic

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes - Interact with LogicBoxes Reseller API

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::LogicBoxes;

    my $logic_boxes = WWW::LogicBoxes->new(
        username      => 'resellerid',

        # You may specify a password OR an api_key
        password      => 'Top S3cr3t!',
        api_key       => 'reseller_api_key',

        response_type => 'json',
        sandbox       => 0,
    );

    my $domain_availabilities = $logic_boxes->check_domain_availability(
        slds => [qw( cpan drzigman brainstormincubator ],
        tlds => [qw( com net org )],
        suggestions => 0,
    );

=head1 DESCRIPTION

L<WWW::LogicBoxes> is a module for interacting with the L<LogicBoxes|http://www.logicboxes.com/> API.  LogicBoxes is a domain registrar and the API performs operations such as checking domain availability, purchasing domains, and managing them.

This module is broken down into two primary components (documented below).  These are L<WWW::LogicBoxes/COMMANDS> which are used for making requests and L<WWW::LogicBoxes/OBJECTS> which are used to represent data.  Below these, documentation for the L<WWW::LogicBoxes> module is included.

=head1 COMMANDS

Commands are how operations are performed using the L<WWW::LogicBoxes> API.  They are seperated into related operations, for documentation on the specific command please see the linked pages.

=head2 L<Raw|WWW::LogicBoxes::Role::Command::Raw>

Low level direct access to the LogicBoxes API.  You rarely want to make use of this and instead want to use the abstracted commands outlined below.

=head2 L<Customer|WWW::LogicBoxes::Role::Command::Customer>

Customer creation and retrieval.  All domains belong to a customer.

=over 4

=item L<create_customer|WWW::LogicBoxes::Role::Command::Customer/create_customer>

=item L<get_customer_by_id|WWW::LogicBoxes::Role::Command::Customer/get_customer_by_id>

=item L<get_customer_by_username|WWW::LogicBoxes::Role::Command::Customer/get_customer_by_username>

=back

=head2 L<Contact|WWW::LogicBoxes::Role::Command::Contact>

Contacts are used in whois information and are required for domain registration.

=over 4

=item L<create_contact|WWW::LogicBoxes::Role::Command::Contact/create_contact>

=item L<get_contact_by_id|WWW::LogicBoxes::Role::Command::Contact/get_contact_by_id>

=item L<update_contact|WWW::LogicBoxes::Role::Command::Contact/update_contact> - OBSOLETE!

=item L<delete_contact_by_id|WWW::LogicBoxes::Role::Command::Contact/delete_contact_by_id>

=item L<get_ca_registrant_agreement|WWW::LogicBoxes::Role::Command::Contact/get_ca_registrant_agreement>

=back

=head2 L<Domain Availability|WWW::LogicBoxes::Role::Command::Domain::Availability>

Used for checking to see if a domain is available for registration as well as getting suggestions of other potentially relevant domains.

=over 4

=item L<check_domain_availability|WWW::LogicBoxes::Role::Command::Domain::Availability/check_domain_availability>

=item L<suggest_domain_names|WWW::LogicBoxes::Role::Command::Domain::Availability/suggest_domain_names>

=back

=head2 L<Domain Registration|WWW::LogicBoxes::Role::Command::Domain::Registration>

New Domain Registration.

=over 4

=item L<register_domain|WWW::LogicBoxes::Role::Command::Domain::Registration/register_domain>

=item L<delete_domain_registration_by_id|WWW::LogicBoxes::Role::Command::Domain::Registration/delete_domain_registration_by_id>

=back

=head2 L<Domain Transfer|WWW::LogicBoxes::Role::Command::Domain::Transfer>

New Domain Transfers.

=over 4

=item L<is_domain_transferable|WWW::LogicBoxes::Role::Command::Domain::Transfer/is_domain_transferable>

=item L<transfer_domain|WWW::LogicBoxes::Role::Command::Domain::Transfer/transfer_domain>

=item L<delete_domain_transfer_by_id|WWW::LogicBoxes::Role::Command::Domain::Transfer/delete_domain_transfer_by_id>

=item L<resend_transfer_approval_mail_by_id|WWW::LogicBoxes::Role::Command::Domain::Transfer/resend_transfer_approval_mail_by_id>

=back

=head2 L<Domain|WWW::LogicBoxes::Role::Command::Domain>

Retrieval of and management of registered domains.

=over 4

=item L<get_domain_by_id|WWW::LogicBoxes::Role::Command::Domain/get_domain_by_id>

=item L<get_domain_by_name|WWW::LogicBoxes::Role::Command::Domain/get_domain_by_name>

=item L<update_domain_contacts|WWW::LogicBoxes::Role::Command::Domain/update_domain_contacts>

=item L<enable_domain_lock_by_id|WWW::LogicBoxes::Role::Command::Domain/enable_domain_lock_by_id>

=item L<disable_domain_lock_by_id|WWW::LogicBoxes::Role::Command::Domain/disable_domain_lock_by_id>

=item L<update_domain_nameservers|WWW::LogicBoxes::Role::Command::Domain/update_domain_nameservers>

=item L<renew_domain|WWW::LogicBoxes::Role::Command::Domain/renew_domain>

=item L<resend_verification_email|WWW::LogicBoxes::Role::Command::Domain/resend_verification_email>

=back

=head2 L<Domain Private Nameservers|WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer>

I<Private> nameservers are those that are based on the registered domain.  For example, a domain of test-domain.com could have private nameservers ns1.test-domain.com and ns2.test-domain.com.

=over 4

=item L<create_private_nameserver|WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer/create_private_nameserver>

=item L<rename_private_nameserver|WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer/rename_private_nameserver>

=item L<modify_private_nameserver_ip|WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer/modify_private_nameserver_ip>

=item L<delete_private_nameserver_ip|WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer/delete_private_nameserver_ip>

=item L<delete_private_nameserver|WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer/delete_private_nameserver>

=back

=head1 OBJECTS

Rather than working with messy JSON objects, WWW::LogicBoxes implements a series of L<Moose> objects for making requests and processing responses.  All commands that take an object have coercion so a HashRef can be used in it's place.

=head2 L<WWW::LogicBoxes>

Primary interface to LogicBoxes.  Documented further below.

=head2 L<WWW::LogicBoxes::Contact>

WHOIS data contacts.  Typically (with few exceptions) domains contains a Registrant, Admin, Technical, and Billing contact.

=head2 L<WWW::LogicBoxes::Contact::US>

Extended contact used for .us domain registrations that contains the required L<Nexus Data|http://www.neustar.us/the-ustld-nexus-requirements/>.

=head2 L<WWW::LogicBoxes::Contact::CA>

Extended contact used for .ca domain registrations that contains the required CPR and CA Registrant Agreement Data.

=head2 L<WWW::LogicBoxes::Contact::CA::Agreement>

The CA Registrant Agreement, contacts for .ca domains must accept it before being allowed to purchase .ca domains.

=head2 L<WWW::LogicBoxes::Customer>

A LogicBoxes customer under the reseller account.

=head2 L<WWW::LogicBoxes::IRTPDetail>

With the changes that became effective on Dec 1st, 2016 to ICANN rules for updating the registrant contact, this object was created to contain information related to an in progress IRTP Verification.  See this object for additional information about the IRTP Changes.

=head2 L<WWW::LogicBoxes::Domain>

A registered domain and all of it's related information.

=head2 L<WWW::LogicBoxes::DomainTransfer>

A pending domain transfer and all of it's related information.

=head2 L<WWW::LogicBoxes::DomainAvailability>

A response to a domain availability request.  Contains the status of the domain and if it is available for registration.

=head2 L<WWW::LogicBoxes::DomainRequest::Registration>

Request to register a domain.

=head2 L<WWW::LogicBoxes::DomainRequest::Transfer>

Request to transfer a domain.

=head2 L<WWW::LogicBoxes::PrivateNameServer>

Private Name Server record for a domain.  Not all domains will have these.

=head1 FACTORIES

In cases where a domain or contact requires additional information (such as .us domains requirning nexus data) factories exist so that the correct subclassed object is returned.  As a consumer, you almost never want to call these directly, rather make use of the above L</COMMANDS> and let this library worry about constructing the correct objects.

=head2 L<WWW::LogicBoxes::Contact::Factory>

Constructs the correct subclassed contact.

=head1 WITH

L<WWW::LogicBoxes::Role::Command>

=head1 ATTRIBUTES

=head2 B<username>

The reseller id to use.

=head2 password

B<NOTE> Password based authentication is now deprecated and is not allowed unless specifically requested from LogicBoxes for your reseller account.  Instead, you should be using the api_key.

=head2 api_key

The API Key used for authentication.  Either the password or the api_key B<MUST> be specified, but B<NOT> both.  For backwards compatability B<apikey> is an alias.

=head2 sandbox

Defaults to false.  Determines if requests should go to the production system L<https://httpapi.com> or the development environment L<https://test.httpapi.com>

=head2 response_type

Defaults to "xml."  Valid values include:

=over 4

=item xml

=item json

=item xml_simple

=back

It should be noted that this setting is really only relevant when making L<Raw|WWW::LogicBoxes::Role::Command::Raw> requests of the LogicBoxes API.  When doing so this attribute defines the format of the responses.

Defaults to

=head1 METHODS

=head2 new

    my $logic_boxes = WWW::LogicBoxes->new(
        username      => 'resellerid',

        # You may specify a password OR an api_key
        password      => 'Top S3cr3t!',
        api_key       => 'reseller_api_key',

        response_type => 'json',
        sandbox       => 0,
    );

Creates a new instance of WWW::LogicBoxes that can be used for API Requests.

=head1 AUTHORS

Robert Stone, C<< <drzigman AT cpan DOT org > >>

=head1 ACKNOWLEDGMENTS

Thanks to L<HostGator|http://hostgator.com> and L<BrainStorm Incubator|http://brainstormincubator.com> for funding the development of this module and providing test resources.

=head1 CONTRIBUTIONS

Special thanks to the following individuals who have offered commits, bug reports, and/or pull requests.

=over 4

=item Doug Schrag

=item Brandon Husbands

=item Slaven Rezic

=item David Foster

=back

=head1 COPYRIGHT & LICENSE

Copyright 2016 Robert Stone

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU Lesser General Public License as published by the Free Software Foundation; or any compatible license.

See http://dev.perl.org/licenses/ for more information.
