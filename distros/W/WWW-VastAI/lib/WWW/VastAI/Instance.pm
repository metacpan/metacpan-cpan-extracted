package WWW::VastAI::Instance;
our $VERSION = '0.001';
# ABSTRACT: Instance wrapper with convenience lifecycle helpers

use Moo;
extends 'WWW::VastAI::Object';

sub label         { shift->data->{label} }
sub actual_status { shift->data->{actual_status} }
sub intended_status { shift->data->{intended_status} }
sub ssh_host      { shift->data->{ssh_host} }
sub ssh_port      { shift->data->{ssh_port} }
sub public_ipaddr { shift->data->{public_ipaddr} }
sub gpu_name      { shift->data->{gpu_name} }
sub num_gpus      { shift->data->{num_gpus} }

sub is_running { (shift->actual_status || '') eq 'running' }
sub is_stopped { (shift->actual_status || '') eq 'stopped' }

sub refresh {
    my ($self) = @_;
    return $self->_replace_data($self->_client->instances->get($self->id)->raw);
}

sub update {
    my ($self, %params) = @_;
    return $self->_replace_data($self->_client->instances->update($self->id, %params)->raw);
}

sub start {
    my ($self) = @_;
    $self->_client->instances->start($self->id);
    return $self;
}

sub stop {
    my ($self) = @_;
    $self->_client->instances->stop($self->id);
    return $self;
}

sub set_label {
    my ($self, $label) = @_;
    $self->_client->instances->label($self->id, $label);
    $self->data->{label} = $label;
    return $self;
}

sub logs {
    my ($self, %params) = @_;
    return $self->_client->instances->logs($self->id, %params);
}

sub ssh_keys {
    my ($self) = @_;
    return $self->_client->instances->ssh_keys($self->id);
}

sub attach_ssh_key {
    my ($self, $ssh_key) = @_;
    return $self->_client->instances->attach_ssh_key($self->id, $ssh_key);
}

sub detach_ssh_key {
    my ($self, $ssh_key_id) = @_;
    return $self->_client->instances->detach_ssh_key($self->id, $ssh_key_id);
}

sub delete {
    my ($self) = @_;
    return $self->_client->instances->delete($self->id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::Instance - Instance wrapper with convenience lifecycle helpers

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::Instance> wraps an instance payload and exposes convenience
helpers for lifecycle operations, log access, and per-instance SSH-key
management through L<WWW::VastAI::API::Instances>.

=head1 METHODS

=head2 label

Returns the instance label.

=head2 actual_status

Returns the current status reported by Vast.ai.

=head2 intended_status

Returns the requested target status when present.

=head2 ssh_host

Returns the SSH host for the instance.

=head2 ssh_port

Returns the SSH port for the instance.

=head2 public_ipaddr

Returns the public IP address when assigned.

=head2 gpu_name

Returns the GPU model name.

=head2 num_gpus

Returns the GPU count.

=head2 is_running

True when C<actual_status> is C<running>.

=head2 is_stopped

True when C<actual_status> is C<stopped>.

=head2 refresh

    $instance->refresh;

Reloads the instance payload from the API and updates the object in place.

=head2 update

    $instance->update(%params);

Sends an instance update request and replaces the local payload with the
returned data.

=head2 start

Requests that the instance be started and returns the current object.

=head2 stop

Requests that the instance be stopped and returns the current object.

=head2 set_label

    $instance->set_label('worker-a');

Updates the instance label and mirrors the new label into the local payload.

=head2 logs

    my $logs = $instance->logs(%params);

Fetches instance logs through L<WWW::VastAI::API::Instances>.

=head2 ssh_keys

Returns the attached SSH keys for the instance.

=head2 attach_ssh_key

Attaches a public SSH key to the instance.

=head2 detach_ssh_key

Detaches a previously attached SSH key from the instance.

=head2 delete

Deletes the instance and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Instances>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-vastai/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
