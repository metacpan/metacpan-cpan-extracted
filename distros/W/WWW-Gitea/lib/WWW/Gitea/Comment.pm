package WWW::Gitea::Comment;

# ABSTRACT: Gitea issue/pull-request comment entity

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


sub id         { $_[0]->data->{id} }
sub body       { $_[0]->data->{body} }
sub html_url   { $_[0]->data->{html_url} }
sub created_at { $_[0]->data->{created_at} }
sub updated_at { $_[0]->data->{updated_at} }
sub user_login { my $u = $_[0]->data->{user}; $u ? $u->{login} : undef }



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::Comment - Gitea issue/pull-request comment entity

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $comments = $gitea->issues->comments('getty', 'p5-www-gitea', 7);

    for my $c (@$comments) {
        print $c->user_login, ": ", $c->body, "\n";
    }

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned for a Gitea comment. The raw
decoded data is always available via L</data>.

=head2 data

Raw decoded JSON for the comment.

=head2 id

Numeric comment ID.

=head2 body

The comment text (Markdown).

=head2 html_url

Web URL of the comment.

=head2 created_at

ISO-8601 creation timestamp.

=head2 updated_at

ISO-8601 last-update timestamp.

=head2 user_login

Login name of the comment's author.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Issue>

=item * L<WWW::Gitea::API::Issues>

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
