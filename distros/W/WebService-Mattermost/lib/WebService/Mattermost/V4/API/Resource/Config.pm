package WebService::Mattermost::V4::API::Resource::Config;

use Moo;
use Types::Standard 'Str';

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

has view_name => (is => 'ro', isa => Str, default => 'Config');

################################################################################

sub get {
    my $self = shift;

    return $self->_single_view_get();
}

sub update {
    my $self = shift;
    my $args = shift;

    return $self->_single_view_put({ parameters => $args });
}

sub reload {
    my $self = shift;

    return $self->_single_view_post({
        endpoint => 'reload',
        view     => 'Status',
    });
}

sub client_subset {
    my $self = shift;
    my $args = shift;

    return $self->_get({
        endpoint   => 'client',
        parameters => $args,
        required   => [ 'format' ],
    });
}

sub set_by_environment {
    my $self = shift;

    return $self->_single_view_get({ endpoint => 'environment' });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Config

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->config;

=head2 METHODS

=over 4

=item C<get()>

L<Get configuration|https://api.mattermost.com/#tag/system%2Fpaths%2F~1file~1s3_test%2Fpost>

    my $response = $resource->get();

=item C<update()>

L<Update configuration|https://api.mattermost.com/#tag/system%2Fpaths%2F~1config%2Fput>

There are many available parameters for this API call which may require reading
of the API documentation.

    my $response = $resource->update({
        # Optional parameters:
        ServiceSettings      => {},
        TeamSettings         => {},
        SqlSettings          => {},
        LogSettings          => {},
        PasswordSettings     => {},
        FileSettings         => {},
        EmailSettings        => {},
        RateLimitSettings    => {},
        PrivacySettings      => {},
        SupportSettings      => {},
        GitLabSettings       => {},
        GoogleSettings       => {},
        Office365Settings    => {},
        LdapSettings         => {},
        ComplianceSettings   => {},
        LocalizationSettings => {},
        SamlSettings         => {},
        NativeAppSettings    => {},
        ClusterSettings      => {},
        MetricsSettings      => {},
        AnalyticsSettings    => {},
        WebrtcSettings       => {},
    });

=item C<reload()>

L<Reload configuration|https://api.mattermost.com/#tag/system%2Fpaths%2F~1config~1reload%2Fpost>

    my $response = $resource->reload();

=item C<client_subset()>

L<Get client configuration|https://api.mattermost.com/#tag/system%2Fpaths%2F~1config~1reload%2Fpost>

    my $response = $resource->client_subset();

=item C<set_by_environment()>

L<Get configuration made through environment variables|https://api.mattermost.com/#tag/system%2Fpaths%2F~1config~1environment%2Fget>

    my $response = $client->set_by_environment();

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

