package WebService::Braintree::Role::MakeRequest;
$WebService::Braintree::Role::MakeRequest::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose::Role;

use WebService::Braintree::ErrorResult;
use WebService::Braintree::Result;

sub _make_request {
    my($self, $path, $verb, @args) = @_;
    my $response = $self->gateway->http->$verb($path, @args);

    if (exists $response->{api_error_response}) {
        return WebService::Braintree::ErrorResult->new(
            $response->{api_error_response},
        );
    }
    else {
        return WebService::Braintree::Result->new(
            response => $response,
        );
    }
}

1;
__END__
