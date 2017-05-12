package WWW::eNom;

use strict;
use warnings;
use utf8;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::eNom::Types qw( Bool Str ResponseType URI );

use URI;

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: Interact with eNom, Inc.'s Reseller API

has username => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has password => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has test => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has response_type => (
    is      => 'rw',
    isa     => ResponseType,
    default => 'xml_simple',
);

has _uri => (
    isa     => URI,
    is      => 'ro',
    lazy    => 1,
    builder => '_build_uri',
);

with 'WWW::eNom::Role::Command';

sub _build_uri {
    my $self = shift;

    my $subdomain = $self->test ? 'resellertest' : 'reseller';
    return URI->new("https://$subdomain.enom.com/interface.asp");
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WWW::eNom - Interact with eNom, Inc.'s reseller API

=head1 SYNOPSIS

    use WWW::eNom;

    my $eNom = WWW::eNom->new(
        username      => "resellid",
        password      => "resellpw",
        response_type => "xml_simple",  # Optional, defaults to xml_simple
        test          => 1              # Optional, defaults to 0 ( production )
    );

    # Check If Domains Are Available
    my $domain_availabilities = $eNom->check_domain_availability(
        slds => [qw( cpan drzigman brainstormincubator )],
        tlds => [qw( com net org )],
        suggestions => 0,
    );

=head1 DESCRIPTION

L<WWW::eNom> is a module for interacting with the L<eNom|https://www.enom.com> API.  eNom is a domain registrar and the API performs operations such as checking domain availability, purchasing domains, and managing them.

This module is broken down into two primary components (documented below).  These are L<WWW::eNom/COMMANDS> which are used for making requests and L<WWW::eNom/OBJECTS> which are used to represent data.  Below these, documentation for the L<WWW::eNom> module is included.

=head1 COMMANDS

Commands are how operations are performed using the L<WWW:eNom> API.  They are separated into related operations, for documentation on the specific command please see the linked pages.

=head2 L<Raw|WWW::eNom::Role::Command::Raw>

Love level direct access to the eNom API.  You rarely want to make use of this and instead want to use the abstracted commands outline below.

=head2 L<Contact|WWW::eNom::Role::Command::Contact>

Contact retrieval.

=over 4

=item L<get_contacts_by_domain_name|WWW::eNom::Role::Command::Contact/get_contacts_by_domain_name>

=item L<update_contacts_for_domain_name|WWW::eNom::Role::Command::Contact/update_contacts_for_domain_name>

=back

=head2 L<Domain Availability|WWW::eNom::Role::Command::Domain::Availability>

Use for checking to see if a domain is available for registration as well as getting suggestions of other potentially relevant domains.

=over 4

=item L<check_domain_availability|WWW::eNom::Role::Command::Domain::Availability/check_domain_availability>

=item L<suggest_domain_names|WWW::eNom::Role::Command::Domain::Availability/suggest_domain_names>

=back

=head2 L<Domain Registration|WWW::eNom::Role::Command::Domain::Registration>

New Domain Registration.

=over 4

=item L<register_domain|WWW::eNom::Role::Command::Domain::Registration/register_domain>

=back

=head2 L<Domain Transfer|WWW::eNom::Role::Command::Domain::Transfer>

New Domain Transfers.

=over 4

=item L<transfer_domain|WWW::eNom::Role::Command::Domain::Transfer/transfer_domain>

=item L<get_transfer_by_order_id|WWW::eNom::Role::Command::Domain::Transfer/get_transfer_by_order_id>

=item L<get_transfer_by_name|WWW::eNom::Role::Command::Domain::Transfer/get_transfer_by_name>

=item L<get_transfer_order_id_from_parent_order_id|WWW::eNom::Role::Command::Domain::Transfer/get_transfer_order_id_from_parent_order_id>

=back

=head2 L<Domain|WWW::eNom::Role::Command::Domain>

Domain retrieval and management.

=over 4

=item L<get_domain_by_name|WWW::eNom::Role::Command::Domain/get_domain_by_name>

=item L<get_is_domain_locked_by_name|WWW::eNom::Role::Command::Domain/get_is_domain_locked_by_name>

=item L<enable_domain_lock_by_name|WWW::eNom::Role::Command::Domain/enable_domain_lock_by_name>

=item L<disable_domain_lock_by_name|WWW::eNom::Role::Command::Domain/disable_domain_lock_by_name>

=item L<get_domain_name_servers_by_name|WWW::eNom::Role::Command::Domain/get_domain_name_servers_by_name>

=item L<update_nameservers_for_domain_name|WWW::eNom::Role::Command::Domain/update_nameservers_for_domain_name>

=item L<get_is_domain_auto_renew_by_name|WWW::eNom::Role::Command::Domain/get_is_domain_auto_renew_by_name>

=item L<enable_domain_auto_renew_by_name|WWW::eNom::Role::Command::Domain/enable_domain_auto_renew_by_name>

=item L<disable_domain_auto_renew_by_name|WWW::eNom::Role::Command::Domain/disable_domain_auto_renew_by_name>

=item L<get_domain_created_date_by_name|WWW::eNom::Role::Command::Domain/get_domain_created_date_by_name>

=item L<renew_domain|WWW::eNom::Role::Command::Domain/renew_domain>

=item L<email_epp_key_by_name|WWW::eNom::Role::Command::Domain/email_epp_key_by_name>

=back

=head2 L<Service|WWW::eNom::Role::Command::Service>

Addon products that can be sold along with domains.

=head3 Domain Privacy

=over 4

=item L<get_domain_privacy_wholesale_price|WWW::eNom::Role::Command::Service/get_domain_privacy_wholesale_price>

=item L<purchase_domain_privacy_for_domain|WWW::eNom::Role::Command::Service/purchase_domain_privacy_for_domain>

=item L<get_is_privacy_purchased_by_name|WWW::eNom::Role::Command::Service/get_is_privacy_purchased_by_name>

=item L<enable_privacy_by_name|WWW::eNom::Role::Command::Service/enable_privacy_by_name>

=item L<disable_privacy_by_name|WWW::eNom::Role::Command::Service/disable_privacy_by_name>

=item L<get_is_privacy_auto_renew_by_name|WWW::eNom::Role::Command::Service/get_is_privacy_auto_renew_by_name>

=item L<get_privacy_expiration_date_by_name|WWW::eNom::Role::Command::Service/get_privacy_expiration_date_by_name>

=item L<enable_privacy_auto_renew_for_domain|WWW::eNom::Role::Command::Service/enable_privacy_auto_renew_for_domain>

=item L<disable_privacy_auto_renew_for_domain|WWW::eNom::Role::Command::Service/disable_privacy_auto_renew_for_domain>

=item L<renew_privacy|WWW::eNom::Role::Command::Service/renew_privacy>

=back

=head2 L<Private Nameservers|WWW::eNom::Role::Command::Domain::PrivateNameServer>

Management of Private Name Servers.

=over 4

=item L<create_private_nameserver|WWW::eNom::Role::Command::Domain::PrivateNameServer/create_private_nameserver>

=item L<update_private_nameserver_ip|WWW::eNom::Role::Command::Domain::PrivateNameServer/update_private_nameserver_ip>

=item L<retrieve_private_nameserver_by_name|WWW::eNom::Role::Command::Domain::PrivateNameServer/retrieve_private_nameserver_by_name>

=item L<delete_private_nameserver|WWW::eNom::Role::Command::Domain::PrivateNameServer/delete_private_nameserver>

=back

=head1 OBJECTS

Rather than working with messy XML objects or HashRefs, WWW::eNom implements a series of L<Moose> objects for making requests and processing responses.  All commands that take an object have coercion so a HashRef can be used in it's place.

=head2 L<WWW::eNom>

Primary interface to eNom.  Documented further below.

=head2 L<WWW::eNom::Contact>

WHOIS data contacts.  Typically (with few exceptions) domains contain a Registrant, Admin, Technical, and Billing contact.

=head2 L<WWW::eNom::Domain>

A registered domain and all of the domain's related information.

=head2 L<WWW::eNom::DomainTransfer>

An in progress domain transfer and all of it's related information.

=head2 L<WWW::eNom::DomainRequest::Registration>

Request to register a domain.

=head2 L<WWW::eNom::DomainRequest::Transfer>

Request to transfer a domain.

=head2 L<WWW::eNom::PrivateNameServer>

Private nameservers.

=head2 L<WWW::eNom::IRTPDetail>

Details about an in progress IRTP Verification (due to a change in registrant contact).  The IRTP Process is rather complex and eNom acts as a Designated Agent, see L<WWW::eNom::IRTPDetail> for more information about this.

=head1 WITH

=over 4

=item L<WWW::eNom::Role::Command>

=back

=head1 ATTRIBUTES

=head2 B<username>

eNom Reseller ID

=head2 B<password>

eNom Reseller Password

=head2 test

Boolean that defaults to false.  If true, requests will be sent to the eNom test endpoint rather than production.

=head2 response_type

Defaults to 'xml_simple'.  Valid values include:

=over 4

=item xml

=item xml_simple

=item html

=item text

=back

It should be noted that this setting is really only relevant when making L<Raw|WWW::eNom::Role::Command::Raw> requests of the eNom API.  When doing so this attribute defines the format of the responses.

=head1 METHODS

=head2 new

    my $eNom = WWW::eNom->new(
        username      => "resellid",
        password      => "resellpw",
        response_type => "xml_simple",  # Optional, defaults to xml_simple
        test          => 1              # Optional, defaults to 0 ( production )
    );

Constructs a new object for interacting with the eNom API. If the "test" parameter is given, then the API calls will be made to the test server instead of the live one.

As of v0.3.1, an optional "response_type" parameter is supported. For the sake of backward compatibility, the default is "xml_simple"; see below for an explanation of this response type. Use of any other valid option will lead to the return of string responses straight from the eNom API. These options are:

=head1 RELEASE NOTE

As of v1.0.0, this module has been renamed to WWW::eNom. Net::eNom is now a thin wrapper to preserve backward compatibility.

=head1 AUTHOR

Robert Stone, C<< <drzigman AT cpan DOT org> >>

Original version by Simon Cozens C<< <simon at simon-cozens.org> >>.
Then maintained and expanded by Richard Simões, C<< <rsimoes AT cpan DOT org> >>.

=head1 COPYRIGHT & LICENSE

Copyright © 2016 Robert Stone. This module is released under the terms of the B<MIT License> and may be modified and/or redistributed under the same or any compatible license.

=cut
