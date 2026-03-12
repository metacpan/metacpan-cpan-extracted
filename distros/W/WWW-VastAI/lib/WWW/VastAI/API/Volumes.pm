package WWW::VastAI::API::Volumes;
our $VERSION = '0.001';
# ABSTRACT: Volume creation and deletion for Vast.ai

use Moo;
use Carp qw(croak);
use WWW::VastAI::Volume;
use namespace::clean;

has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::VastAI::Volume->new(
        client => $self->client,
        data   => $data,
    );
}

sub list {
    my ($self) = @_;
    my $result = $self->client->request_op('listVolumes');
    my $volumes = ref $result eq 'HASH' ? ($result->{volumes} || $result->{results} || []) : ($result || []);
    return [ map { $self->_wrap($_) } @{$volumes} ];
}

sub create {
    my ($self, %params) = @_;
    croak "size required" unless defined $params{size};
    croak "label required" unless defined $params{label};

    my $result = $self->client->request_op('createVolume', body => \%params);
    my $volume = ref $result eq 'HASH' ? ($result->{volume} || $result) : { id => $result };
    return $self->_wrap($volume);
}

sub delete {
    my ($self, $id) = @_;
    croak "volume id required" unless defined $id;
    return $self->client->request_op('deleteVolume', body => { id => $id });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::API::Volumes - Volume creation and deletion for Vast.ai

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Provides access to the Vast.ai volume endpoints and returns
L<WWW::VastAI::Volume> objects.

=head1 METHODS

=head2 list

Returns an arrayref of volume objects.

=head2 create

    my $volume = $vast->volumes->create(
        size  => 10,
        label => 'training-cache',
    );

Creates a volume and returns a wrapped object. If the API only returns a scalar
ID, the returned object contains that ID.

=head2 delete

Deletes a volume by ID.

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
