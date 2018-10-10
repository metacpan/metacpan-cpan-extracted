package WebService::Mattermost::V4::API::Resource::SAML::Certificate;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub status {
    my $self = shift;

    return $self->_get({ endpoint => 'status' });
}

sub idp_upload {
    my $self     = shift;
    my $filename = shift;

    # TODO: wrapping helper for filenames (here and Resource::Users)

    return $self->_post({
        endpoint           => 'idp',
        override_data_type => 'form',
        parameters         => {
            certificate => { file => $filename },
        },
    });
}

sub idp_remove {
    my $self = shift;

    return $self->_delete({ endpoint => 'idp' });
}

sub public_upload {
    my $self     = shift;
    my $filename = shift;

    # TODO: wrapping helper for filenames (here and Resource::Users)

    return $self->_post({
        endpoint           => 'public',
        override_data_type => 'form',
        parameters         => {
            certificate => { file => $filename },
        },
    });
}

sub public_remove {
    my $self = shift;

    return $self->_delete({ endpoint => 'public' });
}

sub private_upload {
    my $self     = shift;
    my $filename = shift;

    # TODO: wrapping helper for filenames (here and Resource::Users)

    return $self->_post({
        endpoint           => 'private',
        override_data_type => 'form',
        parameters         => {
            certificate => { file => $filename },
        },
    });
}

sub private_remove {
    my $self = shift;

    return $self->_delete({ endpoint => 'private' });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::SAML::Certificate

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->saml->certificate;

=head2 METHODS

=over 4

=item C<idp_upload()>

Upload an IDP key.

    $resource->idp_upload('/path/to/idp.key');

=item C<idp_remove()>

Remove your associated IDP key.

    $resource->idp_remove();

=item C<public_upload()>

Upload a public key.

    $resource->public_upload('/path/to/public.key');

=item C<public_remove()>

Remove your associated public key.

    $resource->public_remove();

=item C<private_upload()>

Upload a private key.

    $resource->private_upload('/path/to/private.key');

=item C<private_remove()>

Remove your associated private key.

    $resource->private_remove();

=back

=head1 SEE ALSO

=over 4

=item L<Official SAML documentation|https://api.mattermost.com/#tag/SAML>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

