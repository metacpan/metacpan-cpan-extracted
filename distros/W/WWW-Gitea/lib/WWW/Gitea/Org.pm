package WWW::Gitea::Org;

# ABSTRACT: Gitea organization entity

use Moo;
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => (
    is       => 'rw',
    required => 1,
);


sub id          { $_[0]->data->{id} }
sub name        { $_[0]->data->{name} // $_[0]->data->{username} }
sub full_name   { $_[0]->data->{full_name} }
sub description { $_[0]->data->{description} }
sub avatar_url  { $_[0]->data->{avatar_url} }
sub website     { $_[0]->data->{website} }
sub location    { $_[0]->data->{location} }
sub visibility  { $_[0]->data->{visibility} }


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->orgs->get($self->name);
    $self->data($fresh->data);
    return $self;
}


sub repos {
    my ($self, %query) = @_;
    return $self->_client->orgs->repos($self->name, %query);
}


sub delete {
    my ($self) = @_;
    return $self->_client->orgs->delete($self->name);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::Org - Gitea organization entity

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $org = $gitea->orgs->get('perl-modules');

    print $org->name, " — ", $org->full_name, "\n";
    my $repos = $org->repos;

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned for a Gitea organization.
Convenience methods delegate back to the client's L<WWW::Gitea::API::Orgs>
controller. The raw decoded data is always available via L</data>.

=head2 data

Raw decoded JSON for the organization. Writable so L</refresh> can update it
in place.

=head2 id

Numeric organization ID.

=head2 name

Organization name (the C<name>/C<username> field).

=head2 full_name

Organization display name.

=head2 description

Organization description.

=head2 avatar_url

URL of the organization's avatar image.

=head2 website

Organization website URL.

=head2 location

Organization location.

=head2 visibility

C<public>, C<limited> or C<private>.

=head2 refresh

    $org->refresh;

Re-fetches the organization and updates L</data> in place.

=head2 repos

    my $repos = $org->repos;

Lists the organization's repositories. Delegates to
L<WWW::Gitea::API::Orgs/repos>. Returns an ArrayRef of L<WWW::Gitea::Repo>.

=head2 delete

    $org->delete;

Deletes the organization.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::API::Orgs>

=item * L<WWW::Gitea::Repo>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://codeberg.org/getty/p5-www-gitea/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
