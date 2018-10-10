package WebService::Mattermost::V4::API::Resource::Roles;

use Moo;

extends 'WebService::Mattermost::V4::API::Resource';

################################################################################

around [ qw(get_by_id get_by_name update_by_id) ] => sub {
    my $orig = shift;
    my $self = shift;
    my $id   = shift;

    return $self->validate_id($orig, $id, @_);
};

sub get_by_id {
    my $self = shift;
    my $id   = shift;

    return $self->_get({
        endpoint => '%s',
        ids      => [ $id ],
    });
}

sub get_by_name {
    my $self = shift;
    my $name = shift;

    return $self->_get({
        endpoint => 'name/%s',
        ids      => [ $name ],
    });
}

sub update_by_id {
    my $self = shift;
    my $id   = shift;
    my $args = shift;

    return $self->_patch({
        endpoint   => '%s/patch',
        parameters => $args,
    });
}

sub get_by_names {
    my $self  = shift;
    my $names = shift;

    unless (ref $names eq 'ARRAY' && scalar @{$names}) {
        return $self->_error_return('The first argument must be an ArrayRef of names');
    }

    return $self->_post({
        endpoint   => 'names',
        parameters => $names,
    });
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Resource::Roles

=head1 DESCRIPTION

=head2 USAGE

    use WebService::Mattermost;

    my $mm = WebService::Mattermost->new({
        authenticate => 1,
        username     => 'me@somewhere.com',
        password     => 'hunter2',
        base_url     => 'https://my.mattermost.server.com/api/v4/',
    });

    my $resource = $mm->api->roles;

=head2 METHODS

=over 4

=item C<get_by_id()>

L<Get a role|https://api.mattermost.com/#tag/roles%2Fpaths%2F~1roles~1%7Brole_id%7D%2Fget>

    my $response = $resource->get_by_id('ID-HERE');

=item C<get_by_name()>

L<Get a role|https://api.mattermost.com/#tag/roles%2Fpaths%2F~1roles~1name~1%7Brole_name%7D%2Fget>

    my $response = $resource->get_by_name('NAME-HERE');

=item C<update_by_id()>

L<Patch a role|https://api.mattermost.com/#tag/roles%2Fpaths%2F~1roles~1%7Brole_id%7D~1patch%2Fput>

    my $response = $resource->update_by_id('ID-HERE', {
        permissions => [ qw(
            PERMISSION-HERE
            ANOTHER-PERMISSION-HERE
        ) ],
    });

=item C<get_by_names()>

L<Get a list of roles by name|https://api.mattermost.com/#tag/roles%2Fpaths%2F~1roles~1names%2Fpost>

    my $response = $resource->get_by_names([ qw(NAME-1-HERE NAME-2-HERE) ]);

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

