# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::CreditCardVerificationGateway;

use 5.010_001;
use strictures 1;

use Moo;
with 'WebService::Braintree::Role::MakeRequest';
with 'WebService::Braintree::Role::CollectionBuilder';

use Carp qw(confess);

use WebService::Braintree::Util qw(validate_id);
use WebService::Braintree::Validations qw(
    verify_params
    credit_card_verification_signature
);

use WebService::Braintree::_::CreditCardVerification;
use WebService::Braintree::CreditCardVerificationSearch;

sub find {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    $self->_make_request("/verifications/$id", "get", undef)->verification;
}

sub search {
    my ($self, $block) = @_;

    return $self->resource_collection({
        ids_url => "/verifications/advanced_search_ids",
        obj_url => "/verifications/advanced_search/",
        inflate => [qw/credit_card_verifications verification _::CreditCardVerification/],
        search => $block->(WebService::Braintree::CreditCardVerificationSearch->new),
    });
}

sub all {
    my $self = shift;

    return $self->resource_collection({
        ids_url => "/verifications/advanced_search_ids",
        obj_url => "/verifications/advanced_search/",
        inflate => [qw/credit_card_verifications verification _::CreditCardVerification/],
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
