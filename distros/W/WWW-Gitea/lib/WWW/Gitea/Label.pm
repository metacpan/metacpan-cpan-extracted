package WWW::Gitea::Label;

# ABSTRACT: Gitea label entity

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


has owner => ( is => 'ro' );
has repo  => ( is => 'ro' );


sub id          { $_[0]->data->{id} }
sub name        { $_[0]->data->{name} }
sub color       { $_[0]->data->{color} }
sub description { $_[0]->data->{description} }
sub url         { $_[0]->data->{url} }


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->labels->get($self->owner, $self->repo, $self->id);
    $self->data($fresh->data);
    return $self;
}


sub edit {
    my ($self, %args) = @_;
    my $fresh = $self->_client->labels->edit(
        $self->owner, $self->repo, $self->id, %args);
    $self->data($fresh->data);
    return $self;
}


sub delete {
    my ($self) = @_;
    return $self->_client->labels->delete($self->owner, $self->repo, $self->id);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::Label - Gitea label entity

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $label = $gitea->labels->get('getty', 'p5-www-gitea', 3);

    print $label->name, " #", $label->color, "\n";
    $label->edit(color => '00ff00');

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned for a Gitea label. Lifecycle
methods delegate back to the client's L<WWW::Gitea::API::Labels> controller
and therefore need the owning L</owner>/L</repo> (set automatically when the
label comes from a repository-scoped call). The raw decoded data is always
available via L</data>.

=head2 data

Raw decoded JSON for the label.

=head2 owner

Owner of the repository this label belongs to.

=head2 repo

Name of the repository this label belongs to.

=head2 id

Numeric label ID.

=head2 name

Label name.

=head2 color

6-hex-digit RGB color string.

=head2 description

Label description.

=head2 url

API URL of the label.

=head2 refresh

    $label->refresh;

Re-fetches the label and updates L</data> in place.

=head2 edit

    $label->edit(color => '00ff00');

Edits the label and updates L</data> in place.

=head2 delete

    $label->delete;

Deletes the label.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::API::Labels>

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
