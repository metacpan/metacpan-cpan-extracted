# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::DocumentUploadGateway;

use 5.010_001;
use strictures 1;

use Moo;
with 'WebService::Braintree::Role::MakeRequest';

use Carp qw(confess);

use WebService::Braintree::Validations qw(verify_params);

use WebService::Braintree::_::DocumentUpload;

sub create {
    my ($self, $params) = @_;

    confess "ArgumentError" unless verify_params($params, {
        file => 1,
        kind => 1,
    });

    $self->_make_request("/document_uploads", "post", {
        'document_upload[kind]' => $params->{kind},
    }, $params->{file});
}

__PACKAGE__->meta->make_immutable;

1;
__END__
