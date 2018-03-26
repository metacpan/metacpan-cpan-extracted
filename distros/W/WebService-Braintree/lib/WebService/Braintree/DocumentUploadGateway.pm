# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::DocumentUploadGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

has 'gateway' => (is => 'ro');

use WebService::Braintree::_::DocumentUpload;

sub create {
    my ($self, $params) = @_;
    $self->_make_request("/document_uploads", "post", {
        'document_upload[kind]' => $params->{kind},
    }, $params->{file});
}

__PACKAGE__->meta->make_immutable;

1;
__END__
