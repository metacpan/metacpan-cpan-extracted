package WWW::eNom::IRTPDetail;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::eNom::Types qw( Bool );

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: Representation of IRTP Detail

has 'is_transfer_locked' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

sub construct_from_response {
    my $self     = shift;
    my $response = shift;

    (!$response ) and return;

    return $self->new(
        is_transfer_locked => $response->{transferlock} eq 'True',
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

WWW::eNom::IRTPDetail - Representation of IRTP Detail

=head1 SYNOPSIS

    use WWW::eNom;
    use WWW::eNom::IRTPDetail;

    my $api = WWW::eNom->new( ... );
    my $domain_info_response = $api->submit({
        method => 'GetDomainInfo',
        params => {
            Domain => 'drzigman.com',
        }
    });

    my $irtp_detail = WWW::eNom::IRTPDetail->construct_from_response(
        $domain_info_response->{GetDomainInfo}{services}{entry}{irtpsettings}{irtpsetting}
    );

=head1 DESCRIPTION

On 2016-12-01, a new L<ICANN Inter Registrar Transfer Policy|https://www.icann.org/resources/pages/transfer-policy-2016-06-01-en> went into effect.  This policy requires any material change to the registrant contact ( the name, email address, that sort of thing ), to be confirmed by both the old registrant and the new registrant.  This object exists to contain all the relevant data of an in progress IRTP Verification.

B<NOTE> eNom is acting as a Designated Agent for all of its resellers' resold domains.  A Designated Agent is defined as L<(taken from Section II Subsection A, Sub Title 1, Point 1.2 )|https://www.icann.org/resources/pages/transfer-policy-2016-06-01-en)>:

"1.2 'Designated Agent' means an individual or entity that the Prior Registrant or New Registrant explicitly authorizes to approve a Change of Registrant on its behalf."

For consumers this means that the losing registrant ( the old registrant contact ) and the gaining registrant ( the new registrant contact ) B<NEED NOT CONFIRM> the change.  Instead eNom does it on behalf of the registrant contacts in near real time, there is a few seconds of delay before the new contacts are used.

Really, the only reason this object exists is so that you can get back if the customer opted out of a transfer lock or not.

=head1 ATTRIBUTES

=head2 B<is_transfer_locked>

Boolean indicating if the domain will have a 60 day transfer lock imposed upon it after the registrant contact is updated.  Consumers must specify is_transfer_lock in the call to L<update_contacts_for_domain_name|WWW::eNom::Role::Command::Contact/update_contacts_for_domain_name>.

=head1 METHODS

=head2 construct_from_response

    my $api = WWW::eNom->new( ... );
    my $domain_info_response = $api->submit({
        method => 'GetDomainInfo',
        params => {
            Domain => 'drzigman.com',
        }
    });

    my $irtp_detail = WWW::eNom::IRTPDetail->construct_from_response(
        $domain_info_response->{GetDomainInfo}{services}{entry}{irtpsettings}{irtpsetting}
    );

Constructs an instance of L<WWW::eNom::IRTPDetail> from the irtpsettings details of L<eNom's|http://www.enom.com> API L<GetDomainInfo|https://www.enom.com/api/API%20topics/api_GetDomainInfo.htm> response.  There really is not ever a reason for a consumer to call this method directly.

=cut
