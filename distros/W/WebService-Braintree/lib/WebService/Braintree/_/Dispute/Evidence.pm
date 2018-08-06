# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Dispute::Evidence;
$WebService::Braintree::_::Dispute::Evidence::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Dispute::Evidence

=head1 PURPOSE

This class represents an evidence of a dispute.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moo;
use MooX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 category()

This is the category for this dispute's evidence.

=cut

has category => (
    is => 'ro',
);

=head2 comment()

This is the comment for this dispute's evidence.

=cut

has comment => (
    is => 'ro',
);

=head2 created_at()

This is when this dispute's evidence was created.

=cut

has created_at => (
    is => 'ro',
);

=head2 id()

This is the ID for this dispute's evidence.

=cut

has id => (
    is => 'ro',
);

=head2 sent_to_processor_at()

This is when this dispute's evidence was sent to the processor.

=cut

# Coerce this to DateTime
has sent_to_processor_at => (
    is => 'ro',
);

=head2 sequence_number()

This is the sequence number for this dispute's evidence.

=cut

has sequence_number => (
    is => 'ro',
);

=head2 url()

This is the URL for this dispute's evidence.

=cut

has url => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
