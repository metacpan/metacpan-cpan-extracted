package WebService::Mattermost::V4::API::Resource::Email;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub send_test {
    my $self = shift;
    my $args = shift;

    return $self->_single_view_post({
        endpoint => 'test',
        view     => 'Status',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Email

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->email;

=head2 METHODS

=over 4

=item C<send_test()>

L<Send a test email|https://api.mattermost.com/#tag/system%2Fpaths%2F~1database~1recycle%2Fpost>

There are many available parameters for this API call which may require reading
of the API documentation.

Providing no parameters will use the ones set on your Mattermost server.

    my $response = $resource->send_test({
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

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

