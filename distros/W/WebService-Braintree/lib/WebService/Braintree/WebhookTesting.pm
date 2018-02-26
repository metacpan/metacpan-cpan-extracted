package WebService::Braintree::WebhookTesting;
$WebService::Braintree::WebhookTesting::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose;

sub sample_notification {
    my ($class, $kind, $id) = @_;

    return $class->gateway->webhook_testing->sample_notification($kind, $id);
}

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
