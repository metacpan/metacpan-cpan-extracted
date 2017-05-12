package Web::MarketReceipt::Verifier::AppStore;
use 5.010;
use Mouse;
extends 'Web::MarketReceipt::Verifier';
use utf8;
use Carp;

no Mouse;

use Web::MarketReceipt;
use Furl;
use JSON::XS;
use Try::Tiny;
use MIME::Base64;

sub verify {
    my ($self, %args) = @_;

    my $environment = 'Production';
    my $receipt = $args{receipt};

    my $hash = {
        'receipt-data' => $receipt,
    };

    # try production environment first. cf.
    #   https://developer.apple.com/library/ios/technotes/tn2259/_index.html FAQ16
    #   http://nantekottai.com/2012/08/27/verifying-receipts/
    my $res_json = $self->_send_request(
        environment => $environment,
        hash        => $hash,
        opts        => $args{opts},
    );

    if ($res_json->{status} == 21007) {
        $environment = 'Sandbox';
        $res_json = $self->_send_request(
            environment => $environment,
            hash        => $hash,
        );
    }

    my $raw_json = $res_json->{receipt};
    Web::MarketReceipt->new(
        is_success => $res_json->{status} == 0 ? 1 : 0,
        store      => 'AppStore',
        raw        => $raw_json,
        $res_json->{status} == 0 ? (
            exists $raw_json->{in_app} ? (
                orders => [ map {$self->_order2hash($_, $environment)} @{ $raw_json->{in_app}}],
            ) : (
                orders => [$self->_order2hash($raw_json, $environment)],
            ),
        ) : (),
    );
}

sub _order2hash {
    my ($self, $raw_json, $environment) = @_;

    return {
        product_identifier => $raw_json->{product_id},
        unique_identifier  => 'AppStore:' . $raw_json->{original_transaction_id},
        purchased_epoch    => $raw_json->{original_purchase_date_ms},
        quantity    => $raw_json->{quantity},
        environment => $environment,
        state       => 'purchased',
    }
}

sub _send_request {
    my ($self, %args) = @_;

    my $environment = $args{environment};
    my $url = {
        Production => 'https://buy.itunes.apple.com/verifyReceipt',
        Sandbox    => 'https://sandbox.itunes.apple.com/verifyReceipt',
    }->{$environment};

    state $json_driver = JSON::XS->new->utf8;
    my $json_str = $json_driver->encode($args{hash});

    state $furl = Furl->new(%{ $args{opts} });
    my $res = $furl->post($url, [], $json_str);

    if ($res->status != 200) {
        Web::MarketReceipt::Verifier::AppStore::Exception->throw(
            message     => sprintf('HTTP Status Error(%s):%s %s', $environment, $res->status, $res->message),
            response    => $res,
            environment => $environment,
        );
    }

    my $res_json = eval { $json_driver->decode($res->body) } or Web::MarketReceipt::Verifier::AppStore::Exception->throw(
        message     => sprintf('body is not json(%s)', $environment),
        response    => $res,
        environment => $environment,
    );
    $res_json;
}

package Web::MarketReceipt::Verifier::AppStore::Exception;
use strict;
use warnings;
use utf8;

use parent 'Exception::Tiny';

use Class::Accessor::Lite (
    ro  => [qw/response environment/]
);

sub throw {
    my ($class, %args) = @_;

    ($args{package}, $args{file}, $args{line}) = caller(2);
    $args{subroutine} = (caller(3))[3];

    die $class->new(%args);
}

1;
