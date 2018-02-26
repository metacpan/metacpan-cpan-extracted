package WebService::Braintree::DocumentUploadGateway;
$WebService::Braintree::DocumentUploadGateway::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';

has 'gateway' => (is => 'ro');

sub create {
    my ($self, $params) = @_;
    $self->_make_request("/document_uploads", "post", {
        'document_upload[kind]' => $params->{kind},
    }, $params->{file});
}

__PACKAGE__->meta->make_immutable;

1;
__END__
