package WebService::Dropbox::Files;
use strict;
use warnings;
use parent qw(Exporter);

our @EXPORT = do {
    no strict 'refs';
    grep { $_ =~ qr{ \A [a-z] }xms } keys %{ __PACKAGE__ . '::' };
};

# https://www.dropbox.com/developers/documentation/http/documentation#files-copy
sub copy {
    my ($self, $from_path, $to_path) = @_;

    my $params = {
        from_path => $from_path,
        to_path => $to_path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/copy',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-create_folder
sub create_folder {
    my ($self, $path) = @_;

    my $params = {
        path => $path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/create_folder',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-delete
sub delete {
    my ($self, $path) = @_;

    my $params = {
        path => $path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/delete',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-download
sub download {
    my ($self, $path, $output, $opts) = @_;

    $self->api({
        url => 'https://content.dropboxapi.com/2/files/download',
        params => { path => $path },
        output => $output,
        %{ $opts || +{} },
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-get_metadata
sub get_metadata {
    my ($self, $path, $optional_params) = @_;

    my $params = {
        path => $path,
        %{ $optional_params || {} },
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/get_metadata',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-get_preview
sub get_preview {
    my ($self, $path, $output, $opts) = @_;

    my $params = {
        path => $path,
    };

    $self->api({
        url => 'https://content.dropboxapi.com/2/files/get_preview',
        params => $params,
        output => $output,
        %{ $opts || +{} },
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-get_temporary_link
sub get_temporary_link {
    my ($self, $path) = @_;

    my $params = {
        path => $path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/get_temporary_link',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-get_thumbnail
sub get_thumbnail {
    my ($self, $path, $output, $optional_params, $opts) = @_;

    my $params = {
        path => $path,
        %{ $optional_params || {} },
    };

    $self->api({
        url => 'https://content.dropboxapi.com/2/files/get_thumbnail',
        params => $params,
        output => $output,
        %{ $opts || +{} },
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-list_revisions
sub list_revisions {
    my ($self, $path, $optional_params) = @_;

    my $params = {
        path => $path,
        %{ $optional_params || {} },
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/list_revisions',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-move
sub move {
    my ($self, $from_path, $to_path) = @_;

    my $params = {
        from_path => $from_path,
        to_path => $to_path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/move',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-permanently_delete
sub permanently_delete {
    my ($self, $path) = @_;

    my $params = {
        path => $path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/permanently_delete',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-restore
sub restore {
    my ($self, $path, $rev) = @_;

    my $params = {
        path => $path,
        rev => $rev,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/restore',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-save_url
sub save_url {
    my ($self, $path, $url) = @_;

    my $params = {
        path => $path,
        url => $url,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/save_url',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-save_url-check_job_status
sub save_url_check_job_status {
    my ($self, $async_job_id) = @_;

    my $params = {
        async_job_id => $async_job_id,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/save_url/check_job_status',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-search
sub search {
    my ($self, $path, $query, $optional_params) = @_;

    my $params = {
        path => $path,
        query => $query,
        %{ $optional_params || {} },
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/search',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-upload
sub upload {
    my ($self, $path, $content, $optional_params) = @_;

    my $params = {
        path => $path,
        %{ $optional_params || {} },
    };

    $self->api({
        url => 'https://content.dropboxapi.com/2/files/upload',
        params => $params,
        content => $content,
    });
}

1;
