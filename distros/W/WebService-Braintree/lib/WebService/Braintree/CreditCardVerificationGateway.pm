package WebService::Braintree::CreditCardVerificationGateway;
$WebService::Braintree::CreditCardVerificationGateway::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';
with 'WebService::Braintree::Role::CollectionBuilder';

use WebService::Braintree::CreditCardVerificationSearch;
use WebService::Braintree::Util qw(validate_id);
use WebService::Braintree::Validations qw(
    verify_params
    credit_card_verification_signature
);
use Carp qw(confess);

has 'gateway' => (is => 'ro');

sub find {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    my $response = $self->gateway->http->get("/verifications/$id");
    return WebService::Braintree::CreditCardVerification->new($response->{'verification'});
}

sub search {
    my ($self, $block) = @_;

    return $self->resource_collection({
        ids_url => "/verifications/advanced_search_ids",
        obj_url => "/verifications/advanced_search/",
        inflate => [qw/credit_card_verifications verification CreditCardVerification/],
        search => $block->(WebService::Braintree::CreditCardVerificationSearch->new),
    });
}

sub all {
    my $self = shift;

    return $self->resource_collection({
        ids_url => "/verifications/advanced_search_ids",
        obj_url => "/verifications/advanced_search/",
        inflate => [qw/credit_card_verifications verification CreditCardVerification/],
    });
}

sub create {
    my ($self, $params) = @_;
    confess "ArgumentError" unless verify_params($params, credit_card_verification_signature);
    $self->_make_request("/verifications", "post", {verification => $params});
}

__PACKAGE__->meta->make_immutable;

1;
__END__
