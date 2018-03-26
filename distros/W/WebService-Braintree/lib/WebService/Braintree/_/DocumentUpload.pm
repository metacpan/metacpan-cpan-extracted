# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::DocumentUpload;
$WebService::Braintree::_::DocumentUpload::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::DocumentUpload

=head1 PURPOSE

This class represents a document upload.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 content_type()

This is the content type for this document upload.

=cut

has content_type => (
    is => 'ro',
);

=head2 expires_at()

This is when this document upload expires.

=cut

# Coerce to a DateTime (YYYY-MM-DD)
has expires_at => (
    is => 'ro',
);

=head2 id()

This is the id for this document upload.

=cut

has id => (
    is => 'ro',
);

=head2 kind()

This is the kind for this document upload.

=cut

has kind => (
    is => 'ro',
);

=head2 name()

This is the name for this document upload.

=cut

has name => (
    is => 'ro',
);

=head2 size()

This is the size for this document upload.

=cut

has size => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
