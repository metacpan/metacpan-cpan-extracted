package WebService::EveOnline::API::Account;

use strict;
use base qw/ WebService::EveOnline::Base /;

our $VERSION = "0.61";

our $division = {
    1000 => 'first',
    1001 => 'second',
    1002 => 'third',
    1003 => 'fourth',
    1004 => 'fifth',
    1005 => 'sixth',
    1006 => 'seventh',
};

=head2

Get wallet data for the an EVE character

=cut

=head4 new

This is called under the hood when an accounts object is requested on the $eve->character object.

It returns an array of account objects for the selected character. The first member of the array ALWAYS returns the selected character's personal account object.

=cut

sub new {
    my ($self, $c) = @_;

    my $corporate = $self->call_api('corp_accounts', { characterID => $c->id }, $c)->{accounts};
    my $personal = $self->call_api('accounts', { characterID => $c->id }, $c)->{accounts};

    my @accounts;

    foreach my $account (@{$personal}) {
        push(@accounts, bless({ type => 'personal', balance => $account->{balance}, division => $division->{$account->{accountKey}}, account_id => $account->{accountID}, account_key => $account->{accountKey}, _evecache => $c->{_evecache}, _api_key => $c->{_api_key}, _user_id => $c->{_user_id} }, __PACKAGE__));
    }

    foreach my $account (@{$corporate}) {
        push(@accounts, bless({ type => 'corporate', balance => $account->{balance}, division => $division->{$account->{accountKey}}, account_id => $account->{accountID}, account_key => $account->{accountKey}, _evecache => $c->{_evecache}, _api_key => $c->{_api_key}, _user_id => $c->{_user_id} }, __PACKAGE__));
    }

    if (wantarray) {
        return @accounts;
    } else {
        return $accounts[0];
    }
}

=head4 $account->balance

Returns the balance of an account object in ISK.

=cut

sub balance {
    my $self = shift;
    return ref($self) eq "ARRAY" ? $self->[0]->{balance} : $self->{balance};
}

=head4 $account->division

Returns the division of an account object. The master division is "first", the final division (for corporate accounts) is "seventh".

=cut

sub division {
    my $self = shift;
    return ref($self) eq "ARRAY" ? $self->[0]->{division} : $self->{division};
}

=head4 $account->type

Returns the type of an account object -- can be "personal" or "corporate"

=cut

sub type {
    my $self = shift;
    return ref($self) eq "ARRAY" ? $self->[0]->{type} : $self->{type};
}

=head4 $account->id

Returns the id of the account object. 

=cut

sub id {
    my $self = shift;
    return ref($self) eq "ARRAY" ? $self->[0]->{account_id} : $self->{account_id};
}

=head4 $account->key

Returns the key of the account object. This equates to division.

=cut

sub key {
    my $self = shift;
    return ref($self) eq "ARRAY" ? $self->[0]->{account_key} : $self->{account_key};
}

1;
