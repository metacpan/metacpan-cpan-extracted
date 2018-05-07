# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::Role::MakeRequest;

use 5.010_001;
use strictures 1;

use Moose::Role;

has 'gateway' => (is => 'ro');

use WebService::Braintree::ErrorResult;
use WebService::Braintree::Result;
use WebService::Braintree::Util qw(to_instance_array);

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

sub _make_raw_request {
    my($self, $path, $verb, @args) = @_;
    my $response = $self->gateway->http->$verb($path, @args);

    if (exists $response->{api_error_response}) {
        return WebService::Braintree::ErrorResult->new(
            $response->{api_error_response},
        );
    }
    else {
        return $response;
    }
}

sub _array_request {
    my ($self, $path, $key, $class) = @_;
    my $response = $self->gateway->http->get($path);
    my $attrs = $response->{$key} || [];
    return to_instance_array($attrs, $class);
}

1;
__END__
