package WWW::VastAI::Endpoint;
our $VERSION = '0.001';
# ABSTRACT: Serverless endpoint wrapper with worker and log helpers

use Moo;
extends 'WWW::VastAI::Object';

sub endpoint_name  { shift->data->{endpoint_name} }
sub endpoint_state { shift->data->{endpoint_state} }
sub api_key        { shift->data->{api_key} }

sub workers {
    my ($self) = @_;
    return $self->_client->endpoints->workers($self->id);
}

sub logs {
    my ($self, %params) = @_;
    return $self->_client->endpoints->logs($self->endpoint_name, %params);
}

sub delete {
    my ($self) = @_;
    return $self->_client->endpoints->delete($self->id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::Endpoint - Serverless endpoint wrapper with worker and log helpers

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::Endpoint> wraps a serverless endpoint returned by
L<WWW::VastAI::API::Endpoints>.

=head1 METHODS

=head2 endpoint_name

Returns the endpoint name used by the serverless API.

=head2 endpoint_state

Returns the current endpoint state string.

=head2 api_key

Returns the API key associated with the endpoint when present.

=head2 workers

    my $workers = $endpoint->workers;

Fetches worker information for the endpoint.

=head2 logs

    my $logs = $endpoint->logs(%params);

Fetches endpoint logs using the endpoint name.

=head2 delete

Deletes the endpoint and returns the raw API response.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::API::Endpoints>, L<WWW::VastAI::Workergroup>

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
