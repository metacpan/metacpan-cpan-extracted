package WWW::LogicBoxes::DomainTransfer;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( Bool DateTime DomainName DomainNames DomainStatus Int PrivateNameServers Str VerificationStatus );

use WWW::LogicBoxes::PrivateNameServer;

use DateTime;

our $VERSION = '1.10.0'; # VERSION
# ABSTRACT: LogicBoxes Domain Transfer In Progress Representation

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

has transfer_status => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has verification_status => (
    is       => 'ro',
    isa      => VerificationStatus,
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
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has epp_key => (
    is        => 'ro',
    isa       => Str,
    required  => 0,
    predicate => 'has_epp_key',
);

has private_nameservers => (
    is        => 'ro',
    isa       => PrivateNameServers,
    required  => 0,
    predicate => 'has_private_nameservers',
);

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

    return $self->new(
        id                    => $response->{orderid},
        name                  => $response->{domainname},
        customer_id           => $response->{customerid},
        status                => $response->{currentstatus},
        transfer_status       => $response->{actionstatusdesc},
        verification_status   => $response->{raaVerificationStatus},
        ns                    => [ map { $response->{ $_ } } sort ( grep { $_ =~ m/^ns/ } keys %{ $response } ) ],
        registrant_contact_id => $response->{registrantcontactid},
        admin_contact_id      => $response->{admincontactid},
        technical_contact_id  => $response->{techcontactid},
        billing_contact_id    => $response->{billingcontactid},
        $response->{domsecret} ? ( epp_key => $response->{domsecret} ) : ( ),
        scalar @private_nameservers ? ( private_nameservers => \@private_nameservers ) : ( ),
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::DomainTransfer - Representation of a Domain Transfer In Progress

=head1 SYNOPSIS

    use WWW::LogicBoxes;

    my $logic_boxes = WWW::LogicBoxes->new( ... );

    my $domain_transfer = $logic_boxes->get_domain_by_name( 'in-progress-transfer.com' );

    print 'Status of Domain Transfer is ' . $domain_transfer->transfer_status . "\n";

=head1 DESCRIPTION

Represents L<LogicBoxes|http://www.logicboxes.com> domains transfers that are in progress.

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

=item Deleted

=item Archived

=back

=head2 B<transfer_status>

A human readable string indicating what part of the transfer flow we are currently in.  A non exahustive list of possible values incldue:

=over 4

=item Transfer waiting for Losing Registrar Approval

=item Transfer waiting for Admin Contact Approval

=back

=head2 B<verification_status>

According to ICANN rules, all new gTLD domains that were registered after January 1st, 2014 must be verified.  verification_status describes the current state of this verification and will be one of the following values:

=over 4

=item Verified

=item Pending

=item Suspended

=back

For details on the ICANN policy please see the riveting ICANN Registrar Agreement L<https://www.icann.org/resources/pages/approved-with-specs-2013-09-17-en>.

=head2 B<ns>

ArrayRef of Domain Names that are the authorizative nameservers for this domain.

=head2 B<registrant_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Registrant.

=head2 B<admin_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Admin.

=head2 B<technical_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Technical.

=head2 B<billing_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Billing.

=head2 B<epp_key>

The secret key needed in order to transfer a domain to another registrar, if it has been provided.  Predicate of has_epp_key.

=head2 private_nameserves

ArrayRef of L<WWW::LogicBoxes::PrivateNameServer> objects that contains any created private name servers.  Predicate of has_private_nameservers.

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

    my $domain = WWW::LogicBoxes::DomainTransfer->construct_from_response( $response );

Constructs an instance of $self from a L<LogicBoxes|http://www.logicboxes.com> response.

=cut
