package WebService::Mattermost::V4::API::Resource::Plugin;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';
with    qw(
    WebService::Mattermost::V4::API::Resource::Role::Single
);

################################################################################

around [ qw(activate deactivate remove) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift || $self->id;

    return $self->validate_id($orig, $id, @_);
};

sub remove {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_delete({
        endpoint => '%s',
        ids      => [ $id ],
        view     => 'Status',
    });
}

sub activate {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_post({
        endpoint => '%s/activate',
        ids      => [ $id ],
        view     => 'Status',
    });
}

sub deactivate {
    my $self = shift;
    my $id   = shift;

    return $self->_single_view_post({
        endpoint => '%s/deactivate',
        ids      => [ $id ],
        view     => 'Status',
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Plugin

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->plugin;

Optionally, you can set a global plugin ID and not pass that argument to every
method:

    $resource->id('PLUGIN-ID-HERE');

This would make the C<deactivate()> call look like:

    my $response = $resource->deactivate();

=head2 METHODS

=over 4

=item C<remove()>

L<Remove plugin|https://api.mattermost.com/#tag/plugins%2Fpaths%2F~1plugins~1%7Bplugin_id%7D%2Fdelete>

    my $response = $resource->remove('PLUGIN-ID-HERE');

=item C<activate()>

L<Activate plugin|https://api.mattermost.com/#tag/plugins%2Fpaths%2F~1plugins~1%7Bplugin_id%7D~1activate%2Fpost>

    my $response = $resource->activate('PLUGIN-ID-HERE');

=item C<deactivate()>

L<Deactivate plugin|https://api.mattermost.com/#tag/plugins%2Fpaths%2F~1plugins~1%7Bplugin_id%7D~1deactivate%2Fpost>

    my $response = $resource->deactivate('PLUGIN-ID-HERE');

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

