package WebService::EveOnline::API::Transactions;

our $VERSION = "0.61";

=head2 $character->transactions

Recent transaction list (last 1000). Set offset before_trans_id to recall older transactions.

=cut

use base qw/ WebService::EveOnline::Base /;

=head2 new

This is called under the hood when an $eve->character->transaction(s) object is requested.

It returns an array of transaction objects, or the latest transaction depending on whether or
not it is called in scalar or list context.

You probably won't need to call this method directly.

=cut 

sub new {
    my ($self, $c) = @_;
    my $raw_transactions = $self->call_api('transactions', { characterID => $c->id, beforeTransID => $c->before_trans_id }, $c);
    
    my @transactions;
    foreach my $trans (@{$raw_transactions->{transactions}}) {
        push(@transactions, bless({
            _trans_for => $trans->{transactionFor},
            _trans_type_name => $trans->{typeName},
            _trans_type => $trans->{transactionType},
            _trans_quantity => $trans->{quantity},
            _trans_station_id => $trans->{stationID},
            _trans_client_id => $trans->{clientID},
            _trans_client_name => $trans->{clientName} || "Someone",
            _trans_type_id => $trans->{typeID},
            _trans_id => $trans->{transactionID},
            _trans_price => $trans->{price},
            _trans_station_name => $trans->{stationName},
            _trans_evetime => $trans->{transactionDateTime},
            _trans_time => &WebService::EveOnline::Cache::_evedate_to_epoch($trans->{transactionDateTime}),
            _evecache => $c->{_evecache},
            _api_key => $c->{_api_key},
            _user_id => $c->{_user_id},
        }, __PACKAGE__));
    }
    if (wantarray) {
        return @transactions;
    } else {
        return $transactions[0]
    }
}

=head2 $transaction->for

Who the transaction is for (personal, or presumably corporate)

=cut

sub for {
    my ($self) = @_;
    return $self->{_trans_for};
}

=head2 $transaction->name

The name of the transaction, e.g. the name of the item you're selling/buying.

=cut

sub name {
    my ($self) = @_;
    return $self->{_trans_type_name};
}

=head2 $transaction->type

The transaction type (e.g. buy/sell)

=cut

sub type {
    my ($self) = @_;
    return $self->{_trans_type};
}

=head2 $transaction->quantity

The quantity involved in the transaction

=cut

sub quantity {
    my ($self) = @_;
    return $self->{_trans_quantity};
}

=head2 $transaction->station_id

The station ID of where the transaction took place (see also transaction_station_name)

=cut

sub station_id {
    my ($self) = @_;
    return $self->{_trans_station_id};
}

=head2 $transaction->client_id

The ID of the client (who is buying/selling the item)

=cut

sub client_id {
    my ($self) = @_;
    return $self->{_trans_client_id};
}

=head2 $transaction->client_name

The name of the client (who is buying/selling the item)

=cut

sub client_name {
    my ($self) = @_;
    return $self->{_trans_client_name};
}

=head2 $transaction->type_id

The type ID of the transaction. 

=cut

sub type_id {
    my ($self) = @_;
    return $self->{_trans_type_id};
}

=head2 $transaction->id

The ID of the transaction. Use the lowest transaction ID to walk back in time by setting before_trans_id.

=cut

sub id {
    my ($self) = @_;
    return $self->{_trans_id};
}

=head2 $transaction->price

The price of the transaction

=cut

sub price {
    my ($self) = @_;
    return $self->{_trans_price};
}

=head2 $transaction->time

The time of the transaction in epoch seconds.

=cut

sub time {
    my ($self) = @_;
    return $self->{_trans_time};
}

=head2 $transaction->evetime

The time of the transaction according to EVE.

YYYY-MM-DD HH-MM-SS format. Always GMT/UTC.

=cut

sub evetime {
    my ($self) = @_;
    return $self->{_trans_evetime};
}

=head2 $transaction->station_name

The station name where the transaction took place (see also station_id).

=cut

sub station_name {
    my ($self) = @_;
    return $self->{_trans_station_name};
}

=head2 $character->account_key

Sets the account key for retrieving transactions from a particular account. defaults to 1000.

=cut

sub account_key {
    my ($self, $account_key) = @_;
    $self->{_account_key} = $account_key if $account_key;
    return $self->{_account_key} || 1000;
}

=head2 $transaction->hashref

A hashref containing the details for a transaction. It contains the following keys:

    transaction_for
    transaction_type_name
    transaction_type
    transaction_quantity
    transaction_station_id
    transaction_client_id
    transaction_client_name
    transaction_type_id
    transaction_id
    transaction_price
    transaction_time
    transaction_station_name

=cut

sub hashref {
    my ($self) = @_;
    return {
        transaction_for => $self->{_trans_for},
        transaction_type_name => $self->{_trans_type_name},
        transaction_type => $self->{_trans_type},
        transaction_quantity => $self->{_trans_quantity},
        transaction_station_id => $self->{_trans_station_id},
        transaction_client_id => $self->{_trans_client_id},
        transaction_client_name => $self->{_trans_client_name},
        transaction_type_id => $self->{_trans_type_id},
        transaction_id => $self->{_trans_id},
        transaction_price => $self->{_trans_price},
        transaction_time => $self->{_trans_time},
        transaction_station_name => $self->{_trans_station_name},
    };
}

1;

