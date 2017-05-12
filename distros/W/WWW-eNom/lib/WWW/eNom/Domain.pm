package WWW::eNom::Domain;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Params::Validate;
use namespace::autoclean;

use WWW::eNom::Types qw( Bool Contact DateTime DomainName DomainNames HashRef IRTPDetail PositiveInt Str PrivateNameServers );

use WWW::eNom::Contact;
use WWW::eNom::IRTPDetail;

use DateTime;
use DateTime::Format::DateParse;
use Mozilla::PublicSuffix qw( public_suffix );

use Try::Tiny;
use Carp;

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: Representation of Registered eNom Domain

has 'id' => (
    is       => 'ro',
    isa      => PositiveInt,
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

has 'status' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'verification_status' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'is_auto_renew' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has 'is_locked' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has 'is_private' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has 'created_date' => (
    is       => 'ro',
    isa      => DateTime,
    required => 1,
);

has 'expiration_date' => (
    is       => 'ro',
    isa      => DateTime,
    required => 1,
);

has 'ns' => (
    is       => 'ro',
    isa      => DomainNames,
    required => 1,
);

has 'registrant_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

has 'admin_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

has 'technical_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

has 'billing_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

has 'private_nameservers' => (
    is        => 'ro',
    isa       => PrivateNameServers,
    predicate => 'has_private_nameservers',
);

has 'irtp_detail' => (
    is        => 'ro',
    isa       => IRTPDetail,
    predicate => 'has_irtp_detail',
);

with 'WWW::eNom::Role::ParseDomain';

sub construct_from_response {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_info         => { isa => HashRef },
        is_auto_renew       => { isa => Bool },
        is_locked           => { isa => Bool },
        name_servers        => { isa => DomainNames },
        private_nameservers => { isa => PrivateNameServers, optional => 1 },
        contacts            => { isa => HashRef },
        created_date        => { isa => DateTime },
    );

    return try {
        my ( $verification_status, $is_private );
        if( public_suffix( $args{domain_info}{domainname}{content} ) eq 'us' ) {
            $verification_status = 'Verification Not Needed';
            $is_private          = 0;
        }
        else {
            # On verified domains the raasettings response is empty, if the value is missing, just call it verified.
            $verification_status = $args{domain_info}{services}{entry}{raasettings}{raasetting}{verificationstatus} // 'Verified';
            $is_private          = ( $args{domain_info}{services}{entry}{wpps}{service}{content} == 1120 );
        }

        my $irtp_detail;
        if( $args{contacts}{is_pending_irtp} ) {
            $irtp_detail = WWW::eNom::IRTPDetail->construct_from_response(
                $args{domain_info}{services}{entry}{irtpsettings}{irtpsetting}
            );
        }

        return $self->new({
            id                  => $args{domain_info}{domainname}{domainnameid},
            name                => $args{domain_info}{domainname}{content},
            status              => $args{domain_info}{status}{registrationstatus},
            verification_status => $verification_status,
            is_auto_renew       => $args{is_auto_renew},
            is_locked           => $args{is_locked},
            is_private          => $is_private,
            created_date        => $args{created_date},
            expiration_date     => DateTime::Format::DateParse->parse_datetime( $args{domain_info}{status}{expiration} ),
            ns                  => $args{name_servers},
            registrant_contact  => $args{contacts}{registrant_contact},
            admin_contact       => $args{contacts}{admin_contact},
            technical_contact   => $args{contacts}{technical_contact},
            billing_contact     => $args{contacts}{billing_contact},
            defined $irtp_detail       ? ( irtp_detail         => $irtp_detail               ) : ( ),
            $args{private_nameservers} ? ( private_nameservers => $args{private_nameservers} ) : ( ),
        });
    }
    catch {
        croak "Error constructing domain from response: $_";
    };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

WWW::eNom::Domain - Representation of Registered eNom Domain

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::eNom;
    use WWW::eNom::Contact;
    use WWW::eNom::Domain;

    my $api = WWW::eNom->new( ... );

    # Create New Domain Object, note that domain registration is handled by
    # WWW::eNom::DomainRequest::Registration.
    my $contact              = WWW::eNom::Contact->new( ... );
    my $private_name_servers = [ WWW::eNom::PrivateNameServer->new( ... ) ];

    my $domain  = WWW::eNom::Domain->new(
        id                   => 42,
        name                 => 'drzigman.com',
        status               => 'Paid',
        verification_status  => 'Pending Suspension',
        is_auto_renew        => 0,
        is_locked            => 1,
        is_private           => 0,
        created_date         => DateTime->...,
        expiration_date      => DateTime->...,
        ns                   => [ 'ns1.enom.com', 'ns2.enom.com' ],
        registrant_contact   => $contact,
        admin_contact        => $contact,
        technical_contact    => $contact,
        billing_contact      => $contact,
        private_name_servers => $private_name_servers,   # Optional
    );

    # Construct From eNom Response
    my $response = $api->submit({
        method => 'GetDomainInfo',
        params => {
            Domain => 'drzigman.com',
        }
    });

    my $domain = WWW::eNom::Domain->construct_from_response(
        domain_info   => $response->{GetDomainInfo},
        is_auto_renew => $api->get_is_domain_auto_renew_by_name( 'drzigman.com' ),
        is_locked     => $api->get_is_domain_locked_by_name( 'drzigman.com' ),
        name_servers  => $api->get_domain_name_servers_by_name( 'drzigman.com' ),
        contacts      => $api->get_contacts_by_domain_name( 'drzigman.com' ),
        created_date  => $api->get_domain_created_date_by_name( 'drzigman.com' ),
    );


=head1 WITH

=over 4

=item L<WWW::eNom::Role::ParseDomain>

=back

=head1 DESCRIPTION

Represents L<eNom|https://www.enom.com> domains, containing all related information.  For most operations this will be the base object that is used to represent the data.

=head1 attributes

=head2 B<id>

The domain id of the domain in L<eNom|https://www.enom.com>'s system.

=head2 B<name>

The FQDN this domain object represents

=head2 B<status>

Current status of the domain, related more so to if it's been paid or if it has been deleted or expired.

=head2 B<verification_status>

According to ICANN rules, all new gTLD domains that were registered after January 1st, 2014 must be verified.  verification_status describes the current state of this verification and begins in 'Pending Suspension' until the domain is either verified or is suspended due to a lack of verification.

For details on the ICANN policy please see the riveting ICANN Registrar Agreement L<https://www.icann.org/resources/pages/approved-with-specs-2013-09-17-en>.

=head2 B<is_auto_renew>

Boolean that indicates if eNom should automagically renew this domain.

=head2 B<is_locked>

Boolean indicating if the domain is currently locked, preventing transfer.

=head2 B<is_private>

Boolean indicating if this domain uses WHOIS Privacy.

=head2 B<created_date>

Date this domain registration was created.

=head2 B<expiration_date>

Date this domain registration expires.

=head2 B<ns>

ArrayRef of Domain Names that are authoritative nameservers for this domain.

=head2 B<registrant_contact>

A L<WWW::eNom::Contact> for the Registrant Contact.

=head2 B<admin_contact>

A L<WWW::eNom::Contact> for the Admin Contact.

=head2 B<technical_contact>

A L<WWW::eNom::Contact> for the Technical Contact.

=head2 B<billing_contact>

A L<WWW::eNom::Contact> for the Billing Contact.

B<NOTE> L<eNom|https://www.eNom.com> actually calls this the B<AuxBilling> contact since the primary billing contact is the reseller's information.

=head2 B<private_nameservers>

An ArrayRef of L<WWW::eNom::PrivateNameServer> objects that comprise the private nameservers for this domain, provides a predicate of has_private_nameservers.

B<NOTE> Due to limitations of L<eNom|https://www.enom.com>'s API, all private nameservers B<*MUST*> be used as authoritative nameservers (i.e., they must also appear in the L</ns> attribute).  See L<WWW::eNom::Role::Command::Domain::PrivateNameServer/LIMITATIONS> for more information about this and other limitations.

=head2 irtp_detail

In the event of a recent change in registrant contact, the irtp_detail attribute will be populated with an instance of L<WWW::eNom::IRTPDetail> that contains additional IRTP related information about this domain.  If there is no recent registrant contact change then no value will be provided for the irtp_detail.  Offers a predicate of has_irtp_detail.

=head1 METHODS

=head2 construct_from_response

    my $api = WWW::eNom->new( ... );

    my $response = $api->submit({
        method => 'GetDomainInfo',
        params => {
            Domain => 'drzigman.com',
        }
    });

    my $domain = WWW::eNom::Domain->construct_from_response(
        domain_info          => $response->{GetDomainInfo},
        is_auto_renew        => $api->get_is_domain_auto_renew_by_name( $domain_name ),
        is_locked            => $api->get_is_domain_locked_by_name( $domain_name ),
        name_servers         => $api->get_domain_name_servers_by_name( $domain_name ),
        private_name_servers => $private_name_servers,                                   # Optional
        contacts             => $api->get_contacts_by_domain_name( $domain_name ),
        created_date         => $api->get_domain_created_date_by_name( $domain_name ),
    );

Creates an instance of $self given several parameters:

=over 4

=item domain_info

HashRef response to L<eNom's GetDomainInfo|https://www.enom.com/api/API%20topics/api_GetDomainInfo.htm>.  This, unfortunately, does not contain all of the needed data so several other parameters are required.

=item is_auto_renew

Boolean, indicating if L<eNom|https://www.enom.com> will auto renew this domain.

=item is_locked

Boolean, indicating if this domain is locked to prevent transfer.

=item name_servers

ArrayRef of Domain Names that are the authoritative nameservers for this domain.

=item contacts

HashRef with the keys being:

=over 4

=item registrant_contact

=item admin_contact

=item technical_contact

=item billing_contact

=back

And the values being instances of L<WWW::eNom::Contact> that correspond to the key's contact type.

=item created_date

DateTime that this domain was first created/registered.

=back

=cut
