package WebService::Mattermost::V4::API::Resource::SAML;

use Moo;
use Types::Standard 'InstanceOf';

use WebService::Mattermost::V4::API::Resource::SAML::Certificate;
use WebService::Mattermost::Helper::Alias 'v4';

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

has certificate => (is => 'ro', isa => InstanceOf[v4 'SAML::Certificate'], lazy => 1, builder => 1);

################################################################################

sub metadata {
    my $self = shift;

    return $self->_get({ endpoint => 'metadata' });
}

################################################################################

sub _build_certificate {
    my $self = shift;

    return $self->_new_related_resource('saml', 'SAML::Certificate');
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::SAML

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->saml;

=head2 METHODS

=over 4

=item C<metadata()>

Get SAML metadata from the server.

=back

=head2 ATTRIBUTES

=over 4

=item C<certificate>

An instance of C<WebService::Mattermost::V4::API::Resource::SAML::Certificate>,
which handles getting and setting of certificates (IDP, public and private).

=back

=head1 SEE ALSO

=over 4

=item L<Official SAML documentation|https://api.mattermost.com/#tag/SAML>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

