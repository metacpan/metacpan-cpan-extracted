# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::SubscriptionGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';
with 'WebService::Braintree::Role::CollectionBuilder';

use Carp qw(confess);

use WebService::Braintree::Util qw(validate_id);
use WebService::Braintree::Validations qw(verify_params);

use WebService::Braintree::_::Subscription;
use WebService::Braintree::SubscriptionSearch;

sub create {
    my ($self, $params) = @_;

    confess "ArgumentError" unless verify_params($params, _signature_for('create'));

    my $result = $self->_make_request("/subscriptions/", "post", {subscription => $params});
    return $result;
}

sub find {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    my $result = $self->_make_request("/subscriptions/$id", "get", undef)->subscription;
}

sub update {
    my ($self, $id, $params) = @_;

    confess "NotFoundError" unless validate_id($id);
    confess "ArgumentError" unless verify_params($params, _signature_for('update'));

    my $result = $self->_make_request("/subscriptions/$id", "put", {subscription => $params});
}

sub cancel {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    my $result = $self->_make_request("/subscriptions/$id/cancel", "put", undef);
}

sub search {
    my ($self, $block) = @_;

    return $self->resource_collection({
        ids_url => "/subscriptions/advanced_search_ids",
        obj_url => "/subscriptions/advanced_search",
        inflate => [qw/subscriptions subscription _::Subscription/],
        search => $block->(WebService::Braintree::SubscriptionSearch->new),
    });
}

sub all {
    my $self = shift;

    return $self->resource_collection({
        ids_url => "/subscriptions/advanced_search_ids",
        obj_url => "/subscriptions/advanced_search",
        inflate => [qw/subscriptions subscription _::Subscription/],
    });
}

sub _signature_for {
    my ($type) = @_;

    my $signature = {
        id => 1,
        merchant_account_id => 1,
        never_expires => 1,
        number_of_billing_cycles => 1,
        payment_method_nonce => 1,
        payment_method_token => 1,
        plan_id => 1,
        price => 1,
        options => {
            paypal => {
                description => 1,
            },
        },
        add_ons => {
            add => '_any_key_',
            update => '_any_key_',
            remove => '_any_key_',
        },
        discounts => {
            add => '_any_key_',
            update => '_any_key_',
            remove => '_any_key_',
        },
        descriptor => {
            name => 1,
            phone => 1,
            url => 1,
        },
    };

    if ($type eq 'create') {
        $signature = {
            %{$signature},
            billing_day_of_month => 1,
            first_billing_date => 1,
            trial_duration => 1,
            trial_duration_unit => 1,
            trial_period => 1,
        };
        $signature->{options} = {
            %{$signature->{options}},
            do_not_inherit_add_ons_or_discounts => 1,
            start_immediately => 1,
        };
    }
    elsif ($type eq 'update') {
        $signature->{options} = {
            %{$signature->{options}},
            prorate_charges => 1,
            replace_all_add_ons_and_discounts => 1,
            revert_subscription_on_proration_failure => 1,
        };
    }

    return $signature;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
