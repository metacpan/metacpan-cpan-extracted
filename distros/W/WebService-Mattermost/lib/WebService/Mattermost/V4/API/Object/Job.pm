package WebService::Mattermost::V4::API::Object::Job;

use Moo;
use Types::Standard qw(HashRef Int Maybe Object Str);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::APIMethods
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::CreatedAt
    WebService::Mattermost::V4::API::Object::Role::Status
);

################################################################################

has type             => (is => 'ro', isa => Maybe[Str],     lazy => 1, builder => 1);
has start_at         => (is => 'ro', isa => Maybe[Int],     lazy => 1, builder => 1);
has last_activity_at => (is => 'ro', isa => Maybe[Int],     lazy => 1, builder => 1);
has progress         => (is => 'ro', isa => Maybe[Int],     lazy => 1, builder => 1);
has data             => (is => 'ro', isa => Maybe[HashRef], lazy => 1, builder => 1);
has started_at       => (is => 'ro', isa => Maybe[Object],  lazy => 1, builder => 1);

################################################################################

sub BUILD {
    my $self = shift;

    $self->api_resource_name('job');
    $self->set_available_api_methods([ 'cancel' ]);

    return 1;
}

################################################################################

sub _build_type {
    my $self = shift;

    return $self->raw_data->{type};
}

sub _build_start_at {
    my $self = shift;

    return $self->raw_data->{start_at};
}

sub _build_last_activity_at {
    my $self = shift;

    return $self->raw_data->{last_activity_at};
}

sub _build_progress {
    my $self = shift;

    return $self->raw_data->{progress};
}

sub _build_data {
    my $self = shift;

    return $self->raw_data->{data};
}

sub _build_started_at {
    my $self = shift;

    return $self->_from_epoch($self->start_at);
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Job

=head1 DESCRIPTION

=head2 METHODS

See matching methods in C<WebService::Mattermost::V4::API::Resource::Job>
for full documentation.

ID parameters are not required:

    my $response = $mattermost->api->job->get('ID-HERE')->item->cancel();

Is the same as:

    my $response = $mattermost->api->job->cancel('ID-HERE');

=over 4

=item C<cancel()>

=back

=head2 ATTRIBUTES

=over 4

=item C<type>

=item C<start_at>

=item C<started_at>

DateTime.

=item C<last_activity_at>

=item C<progress>

=item C<data>

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Object::Job>

=item C<WebService::Mattermost::V4::API::Object::Jobs>

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::CreatedAt>

=item C<WebService::Mattermost::V4::API::Object::Role::Status>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

