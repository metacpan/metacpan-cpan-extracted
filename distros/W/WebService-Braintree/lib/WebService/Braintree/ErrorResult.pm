package WebService::Braintree::ErrorResult;
$WebService::Braintree::ErrorResult::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose;

use WebService::Braintree::Util qw(is_hashref);
use WebService::Braintree::ValidationErrorCollection;

my %attrs_with_classes = (
    verification => 'CreditCardVerification',
    merchant_account => 'MerchantAccount',
    transaction => 'Transaction',
    subscription => 'Subscription',
    errors => 'ValidationErrorCollection',
);

my @attrs = (
    qw(params message),
    (keys %attrs_with_classes),
);

has($_ => ( is => 'rw' )) for @attrs;

sub credit_card_verification {
    my $self = shift;
    return $self->verification(@_);
}

sub is_success { 0 }

sub BUILD {
    my ($self, $params) = @_;

    foreach my $attr (@attrs) {
        next unless exists $params->{$attr};

        my $value = $params->{$attr};
        my $class = $attrs_with_classes{$attr};
        if ($class) {
            $value = "WebService::Braintree::${class}"->new($value);
        }
        $self->$attr($value);
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
