package WebService::Dropbox::Users;
use strict;
use warnings;
use parent qw(Exporter);

our @EXPORT = do {
    no strict 'refs';
    grep { $_ !~ qr{ \A [A-Z]+ \z }xms } keys %{ __PACKAGE__ . '::' };
};

# https://www.dropbox.com/developers/documentation/http/documentation#users-get_account
sub get_account {
    my ($self, $account_id) = @_;

    $self->api({
        url => 'https://api.dropboxapi.com/2/users/get_account',
        params => {
            account_id => $account_id,
        },
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#users-get_account_batch
sub get_account_batch {
    my ($self, $account_ids) = @_;

    $self->api({
        url => 'https://api.dropboxapi.com/2/users/get_account_batch',
        params => {
            account_ids => $account_ids,
        },
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#users-get_current_account
sub get_current_account {
    my ($self) = @_;

    $self->api({
        url => 'https://api.dropboxapi.com/2/users/get_current_account',
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#users-get_space_usage
sub get_space_usage {
    my ($self) = @_;

    $self->api({
        url => 'https://api.dropboxapi.com/2/users/get_space_usage',
    });
}

1;
