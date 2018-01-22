package WebService::BitFlyer::API;
use strict;
use warnings;
use Class::Accessor::Lite (
    ro  => [qw/
        client
    /],
);

# https://lightning.bitflyer.jp/docs

sub new {
    my $class  = shift;
    my $client = shift;

    bless {
        client => $client,
    }, $class;
}

sub markets {
    my ($self, %params) = @_;

    my $req_params;

    my $res = $self->client->request(
        'GET' => '/v1/markets',
        $req_params,
    );

    return $res;
}

sub board {
    my ($self, %params) = @_;

    my $req_params = {
        product_code => $params{product_code} || 'BTC_JPY',
    };

    my $res = $self->client->request(
        'GET' => '/v1/board',
        $req_params,
    );

    return $res;
}

sub ticker {
    my ($self, %params) = @_;

    my $req_params = {
        product_code => $params{product_code} || 'BTC_JPY',
    };

    my $res = $self->client->request(
        'GET' => '/v1/ticker',
        $req_params,
    );

    return $res;
}

sub market_executions {
    my ($self, %params) = @_;

    my %paginate = (
        $params{count}  ? (count  => $params{count})  : (),
        $params{before} ? (before => $params{before}) : (),
        $params{after}  ? (after  => $params{after})  : (),
    );

    my $req_params = {
        product_code => $params{product_code} || 'BTC_JPY',
        %paginate,
    };

    my $res = $self->client->request(
        'GET' => '/v1/executions',
        $req_params,
    );

    return $res;
}

sub boardstate {
    my ($self, %params) = @_;

    my $req_params = {
        product_code => $params{product_code} || 'BTC_JPY',
    };

    my $res = $self->client->request(
        'GET' => '/v1/getboardstate',
        $req_params,
    );

    return $res;
}

sub health {
    my ($self, %params) = @_;

    my $req_params = {
        product_code => $params{product_code} || 'BTC_JPY',
    };

    my $res = $self->client->request(
        'GET' => '/v1/gethealth',
        $req_params,
    );

    return $res;
}

sub chats {
    my ($self, %params) = @_;

    my $req_params = {
        from_date => $params{from_date},
    };

    my $res = $self->client->request(
        'GET' => '/v1/getchats',
        $req_params,
    );

    return $res;
}

sub permissions {
    my ($self, %params) = @_;

    my $res = $self->client->request(
        'GET' => '/v1/me/getpermissions',
    );

    return $res;
}

sub balance {
    my ($self, %params) = @_;

    my $res = $self->client->request(
        'GET' => '/v1/me/getbalance',
    );

    return $res;
}

sub collateral {
    my ($self, %params) = @_;

    my $res = $self->client->request(
        'GET' => '/v1/me/getcollateral',
    );

    return $res;
}

sub collateralaccounts {
    my ($self, %params) = @_;

    my $res = $self->client->request(
        'GET' => '/v1/me/getcollateralaccounts',
    );

    return $res;
}

sub coinins {
    my ($self, %params) = @_;

    my %paginate = (
        $params{count}  ? (count  => $params{count})  : (),
        $params{before} ? (before => $params{before}) : (),
        $params{after}  ? (after  => $params{after})  : (),
    );

    my $req_params = {
        %paginate,
    };

    my $res = $self->client->request(
        'GET' => '/v1/me/getcoinins',
        $req_params,
    );

    return $res;
}

sub coinouts {
    my ($self, %params) = @_;

    my %paginate = (
        $params{count}  ? (count  => $params{count})  : (),
        $params{before} ? (before => $params{before}) : (),
        $params{after}  ? (after  => $params{after})  : (),
    );

    my $req_params = {
        %paginate,
    };

    my $res = $self->client->request(
        'GET' => '/v1/me/getcoinouts',
        $req_params,
    );

    return $res;
}

sub bankaccounts {
    my ($self, %params) = @_;

    my $res = $self->client->request(
        'GET' => '/v1/me/getbankaccounts',
    );

    return $res;
}

