package WebService::Mattermost::V4::API::Object::DataRetentionPolicy;

use Moo;
use Types::Standard qw(Bool Maybe InstanceOf Int);

extends 'WebService::Mattermost::V4::API::Object';

################################################################################

has [ qw(
    message_deletion_enabled 
    file_deletion_enabled
) ] => (is => 'ro', isa => Maybe[Bool], lazy => 1, builder => 1);

has [ qw(
    message_retention_cutoff
    file_retention_cutoff
) ] => (is => 'ro', isa => Maybe[Int], lazy => 1, builder => 1);

has [ qw(
    files_kept_until
    messages_kept_until
) ] => (is => 'ro', isa => Maybe[InstanceOf['DateTime']], lazy => 1, builder => 1);

################################################################################

sub _build_message_deletion_enabled { shift->raw_data->{message_deletion_enabled} }
sub _build_file_deletion_enabled    { shift->raw_data->{file_deletion_enabled}    }
sub _build_message_retention_cutoff { shift->raw_data->{message_retention_cutoff} }
sub _build_file_retention_cutoff    { shift->raw_data->{file_retention_cutoff}    }

sub _build_files_kept_until {
    my $self = shift;

    return unless $self->file_retention_cutoff;
    return $self->_from_epoch($self->file_retention_cutoff);
}

sub _build_messages_kept_until {
    my $self = shift;

    return unless $self->message_retention_cutoff;
    return $self->_from_epoch($self->message_retention_cutoff);
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::DataRetentionPolicy

=head1 DESCRIPTION

A data retention policy.

=head2 ATTRIBUTES

=over 4

=item C<message_deletion_enabled>

=item C<file_deletion_enabled>

=item C<message_retention_cutoff>

UNIX timestamp.

=item C<file_retention_cutoff>

UNIX timestamp.

=item C<messages_kept_until>

DateTime.

=item C<files_kept_until>

DateTime.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

