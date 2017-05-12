package WebService::Dropbox::Files::ListFolder;
use strict;
use warnings;
use parent qw(Exporter);

our @EXPORT = do {
    no strict 'refs';
    grep { $_ !~ qr{ \A [A-Z]+ \z }xms } keys %{ __PACKAGE__ . '::' };
};


# https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder
sub list_folder {
    my ($self, $path, $optional_params) = @_;

    my $params = {
        path => $path,
        %{ $optional_params || {} },
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/list_folder',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-continue
sub list_folder_continue {
    my ($self, $cursor) = @_;

    my $params = {
        cursor => $cursor,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/list_folder/continue',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-get_latest_cursor
sub list_folder_get_latest_cursor {
    my ($self, $path, $optional_params) = @_;

    my $params = {
        path => $path,
        %{ $optional_params || {} },
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/list_folder/get_latest_cursor',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-longpoll
sub list_folder_longpoll {
    my ($self, $cursor, $optional_params) = @_;

    my $params = {
        cursor => $cursor,
        %{ $optional_params || {} },
    };

    $self->api({
        url => 'https://notify.dropboxapi.com/2/files/list_folder/longpoll',
        params => $params,
    });
}

1;
