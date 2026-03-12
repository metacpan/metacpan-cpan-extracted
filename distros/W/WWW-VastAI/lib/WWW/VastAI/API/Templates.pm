package WWW::VastAI::API::Templates;
our $VERSION = '0.001';
# ABSTRACT: Template listing and management for Vast.ai

use Moo;
use Carp qw(croak);
use WWW::VastAI::Template;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Template->new(
        client => $self->client,
        data   => $data,
    );
}

sub list {
    my ($self, %query) = @_;
    my $result = $self->client->request_op('searchTemplates', query => \%query);
    my $templates = ref $result eq 'HASH' ? ($result->{templates} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$templates} ];
}

sub create {
    my ($self, %params) = @_;
    croak "name required"  unless $params{name};
    croak "image required" unless $params{image};

    my $result = $self->client->request_op('createTemplate', body => \%params);
    my $template = ref $result eq 'HASH' ? ($result->{template} || $result) : $result;
    return $self->_wrap($template);
}

sub update {
    my ($self, $hash_id, %params) = @_;
    croak "hash_id required" unless $hash_id;
    $params{hash_id} = $hash_id;

    my $result = $self->client->request_op('updateTemplate', body => \%params);
    my $template = ref $result eq 'HASH' ? ($result->{template} || $result) : $result;
    return $self->_wrap($template);
}

sub delete {
    my ($self, $id) = @_;
    croak "template id required" unless defined $id;
    return $self->client->request_op('deleteTemplate', body => { id => $id });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::API::Templates - Template listing and management for Vast.ai

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Wraps the Vast.ai template APIs and returns L<WWW::VastAI::Template> objects.

=head1 METHODS

=head2 list

    my $templates = $vast->templates->list(%query);

Lists templates. Structured filter arguments are JSON-encoded into the query
string by the shared HTTP layer.

=head2 create

Creates a new template and returns it as a L<WWW::VastAI::Template> object.

=head2 update

Updates an existing template identified by C<$hash_id>.

=head2 delete

Deletes the template identified by C<$id>.

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
