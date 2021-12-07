package Web::MarketReceipt::Verifier::GooglePlay;
use Mouse;
use Mouse::Util::TypeConstraints;
extends 'Web::MarketReceipt::Verifier';
use utf8;

use Web::MarketReceipt;
use Carp;
use Crypt::OpenSSL::RSA;
use MIME::Base64;
use JSON::XS;

subtype 'Crypt::OpenSSL::RSA' => as 'Object' => where { $_->isa('Crypt::OpenSSL::RSA') };
coerce  'Crypt::OpenSSL::RSA'
    => from 'Str',
    => via { Crypt::OpenSSL::RSA->new_public_key($_) };

# need pem format
has public_key => (
    is       => 'ro',
    isa      => 'Crypt::OpenSSL::RSA',
    required => 1,
    coerce   => 1,
);

no Mouse;

sub verify {
    my ($self, %args) = @_;

    # TODO 例外処理
    my $signed_data = decode_base64 $args{signed_data};
    my $signature   = decode_base64 $args{signature};

    my $verification_result = $self->public_key->verify($signed_data, $signature);
    my $raw_json = decode_json $signed_data;

    Web::MarketReceipt->new(
        is_success => $verification_result ? 1 : 0,
        store      => 'GooglePlay',
        raw        => $raw_json,
        $verification_result ? (
            exists $raw_json->{orders} ? (
                orders => [ map { $self->_order2hash($_) } @{ $raw_json->{orders} } ],
            ) : (
                orders => [ $self->_order2hash($raw_json) ],
            ),
        ) : (),
    );
}

sub _order2hash {
    my ($self, $order) = @_;

    return {
        product_identifier => $order->{productId},
        unique_identifier  => 'GooglePlay:' . $order->{orderId},
        purchased_epoch    => int( $order->{purchaseTime}/1000 ),
        state       => $self->_purchase_state($order->{purchaseState}),
        quantity    => 1,
        environment => 'Production',
    };
}

sub _purchase_state {
    my ($self, $purchase_state) = @_;

    if ($purchase_state == 0) {
        return 'purchased';
    } elsif ($purchase_state == 1) {
        return 'canceled';
    } elsif ($purchase_state == 2) {
        return 'refunded';
    } elsif ($purchase_state == 3) {
        return 'expired';
    } elsif ($purchase_state == 4) {
        return 'pending';
    }

    croak sprintf 'invalid purchase state: %s', $purchase_state;
}

1;
