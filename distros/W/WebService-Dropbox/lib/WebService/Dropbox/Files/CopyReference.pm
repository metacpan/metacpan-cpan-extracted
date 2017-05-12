package WebService::Dropbox::Files::CopyReference;
use strict;
use warnings;
use parent qw(Exporter);

our @EXPORT = do {
    no strict 'refs';
    grep { $_ !~ qr{ \A [A-Z]+ \z }xms } keys %{ __PACKAGE__ . '::' };
};

# https://www.dropbox.com/developers/documentation/http/documentation#files-copy_reference-get
sub copy_reference_get {
    my ($self, $path) = @_;

    my $params = {
        path => $path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/copy_reference/get',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-copy_reference-save
sub copy_reference_save {
    my ($self, $copy_reference, $path) = @_;

    my $params = {
        copy_reference => $copy_reference,
        path => $path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/copy_reference/save',
        params => $params,
    });
}

1;
