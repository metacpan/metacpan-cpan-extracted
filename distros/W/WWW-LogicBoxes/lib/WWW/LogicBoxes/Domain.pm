package WWW::LogicBoxes::Domain;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw(
  Bool DateTime DomainName DomainNames DomainStatus Int IRTPDetail PrivateNameServers Str VerificationStatus
);

use WWW::LogicBoxes::IRTPDetail;
use WWW::LogicBoxes::PrivateNameServer;

use DateTime;
use Carp;
use Mozilla::PublicSuffix qw( public_suffix );

our $VERSION = '1.10.0'; # VERSION
# ABSTRACT: LogicBoxes Domain Representation

has id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

has customer_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has status => (
    is       => 'ro',
    isa      => DomainStatus,
    required => 1,
);

has verification_status => (
    is       => 'ro',
    isa      => VerificationStatus,
    required => 1,
);

has is_locked => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has is_private => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has created_date => (
    is       => 'ro',
    isa      => DateTime,
    required => 1,
);

has expiration_date => (
    is       => 'ro',
    isa      => DateTime,
    required => 1,
);

has ns => (
    is       => 'ro',
    isa      => DomainNames,
    required => 1,
);

has registrant_contact_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has admin_contact_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has technical_contact_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has billing_contact_id => (
    is        => 'ro',
    isa       => Int,
    required  => 0,
    predicate => 'has_billing_contact_id',
);

has epp_key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has private_nameservers => (
    is        => 'ro',
    isa       => PrivateNameServers,
    required  => 0,
    predicate => 'has_private_nameservers',
);

has irtp_detail => (
    is        => 'ro',
    isa       => IRTPDetail,
    predicate => 'has_irtp_detail',
);

sub BUILD {
    my $self = shift;

    my $tld = public_suffix( $self->name );

    if( $tld eq 'ca' ) {
        if( $self->has_billing_contact_id ) {
            croak 'CA domains do not have a billing contact';
        }
    }
    elsif( !$self->has_billing_contact_id ) {
        croak 'A billing_contact_id is required';
    }

    return $self;
}

sub construct_from_response {
    my $self     = shift;
    my $response = shift;

    if( !$response ) {
        return;
    }

    my @private_nameservers;
    for my $private_nameserver_name ( keys %{ $response->{cns} } ) {
        push @private_nameservers, WWW::LogicBoxes::PrivateNameServer->new(
            domain_id => $response->{orderid},
            name      => $private_nameserver_name,
            ips       => $response->{cns}{$private_nameserver_name},
        );
    }

    my $irtp_detail;
    if( exists $response->{irtp_status} ) {
        $irtp_detail = WWW::LogicBoxes::IRTPDetail->construct_from_response( $response->{irtp_status} );
    }

    return $self->new(
        id                    => $response->{orderid},
        name                  => $response->{domainname},
        customer_id           => $response->{customerid},
        status                => $response->{currentstatus},
        verification_status   => $response->{raaVerificationStatus} // 'NA',
        is_locked             => !!( grep { $_ && $_ eq 'transferlock' } @{ $response->{orderstatus} } ),
        is_private            => $response->{isprivacyprotected} && $response->{isprivacyprotected} eq 'true',
        created_date          => DateTime->from_epoch( epoch => $response->{creationtime}, time_zone => 'UTC' ),
        expiration_date       => DateTime->from_epoch( epoch => $response->{endtime}, time_zone => 'UTC' ),
        ns                    => [ map { $response->{ $_ } } sort ( grep { $_ =~ m/^ns/ } keys %{ $response } ) ],
        epp_key               => $response->{domsecret},
        scalar @private_nameservers ? ( private_nameservers => \@private_nameservers ) : ( ),
        registrant_contact_id => $response->{registrantcontact}{contactid},
        admin_contact_id      => $response->{admincontact}{contactid},
        technical_contact_id  => $response->{techcontact}{contactid},
        $response->{billingcontact} ? ( billing_contact_id => $response->{billingcontact}{contactid} ) : ( ),
        $irtp_detail                ? ( irtp_detail        => $irtp_detail                           ) : ( ),
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Domain - Representation of Registered LogicBoxes Domain

=head1 SYNOPSIS

    use WWW::LogicBoxes;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $domain = $logic_boxes->get_domain_by_name( 'test-domain.com' );

    print 'ID For domain test-domain.com is ' . $domain->id . "\n";

=head1 DESCRIPTION

Represents L<LogicBoxes|http://www.logicboxes.com> domains, containing all related information.  For most operations this will be the base object that is used to represent the data.

=head1 ATTRIBUTES

=head2 B<id>

The order_id of the domain in L<LogicBoxes|http://www.logicboxes.com>'s system.

=head2 B<name>

The full domain name ( test-domain.com ).

=head2 B<customer_id>

The id of the L<customer|WWW::LogicBoxes::Customer> who owns this domain in L<LogicBoxes|http://www.logicboxes.com>.

=head2 B<status>

Current status of the domain with L<LogicBoxes|http://www.logicboxes.com>.  Will be one of the following values:

=over 4

=item InActive

=item Active

=item Suspended

=item Pending Delete Restorable

=item QueuedForDeletion

=item Deleted

=item Archived

=back

=head2 B<verification_status>

According to ICANN rules, all new gTLD domains that were registered after January 1st, 2014 must be verified.  verification_status describes the current state of this verification and will be one of the following values:

=over 4

=item Verified

=item Pending

=item Suspended

=back

For details on the ICANN policy please see the riveting ICANN Registrar Agreement L<https://www.icann.org/resources/pages/approved-with-specs-2013-09-17-en>.

=head2 B<is_locked>

Boolean indicating if the domain is currently locked, preventing transfer.

=head2 B<is_private>

Boolean indicating if this domain uses WHOIS Privacy.

=head2 B<created_date>

Date this domain registration was created.

=head2 B<expiration_date>

Date this domain registration expires.

=head2 B<ns>

ArrayRef of Domain Names that are the authorizative nameservers for this domain.

=head2 B<registrant_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Registrant.

=head2 B<admin_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Admin.

=head2 B<technical_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Technical.

=head2 billing_contact_id

A L<Contact|WWW::LogicBoxes::Contact> id for the Billing.  Offers a predicate of has_billing_contact_id.

Almost all TLDs require a billing contact, however for .ca domains it B<must not> be provided.

=head2 B<epp_key>

The secret key needed in order to transfer a domain to another registrar.

=head2 private_nameserves

ArrayRef of L<WWW::LogicBoxes::PrivateNameServer> objects that contains any created private name servers.  Predicate of has_private_nameservers.

=head2 irtp_detail

If an IRTP Verification is in process for this domain, this attribute will contain a fully formed L<WWW::LogicBoxes::IRTPDetail> object.  If there is no pending IRTP Verification this attribute will not be set.  A predicate of has_irtp_detail is provided.

=head1 METHODS

These methods are used internally, it's fairly unlikely that consumers will ever call them directly.

=head2 construct_from_response

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $response = $logic_boxes->submit({
        method => 'domains__details_by_name',
        params => {
            'domain-name' => 'test-domain.com',
            'options'     => [qw( All )],
        },
    });

    my $domain = WWW::LogicBoxes::Domain->construct_from_response( $response );

Constructs an instance of $self from a L<LogicBoxes|http://www.logicboxes.com> response.

=cut
