package WWW::VastAI::Workergroup;
our $VERSION = '0.001';
# ABSTRACT: Serverless workergroup wrapper with management helpers

use Moo;
extends 'WWW::VastAI::Object';

sub endpoint_name { shift->data->{endpoint_name} }
sub endpoint_id   { shift->data->{endpoint_id} }
sub template_hash { shift->data->{template_hash} }
sub api_key       { shift->data->{api_key} }

sub workers {
    my ($self) = @_;
    return $self->_client->workergroups->workers($self->id);
}

sub logs {
    my ($self, %params) = @_;
    return $self->_client->workergroups->logs($self->id, %params);
}

sub update {
    my ($self, %params) = @_;
    return $self->_replace_data($self->_client->workergroups->update($self->id, %params)->raw);
}

sub delete {
    my ($self) = @_;
    return $self->_client->workergroups->delete($self->id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::Workergroup - Serverless workergroup wrapper with management helpers

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::Workergroup> wraps a serverless workergroup managed through
L<WWW::VastAI::API::Workergroups>.

=head1 METHODS

=head2 endpoint_name

Returns the endpoint name this workergroup belongs to.

=head2 endpoint_id

Returns the endpoint identifier when present.

=head2 template_hash

Returns the template hash used by the workergroup.

=head2 api_key

Returns the API key associated with the workergroup when present.

=head2 workers

Returns worker information for the workergroup.

=head2 logs

Returns workergroup logs.

=head2 update

    $group->update(%params);

Updates the workergroup and refreshes the local payload.

=head2 delete

Deletes the workergroup and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Workergroups>, L<WWW::VastAI::Endpoint>

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
