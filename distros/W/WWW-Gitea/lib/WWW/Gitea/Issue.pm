package WWW::Gitea::Issue;

# ABSTRACT: Gitea issue entity

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


sub _owner {
    my ($self) = @_;
    return $self->owner if defined $self->owner;
    my $r = $self->data->{repository};
    return $r ? $r->{owner} : undef;
}

sub _repo {
    my ($self) = @_;
    return $self->repo if defined $self->repo;
    my $r = $self->data->{repository};
    return $r ? $r->{name} : undef;
}

sub id         { $_[0]->data->{id} }
sub number     { $_[0]->data->{number} }
sub title      { $_[0]->data->{title} }
sub body       { $_[0]->data->{body} }
sub state      { $_[0]->data->{state} }
sub html_url   { $_[0]->data->{html_url} }
sub created_at { $_[0]->data->{created_at} }
sub updated_at { $_[0]->data->{updated_at} }
sub comments_count { $_[0]->data->{comments} }
sub user_login { my $u = $_[0]->data->{user}; $u ? $u->{login} : undef }

sub label_names {
    my ($self) = @_;
    return [ map { $_->{name} } @{ $self->data->{labels} || [] } ];
}

sub assignee_logins {
    my ($self) = @_;
    return [ map { $_->{login} } @{ $self->data->{assignees} || [] } ];
}


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->issues->get($self->_owner, $self->_repo, $self->number);
    $self->data($fresh->data);
    return $self;
}


sub edit {
    my ($self, %args) = @_;
    my $fresh = $self->_client->issues->edit(
        $self->_owner, $self->_repo, $self->number, %args);
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


sub add_comment {
    my ($self, $body) = @_;
    return $self->_client->issues->create_comment(
        $self->_owner, $self->_repo, $self->number, $body);
}


sub attachments {
    my ($self, %query) = @_;
    return $self->_client->issues->attachments(
        $self->_owner, $self->_repo, $self->number, %query);
}


sub create_attachment {
    my ($self, %args) = @_;
    return $self->_client->issues->create_attachment(
        $self->_owner, $self->_repo, $self->number, %args);
}


sub get_attachment {
    my ($self, $attachment_id) = @_;
    return $self->_client->issues->get_attachment(
        $self->_owner, $self->_repo, $self->number, $attachment_id);
}


sub edit_attachment {
    my ($self, $attachment_id, %args) = @_;
    return $self->_client->issues->edit_attachment(
        $self->_owner, $self->_repo, $self->number, $attachment_id, %args);
}


sub delete_attachment {
    my ($self, $attachment_id) = @_;
    return $self->_client->issues->delete_attachment(
        $self->_owner, $self->_repo, $self->number, $attachment_id);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::Issue - Gitea issue entity

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $issue = $gitea->issues->get('getty', 'p5-www-gitea', 7);

    print $issue->number, " ", $issue->title, " [", $issue->state, "]\n";

    $issue->add_comment('looking into it');
    $issue->close;

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned for a Gitea issue. Lifecycle
methods (L</edit>, L</close>, L</add_comment>, ...) delegate back to the
client's L<WWW::Gitea::API::Issues> controller. The owning repository is taken
from the explicit L</owner>/L</repo> passed at construction, falling back to
the C<repository> block embedded in the issue JSON. The raw decoded data is
always available via L</data>.

=head2 data

Raw decoded JSON for the issue. Writable so L</refresh> and L</edit> can
update it in place.

=head2 owner

Owner of the repository this issue belongs to. Optional; falls back to the
embedded C<< data->{repository}{owner} >>.

=head2 repo

Name of the repository this issue belongs to. Optional; falls back to the
embedded C<< data->{repository}{name} >>.

=head2 id

Global numeric issue ID.

=head2 number

Per-repository issue index (the number shown in the UI).

=head2 title

Issue title.

=head2 body

Issue body (Markdown).

=head2 state

C<open> or C<closed>.

=head2 html_url

Web URL of the issue.

=head2 created_at

ISO-8601 creation timestamp.

=head2 updated_at

ISO-8601 last-update timestamp.

=head2 comments_count

Number of comments on the issue.

=head2 user_login

Login name of the issue's author.

=head2 label_names

    my $names = $issue->label_names;

Returns an ArrayRef of the issue's label names.

=head2 assignee_logins

    my $logins = $issue->assignee_logins;

Returns an ArrayRef of the assignees' login names.

=head2 refresh

    $issue->refresh;

Re-fetches the issue and updates L</data> in place.

=head2 edit

    $issue->edit(title => 'New title');

Edits the issue and updates L</data> in place.

=head2 close

    $issue->close;

Closes the issue (shortcut for C<< $issue->edit(state => 'closed') >>).

=head2 reopen

    $issue->reopen;

Reopens the issue (shortcut for C<< $issue->edit(state => 'open') >>).

=head2 add_comment

    my $comment = $issue->add_comment('thanks for the report');

Adds a comment to the issue. Returns the new L<WWW::Gitea::Comment>.

=head2 attachments

    my $attachments = $issue->attachments;

Lists the issue's attachments. Returns an ArrayRef of
L<WWW::Gitea::Attachment>.

=head2 create_attachment

    my $a = $issue->create_attachment(file => '/path/to/log.txt');

Uploads an attachment to the issue (see
L<WWW::Gitea::API::Issues/create_attachment>). Returns a
L<WWW::Gitea::Attachment>.

=head2 get_attachment

    my $a = $issue->get_attachment(12);

Fetches one of the issue's attachments by attachment id. Returns a
L<WWW::Gitea::Attachment>.

=head2 edit_attachment

    $issue->edit_attachment(12, name => 'renamed.txt');

Edits one of the issue's attachments. Returns the updated
L<WWW::Gitea::Attachment>.

=head2 delete_attachment

    $issue->delete_attachment(12);

Deletes one of the issue's attachments by attachment id.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::API::Issues>

=item * L<WWW::Gitea::Comment>

=item * L<WWW::Gitea::Attachment>

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
