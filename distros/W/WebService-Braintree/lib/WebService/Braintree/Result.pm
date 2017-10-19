package WebService::Braintree::Result;
$WebService::Braintree::Result::VERSION = '0.94';
use 5.010_001;
use strictures 1;

use Moose;
use Hash::Inflator;

use WebService::Braintree::Util qw(is_hashref);

# XXX: Why only these classes?
use WebService::Braintree::ValidationErrorCollection;
use WebService::Braintree::CreditCardVerification;
use WebService::Braintree::Nonce;

my $meta = __PACKAGE__->meta;

my $response_objects = {
    address => "WebService::Braintree::Address",
    apple_pay => "WebService::Braintree::ApplePayCard",
    apple_pay_card => "WebService::Braintree::ApplePayCard",
    credit_card => "WebService::Braintree::CreditCard",
    customer => "WebService::Braintree::Customer",
    merchant_account => "WebService::Braintree::MerchantAccount",
    payment_method => {
        credit_card => "WebService::Braintree::CreditCard",
        paypal_account => "WebService::Braintree::PayPalAccount"
    },
    payment_method_nonce => 'WebService::Braintree::Nonce',
    settlement_batch_summary => "WebService::Braintree::SettlementBatchSummary",
    subscription => "WebService::Braintree::Subscription",
    transaction => "WebService::Braintree::Transaction",
};

has response => ( is => 'ro' );

sub _get_response {
    my $self = shift;
    return $self->response->{'api_error_response'} || $self->response;
}

sub patch_in_response_accessors {
    my $field_rules = shift;
    while (my($key, $rule) = each(%$field_rules)) {
        if (is_hashref($rule)) {
            $meta->add_method($key, sub {
                                  my $self = shift;
                                  my $response = $self->_get_response();
                                  while (my($subkey, $subrule) = each(%$rule)) {
                                      my $field_value = $self->$subkey;
                                      if ($field_value) {
                                          keys %$rule;
                                          return $field_value;
                                      }
                                  }

                                  return undef;
                              });

            patch_in_response_accessors($rule);
        } else {
            $meta->add_method($key, sub {
                                  my $self = shift;
                                  my $response = $self->_get_response();
                                  if (!$response->{$key}) {
                                      return undef;
                                  }

                                  return $rule->new($response->{$key});
                              });
        }
    }
}

patch_in_response_accessors($response_objects);

sub is_success {
    my $self = shift;

    return if $self->response->{'api_error_response'};

    return 1;
}

sub api_error_response {
    my $self = shift;
    return $self->response->{'api_error_response'};
}

sub message {
    my $self = shift;
    return $self->api_error_response->{'message'} if $self->api_error_response;
    return "";
}

sub errors {
    my $self = shift;
    return WebService::Braintree::ValidationErrorCollection->new($self->api_error_response->{errors});
}

sub credit_card_verification {
    my $self = shift;
    return WebService::Braintree::CreditCardVerification->new($self->api_error_response->{verification});
}

__PACKAGE__->meta->make_immutable;

1;
__END__
