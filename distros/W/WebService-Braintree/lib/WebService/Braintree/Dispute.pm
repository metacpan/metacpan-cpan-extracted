package WebService::Braintree::Dispute;
$WebService::Braintree::Dispute::VERSION = '1.1';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Dispute

=head1 PURPOSE

This class represents a dispute.

=cut

use WebService::Braintree::Dispute::Evidence;
use WebService::Braintree::Dispute::Kind;
use WebService::Braintree::Dispute::Reason;
use WebService::Braintree::Dispute::Status;
use WebService::Braintree::Dispute::TransactionDetails;

use Moose;
extends 'WebService::Braintree::ResultObject';

=head1 CLASS METHODS

=head2 accept

This takes a dispute id and marks it as accepted.

=cut

sub accept {
    my ($class, $id) = @_;
    $class->gateway->dispute->accept($id);
}

=head2 finalize

This takes a dispute id and marks it as disputed.

=cut

sub finalize {
    my ($class, $id) = @_;
    $class->gateway->dispute->finalize($id);
}

=head2 add_file_evidence

This takes a dispute id and a document_upload id and adds the upload to the
dispute's evidence.

=cut

sub add_file_evidence {
    my ($class, $id, $upload_id) = @_;
    $class->gateway->dispute->add_file_evidence($id, $upload_id);
}

=head2 add_text_evidence

This takes a dispute id and a comment and adds the comment to the dispute's
evidence.

=cut

sub add_text_evidence {
    my ($class, $id, $content) = @_;
    $class->gateway->dispute->add_text_evidence($id, $content);
}

=head2 remove_evidence

This takes a dispute id and an evidence id and removes the evidence from the
dispute's evidence.

=cut

sub remove_evidence {
    my ($class, $id, $evidence_id) = @_;
    $class->gateway->dispute->remove_evidence($id, $evidence_id);
}

=head2 find

This takes a dispute id and returns it.

=cut

sub find {
    my ($class, $id) = @_;
    $class->gateway->dispute->find($id);
}

=head2 search()

This takes a subref which is used to set the search parameters and returns a
collection of Dispute objects.

Please see L<Searching|WebService::Braintree/SEARCHING> for more information on
the subref and how it works.

=cut

sub search {
    my ($class, $block) = @_;
    $class->gateway->dispute->search($block);
}

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

=head1 OBJECT METHODS

=cut

sub BUILD {
    my ($self, $attrs) = @_;

    $self->build_sub_object($attrs,
        method => 'transaction_details',
        class  => 'Dispute::TransactionDetails',
        key    => 'transaction',
    );

    $self->set_attributes_from_hash($self, $attrs);
}

=pod

In addition to the methods provided by B<TODO>, this class provides the
following methods:

=head2 transaction_details()

This returns the transaction details associated with this dispute (if any).
This will be an object of type
L<WebService::Braintree::Dispute::TransactionDetails/>.

=cut

has transaction_details => (is => 'rw');

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 TODO

=over 4

=item Need to document the keys and values that are returned

=item Need to document the required and optional input parameters

=item Need to document the possible errors/exceptions

=back

=cut