sub deposits {
    my ($self, %params) = @_;

    my %paginate = (
        $params{count}  ? (count  => $params{count})  : (),
        $params{before} ? (before => $params{before}) : (),
        $params{after}  ? (after  => $params{after})  : (),
    );

    my $req_params = {
        %paginate,
    };

    my $res = $self->client->request(
        'GET' => '/v1/me/getdeposits',
        $req_params,
    );

    return $res;
}

sub withdraw {
    my ($self, %params) = @_;

    my $req_params = {
        currency_code   => $params{currency_code} || 'JPY',
        bank_account_id => $params{bank_account_id},
        amount          => $params{amount},
        code            => $params{code},
    };

    my $res = $self->client->request(
        'POST' => '/v1/me/withdraw',
        $req_params,
    );

    return $res;
}

sub withdrawals {
    my ($self, %params) = @_;

    my %paginate = (
        $params{count}  ? (count  => $params{count})  : (),
        $params{before} ? (before => $params{before}) : (),
        $params{after}  ? (after  => $params{after})  : (),
    );

    my $req_params = {
        message_id => $params{mesage_id},
        %paginate,
    };

    my $res = $self->client->request(
        'GET' => '/v1/me/getwithdrawals',
        $req_params,
    );

    return $res;
}

sub order {
    my ($self, %params) = @_;

    my $req_params = {
        product_code     => $params{product_code} || 'BTC_JPY',
        child_order_type => $params{child_order_type},
        side             => $params{side},
        price            => $params{price},
        size             => $params{size},
        minute_to_expire => $params{minute_to_expire},
        time_in_force    => $params{time_in_force} || 'GTC',
    };

    my $res = $self->client->request(
        'POST' => '/v1/me/sendchildorder',
        $req_params,
    );

    return $res;
}

sub cancel_order {
    my ($self, %params) = @_;

    my $req_params = {
        product_code              => $params{product_code} || 'BTC_JPY',
        child_order_id            => $params{child_order_id},
        child_order_acceptance_id => $params{child_order_acceptance_id},
    };

    my $res = $self->client->request(
        'POST' => '/v1/me/cancelchildorder',
        $req_params,
    );

    return $res;
}

sub cancel_all {
    my ($self, %params) = @_;

    my $req_params = {
        product_code => $params{product_code} || 'BTC_JPY',
    };

    my $res = $self->client->request(
        'POST' => '/v1/me/cancelallchildorders',
        $req_params,
    );

    return $res;
}

sub orders {
    my ($self, %params) = @_;

    my %paginate = (
        $params{count}  ? (count  => $params{count})  : (),
        $params{before} ? (before => $params{before}) : (),
        $params{after}  ? (after  => $params{after})  : (),
    );

    my $req_params = {
        product_code              => $params{product_code} || 'BTC_JPY',
        child_order_state         => $params{child_order_state},
        child_order_id            => $params{child_order_id},
        child_order_acceptance_id => $params{child_order_acceptance_id},
        parent_order_id           => $params{parent_order_id},
        %paginate,
    };

    my $res = $self->client->request(
        'GET' => '/v1/me/getchildorders',
        $req_params,
    );

    return $res;
}

sub executions {
    my ($self, %params) = @_;

    my %paginate = (
        $params{count}  ? (count  => $params{count})  : (),
        $params{before} ? (before => $params{before}) : (),
        $params{after}  ? (after  => $params{after})  : (),
    );

    my $req_params = {
        product_code              => $params{product_code} || 'BTC_JPY',
        child_order_id            => $params{child_order_id},
        child_order_acceptance_id => $params{child_order_acceptance_id},
        %paginate,
    };

    my $res = $self->client->request(
        'GET' => '/v1/me/getexecutions',
        $req_params,
    );

    return $res;
}


sub trading_commission {
    my ($self, %params) = @_;

    my $req_params = {
        product_code => $params{product_code} || 'BTC_JPY',
    };

    my $res = $self->client->request(
        'GET' => '/v1/me/gettradingcommission',
        $req_params,
    );

    return $res;
}

1;
