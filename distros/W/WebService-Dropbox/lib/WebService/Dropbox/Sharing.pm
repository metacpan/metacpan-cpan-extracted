package WebService::Dropbox::Sharing;
use strict;
use warnings;
use parent qw(Exporter);

## preliminary version with support for creating and managing links
## to shared files. more to follow...

our @EXPORT = do {
    no strict 'refs';
    grep { $_ =~ qr{ \A [a-z] }xms } keys %{ __PACKAGE__ . '::' };
};

# https://www.dropbox.com/developers/documentation/http/documentation#sharing-create_shared_link_with_settings
sub create_shared_link_with_settings {
    my ($self, $path, $settings) = @_;

    my $params = {
        path     => $path,
        settings => $settings,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#sharing-list_shared_links
sub list_shared_links {
    my ($self, $path) = @_;

    my $params = {
        path     => $path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/sharing/list_shared_links',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#sharing-modify_shared_link_settings
sub modify_shared_link_settings {
    my ($self, $path, $settings, $remove_expiration) = @_;

    # this assumes the api converts 1 and 0 to JSON::true and JSON::false accordingly
	if ($remove_expiration) {
		$remove_expiration = 1;
	} else {
		$remove_expiration = 0;
	}

    my $params = {
        path     => $path,
        settings => $settings,
        remove_expiration => $remove_expiration,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/sharing/modify_shared_link_settings',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#sharing-revoke_shared_link
sub revoke_shared_link {
    my ($self, $url) = @_;

    my $params = {
        url      => $url,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/sharing/revoke_shared_link',
        params => $params,
    });
}

1;
