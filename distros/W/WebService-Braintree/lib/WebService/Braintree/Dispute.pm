# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Dispute;
$WebService::Braintree::Dispute::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Dispute

=head1 PURPOSE

This class represents a dispute.

=cut

use WebService::Braintree::Dispute::Kind;
use WebService::Braintree::Dispute::Reason;
use WebService::Braintree::Dispute::Status;

use Moo;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 accept

This takes a dispute_id, marks it as accepted, and returns a L<response|WebService::Braintee::Result> (if found).

=cut

sub accept {
    my ($class, $id) = @_;
    $class->gateway->dispute->accept($id);
}

=head2 finalize

This takes a dispute_id, marks it as finalized, and returns a L<response|WebService::Braintee::Result> (if found).

=cut

sub finalize {
    my ($class, $id) = @_;
    $class->gateway->dispute->finalize($id);
}

=head2 add_file_evidence

This takes a dispute_id and a C<document_upload_id|WebService::Braintree::DocumentUpload>,
adds the upload to the dispute, and returns a L<response|WebService::Braintee::Result> (if found) with the C<< evidence() >> set.

=cut

sub add_file_evidence {
    my ($class, $id, $upload_id) = @_;
    $class->gateway->dispute->add_file_evidence($id, $upload_id);
}

=head2 add_text_evidence

This takes a dispute_id and a comment, adds the comment to the dispute, and returns a L<response|WebService::Braintee::Result> (if found) with the C<< evidence() >> set.

=cut

sub add_text_evidence {
    my ($class, $id, $content) = @_;
    $class->gateway->dispute->add_text_evidence($id, $content);
}

=head2 remove_evidence

This takes a dispute_id and an evidence_id, removes the evidence from the dispute, and returns a L<response|WebService::Braintee::Result> (if found).


=cut

sub remove_evidence {
    my ($class, $id, $evidence_id) = @_;
    $class->gateway->dispute->remove_evidence($id, $evidence_id);
}

=head2 find

This takes a dispute_id and returns a L<response|WebService::Braintee::Result> with the C<< dispute() >> set.

=cut

sub find {
    my ($class, $id) = @_;
    $class->gateway->dispute->find($id);
}

=head2 search()

This takes a subref which is used to set the search parameters and returns a
L<collection|WebService::Braintree::ResourceCollection> of the matching
L<customers|WebService::Braintree::_::Dispute>.

Please see L<Searching|WebService::Braintree/SEARCHING> for more information on
the subref and how it works.

Please see L<WebService::Braintree::DisputeSearch> for more

=cut

sub search {
    my ($class, $block) = @_;
    $class->gateway->dispute->search($block);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
