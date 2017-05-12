package WWW::LogicBoxes::IRTPDetail;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( Bool DateTime IRTPFOAStatus IRTPStatus Int Str );

use DateTime;

our $VERSION = '1.9.0'; # VERSION
# ABSTRACT: Detailed Information About An In Progress IRTP Verification

has 'is_transfer_locked' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has 'expiration_date' => (
    is       => 'ro',
    isa      => DateTime,
    required => 1,
);

has 'gaining_foa_status' => (
    is       => 'ro',
    isa      => IRTPFOAStatus,
    required => 1,
);

has 'losing_foa_status' => (
    is       => 'ro',
    isa      => IRTPFOAStatus,
    required => 1,
);

has 'status' => (
    is       => 'ro',
    isa      => IRTPStatus,
    required => 1,
);

has 'message' => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_message',
);

has 'proposed_registrant_contact_id' => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

sub construct_from_response {
    my $self     = shift;
    my $response = shift;

    (!$response) and return;

    return $self->new(
        is_transfer_locked => ($response->{'sixty-day-lock-status'} eq 'true'),
        expiration_date    => DateTime->from_epoch( epoch => $response->{expiry} ),
        gaining_foa_status => $response->{'gaining-foa-status'},
        losing_foa_status  => $response->{'losing-foa-status'},
        status             => $response->{'task-status'},
        proposed_registrant_contact_id => $response->{'gaining-contact-info'}{id},
        $response->{message} ? ( message => $response->{message} ) : ( ),
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::IRTPDetail - Detailed Information About An In Progress IRTP Verification

=head1 SYNOPSIS

    use WWW::LogicBoxes;

    my $api    = WWW::LogicBoxes->new( ... );
    my $domain = $api->get_domain_by_name( 'test-domain.com' );

    if( $domain->has_irtp_detail ) {
        # Output information about IRTP Verification
        $domain->irtp_detail->is_transfer_locked;
        ...
    }

=head1 DESCRIPTION

On 2016-12-01, a new L<ICANN Inter Registrar Transfer Policy|https://www.icann.org/resources/pages/transfer-policy-2016-06-01-en> went into effect.  This policy requires any material change to the registrant contact ( the name, email address, that sort of thing ), to be confirmed by both the old registrant and the new registrant.  This object exists to contain all the relevant data of an in progress IRTP Verification.

=head1 ATTRIBUTES

=head2 B<is_transfer_locked>

Boolean indicating if the domain will be transfer locked for 60 days after the verification is complete.  This is set when the original call to L<WWW::LogicBoxes::Role::Command::Domain/update_domain_contacts> is made and is based on the value of is_transfer_locked.

=head2 B<expiration_date>

DateTime object that contains when this verification request will expire.

=head2 B<gaining_foa_status>

The verification status for the gaining registrant.

Always takes one of the following values:

=over 4

=item PENDING

=item APPROVED

=item DISAPPROVED

=back

=head2 B<losing_foa_status>

The verification status for the losing registrant.

Always takes one of the following values:

=over 4

=item PENDING

=item APPROVED

=item DISAPPROVED

=back

=head2 B<status>

Overall status of the IRTP Verification.

=over 4

=item PENDING

=item REVOKED

=item EXPIRED

=item FAILED

=item APPROVED

=item SUCCESS

=item REMOTE_FAILURE

=back

=head2 message

In the event that the status is REVOKED or REMOTE_FAILURE, message will be populated with details about the issue.  A predicate of has_message is provided.

=head1 METHODS

=head2 construct_from_response

Construct an instance of $self from the irtp_status portion of the L<WWW::LogicBoxes::Role::Command::Domain/get_domain_by_id> response from LogicBoxes.  There really isn't any reason for consumers to use this method directly.

=cut
