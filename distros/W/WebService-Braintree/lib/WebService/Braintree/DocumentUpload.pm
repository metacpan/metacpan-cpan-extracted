package WebService::Braintree::DocumentUpload;
$WebService::Braintree::DocumentUpload::VERSION = '1.1';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::DocumentUpload

=head1 PURPOSE

This class creates document uploads.

=cut

use Moose;
extends "WebService::Braintree::ResultObject";

use WebService::Braintree::DocumentUpload::Kind;

=head2 create()

This takes a hashref of params and returns the create document upload.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->document_upload->create($params // {});
}

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

sub BUILD {
    my ($self, $attributes) = @_;

    $self->set_attributes_from_hash($self, $attributes);
}

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
