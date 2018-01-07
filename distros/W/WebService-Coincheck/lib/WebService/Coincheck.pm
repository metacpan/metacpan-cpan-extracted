package WebService::Coincheck;
use strict;
use warnings;
use Carp qw/croak/;
use HTTP::Tiny;
use Time::HiRes qw/time/;
use URI::Query;
use Digest::SHA qw/hmac_sha256_hex/;
use String::CamelCase qw/camelize/;
use Class::Load qw/load_class/;
use JSON qw//;
use Class::Accessor::Lite (
    ro  => [qw/
        api_base
        access_key
        secret_key
        ticker
        trade
        order_book
        order
        leverage
        account
        send
        deposit
        bank_account
        withdraw
        borrow
        transfer
    /],
    rw  => [qw/
        client
        signature
        nonce
        decode_json
    /],
);

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless {
        decode_json => 0,
        api_base    => 'https://coincheck.jp/',
        %args,
    }, $class;

    $self->_initialize;

    return $self;
}

sub _initialize {
    my ($self) = @_;

    $self->client(
        HTTP::Tiny->new(
            agent   => __PACKAGE__ . "/$VERSION",
            default_headers => {
                'Content-Type' => 'application/json',
                'ACCESS-KEY'   => $self->access_key,
            },
            timeout => 15,
        )
    );

    for my $api (qw/
        ticker
        trade
        order_book
        order
        leverage
        account
        send
        deposit
        bank_account
        withdraw
        borrow
        transfer
    /) {
        my $klass = 'WebService::Coincheck::' . camelize($api);
        $self->{$api} = load_class($klass)->new($self);
    }
}

sub set_signature {
    my ($self, $req_url) = @_;

    $self->nonce(int(time * 10000));
    $self->signature(hmac_sha256_hex($self->nonce . $req_url, $self->secret_key));
}

sub request {
    my ($self, $method, $req_path, $query) = @_;

    my $res;

    if ($method =~ m!^get$!i) {
        my $query_string = URI::Query->new($query)->stringify;
        my $req_url = join '', $self->api_base, $req_path, $query_string ? "?$query_string" : '';
        $self->set_signature($req_url);
        $res = $self->client->get(
            $req_url,
            {
                headers => {
                    'ACCESS-NONCE'     => $self->nonce,
                    'ACCESS-SIGNATURE' => $self->signature,
                },
            },
        );
    }
    elsif ($method =~ m!^(?:post|delete)$!i) {
        my $req_url = join '', $self->api_base, $req_path;
        $self->set_signature($req_url);
        $res = $self->client->request(
            'POST',
            $req_url,
            {
                content => {
                    %{$query || {}},
                },
                headers => {
                    'ACCESS-NONCE'     => $self->nonce,
                    'ACCESS-SIGNATURE' => $self->signature,
                },
            },
        );
    }

    unless ($res->{success}) {
        croak "Error:" . join "\t", map { $res->{$_} } (qw/url status reason content/);
    }

    if ($self->decode_json) {
        return JSON::decode_json($res->{content});
    }
    else {
        return $res->{content};
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

WebService::Coincheck - coincheck Perl libraries L<http://coincheck.jp/>


=head1 SYNOPSIS

    use WebService::Coincheck;

    my $coincheck = WebService::Coincheck->new(
        access_key => 'YOUR_ACCESSKEY',
        secret_key => 'YOUR_SECRETKEY',
    );

    # Public API
    $coincheck->ticker->all;
    $coincheck->trade->all;
    $coincheck->order_book->all;

    # Private API
    # 新規注文
    # "buy" 指値注文 現物取引 買い
    # "sell" 指値注文 現物取引 売り
    # "market_buy" 成行注文 現物取引 買い
    # "market_sell" 成行注文 現物取引 売り
    # "leverage_buy" 指値注文 レバレッジ取引新規 買い
    # "leverage_sell" 指値注文 レバレッジ取引新規 売り
    # "close_long" 指値注文 レバレッジ取引決済 売り
    # "close_short" 指値注文 レバレッジ取引決済 買い
    $coincheck->order->create(
        rate       => "28500",
        amount     => "0.00508771",
        order_type => "buy",
        pair       => "btc_jpy"
    );
    # 未決済の注文一覧
    $coincheck->order->opens;
    # 注文のキャンセル
    $coincheck->order->cancel(id => 2953613);
    # 取引履歴
    $coincheck->order->transactions;
    # ポジション一覧
    $coincheck->leverage->positions;
    # 残高
    $coincheck->account->balance;
    # レバレッジアカウントの残高
    $coincheck->account->leverage_balance;
    # アカウント情報
    $coincheck->account->info;
    # ビットコインの送金
    $coincheck->send->create(
        address => '1Gp9MCp7FWqNgaUWdiUiRPjGqNVdqug2hY',
        amount  => '0.0002'
    );
    # ビットコインの送金履歴
    $coincheck->send->all(currency => "BTC");
    # ビットコインの受け取り履歴
    $coincheck->deposit->all(currency => "BTC");
    # ビットコインの高速入金
    $coincheck->deposit->fast(id => 2222);
    # 銀行口座一覧
    $coincheck->bank_account->all;
    # 銀行口座の登録
    $coincheck->bank_account->create(
        bank_name         => "住信SBIネット",
        branch_name       => "ミカン",
        bank_account_type => "futu",
        number            => "123456",
        name              => "ヤマモト タロウ"
    );
    # 銀行口座の削除
    $coincheck->bank_account->delete;
    # 出金履歴
    $coincheck->withdraw->all;
    # 出金申請の作成
    $coincheck->withdraw->create(
        bank_account_id => 2222,
        amount          => 50000,
        currency        => "JPY",
        is_fast         => false
    );
    # 出金申請のキャンセル
    $coincheck->withdraw->cancel;
    # 借入申請
    $coincheck->borrow->create(
        amount   => "0.01",
        currency => "BTC"
    );
    # 借入中一覧
    $coincheck->borrow->matches;
    # 返済
    $coincheck->borrow->repay(id => "1135");
    # レバレッジアカウントへの振替
    $coincheck->transfer->to_leverage(
        amount   => 100,
        currency => "JPY"
    );
    # レバレッジアカウントからの振替
    $coincheck->transfer->from_leverage(
        amount   => 100,
        currency => "JPY"
    );


=head1 DESCRIPTION

WebService::Coincheck is the Perl libraries for L<http://coincheck.jp/> API

=head1 METHODS

=head2 new

the constructor

=head2 set_signature

generate signature

=head2 request

calling API


=head1 REPOSITORY

WebService::Coincheck is hosted on github: L<http://github.com/bayashi/WebService-Coincheck>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<http://coincheck.jp/>

L<https://coincheck.com/ja/documents/exchange/api>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
