package WebService::Mattermost::V4::API::Resource::S3;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

sub test {
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

WebService::Mattermost::V4::API::Resource::S3

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->s3;

=head2 METHODS

=over 4

=item C<send_test()>

L<Test AWS S3 connection|https://api.mattermost.com/#tag/system%2Fpaths%2F~1file~1s3_test%2Fpost>

There are many available parameters for this API call which may require reading
of the API documentation.

Providing no parameters will use the ones set on your Mattermost server.

    my $response = $resource->test({
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

