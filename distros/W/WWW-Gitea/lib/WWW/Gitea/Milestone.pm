package WWW::Gitea::Milestone;

# ABSTRACT: Gitea milestone entity

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


sub id            { $_[0]->data->{id} }
sub title         { $_[0]->data->{title} }
sub description   { $_[0]->data->{description} }
sub state         { $_[0]->data->{state} }
sub due_on        { $_[0]->data->{due_on} }
sub open_issues   { $_[0]->data->{open_issues} }
sub closed_issues { $_[0]->data->{closed_issues} }


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->milestones->get($self->owner, $self->repo, $self->id);
    $self->data($fresh->data);
    return $self;
}


sub edit {
    my ($self, %args) = @_;
    my $fresh = $self->_client->milestones->edit(
        $self->owner, $self->repo, $self->id, %args);
    $self->data($fresh->data);
    return $self;
}


sub close {
    my ($self) = @_;
    return $self->edit(state => 'closed');
}


sub reopen {
    my ($self) = @_;
    return $self->edit(state => 'open');
}


sub delete {
    my ($self) = @_;
    return $self->_client->milestones->delete($self->owner, $self->repo, $self->id);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::Milestone - Gitea milestone entity

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $ms = $gitea->milestones->get('getty', 'p5-www-gitea', 1);

    print $ms->title, " [", $ms->state, "]\n";
    $ms->close;

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned for a Gitea milestone. Lifecycle
methods delegate back to the client's L<WWW::Gitea::API::Milestones>
controller and need the owning L</owner>/L</repo> (set automatically when the
milestone comes from a repository-scoped call). The raw decoded data is always
available via L</data>.

=head2 data

Raw decoded JSON for the milestone.

=head2 owner

Owner of the repository this milestone belongs to.

=head2 repo

Name of the repository this milestone belongs to.

=head2 id

Numeric milestone ID.

=head2 title

Milestone title.

=head2 description

Milestone description.

=head2 state

C<open> or C<closed>.

=head2 due_on

ISO-8601 due date (or C<undef>).

=head2 open_issues

Number of open issues in the milestone.

=head2 closed_issues

Number of closed issues in the milestone.

=head2 refresh

    $ms->refresh;

Re-fetches the milestone and updates L</data> in place.

=head2 edit

    $ms->edit(description => '...');

Edits the milestone and updates L</data> in place.

=head2 close

    $ms->close;

Closes the milestone (shortcut for C<< $ms->edit(state => 'closed') >>).

=head2 reopen

    $ms->reopen;

Reopens the milestone (shortcut for C<< $ms->edit(state => 'open') >>).

=head2 delete

    $ms->delete;

Deletes the milestone.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::API::Milestones>

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
