package WebService::Braintree::WebhookNotificationGateway;
$WebService::Braintree::WebhookNotificationGateway::VERSION = '0.9';

use MIME::Base64;
use WebService::Braintree::Digest qw(hexdigest);
use WebService::Braintree::Xml qw(xml_to_hash);
use Carp qw(confess);
use Moose;

has 'gateway' => (is => 'ro');

sub parse {
    my ($self, $signature, $payload) = @_;
    $self->_validate_signature($signature, $payload);
    my $xml_payload = decode_base64($payload);
    my $attributes = xml_to_hash($xml_payload);

    WebService::Braintree::WebhookNotification->new($attributes->{notification});
}

sub _matching_signature {
    my ($self, $signature, $payload) = @_;
    foreach my $signature_pair (split("&", $signature)) {
        my @components = split("\\|", $signature_pair);

        if ($components[0] eq $self->gateway->config->public_key) {
            return $components[1];
        }
    }
}

sub _validate_signature {
    my ($self, $signature, $payload) = @_;
    my $matching_signature = $self->_matching_signature($signature, $payload);
    if (defined($matching_signature) && $matching_signature ne hexdigest($self->gateway->config->private_key, $payload)) {
        confess "InvalidSignature";
    }
}

sub verify {
    my ($self, $challenge) = @_;
    if ($challenge !~ /^[a-f0-9]{20,32}$/) {
        confess "InvalidChallenge";
    }
    return $self->gateway->config->public_key . "|" . hexdigest($self->gateway->config->private_key, $challenge);
}

__PACKAGE__->meta->make_immutable;
1;

