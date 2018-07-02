# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::DocumentUpload;
$WebService::Braintree::DocumentUpload::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::DocumentUpload

=head1 PURPOSE

This class creates document uploads.

=cut

use Moo;

with 'WebService::Braintree::Role::Interface';

use WebService::Braintree::DocumentUpload::Kind;

=head2 create()

This takes a hashref of parameters and returns a L<response|WebService::Braintee::Result> with the C<< document_upload() >> set.

The parameters are:

=over 4

=item kind

This is the L<kind of document|WebService::Braintree::DocumentUpload::Kind>.

=item file

This is a path on the server for the file to upload. The extension will be used
to determine the mime type.

=back

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->document_upload->create($params // {});
}

__PACKAGE__->meta->make_immutable;

1;
__END__
