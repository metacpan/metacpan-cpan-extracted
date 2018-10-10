package WebService::Mattermost::V4::API::Object::Compliance::Report;

use Moo;
use Types::Standard qw(Str InstanceOf Int Maybe);

extends 'WebService::Mattermost::V4::API::Object';
with    qw(
    WebService::Mattermost::V4::API::Object::Role::APIMethods
    WebService::Mattermost::V4::API::Object::Role::ID
    WebService::Mattermost::V4::API::Object::Role::Status
    WebService::Mattermost::V4::API::Object::Role::CreatedAt
    WebService::Mattermost::V4::API::Object::Role::BelongingToUser
);

################################################################################

has [ qw(count start_at end_at) ]     => (is => 'ro', isa => Maybe[Int], lazy => 1, builder => 1);
has [ qw(desc type keywords emails) ] => (is => 'ro', isa => Maybe[Str], lazy => 1, builder => 1);

has [ qw(
    started_at
    ended_at
) ] => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

################################################################################

sub BUILD {
    my $self = shift;

    $self->api_resource_name('compliance_report');
    $self->available_api_methods([ 'download' ]);

    return 1;
}

################################################################################

sub _build_count {
    my $self = shift;

    return $self->raw_data->{count};
}

sub _build_start_at {
    my $self = shift;

    return $self->raw_data->{start_at};
}

sub _build_end_at {
    my $self = shift;

    return $self->raw_data->{end_at};
}

sub _build_desc {
    my $self = shift;

    return $self->raw_data->{desc};
}

sub _build_type {
    my $self = shift;

    return $self->raw_data->{type};
}

sub _build_keywords {
    my $self = shift;

    return $self->raw_data->{keywords};
}

sub _build_emails {
    my $self = shift;

    return $self->raw_data->{emails};
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Compliance::Report

=head1 DESCRIPTION

See matching methods in C<WebService::Mattermost::V4::API::Resource::Compliance::Report>
for full documentation.

ID parameters are not required:

    my $response = $mattermost->api->compliance_report->get('ID-HERE')->item->download();

Is the same as: 

    my $response = $mattermost->api->compliance_report->download('ID-HERE');

=head2 ATTRIBUTES

=over 4

=item C<count>

=item C<start_at>

=item C<end_at>

=item C<desc>

=item C<type>

=item C<keywords>

=item C<emails>

=item C<started_at>

=item C<ended_at>

=back

=head1 SEE ALSO

=over 4

=item C<WebService::Mattermost::V4::API::Resource::Compliance::Report>

=item C<WebService::Mattermost::V4::API::Object::Role::ID>

=item C<WebService::Mattermost::V4::API::Object::Role::Status>

=item C<WebService::Mattermost::V4::API::Object::Role::CreatedAt>

=item C<WebService::Mattermost::V4::API::Object::Role::BelongingToUser>

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

