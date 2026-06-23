package WWW::Gitea::User;

# ABSTRACT: Gitea user entity

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


sub id        { $_[0]->data->{id} }
sub login     { $_[0]->data->{login} }
sub full_name { $_[0]->data->{full_name} }
sub email     { $_[0]->data->{email} }
sub avatar_url { $_[0]->data->{avatar_url} }
sub is_admin  { $_[0]->data->{is_admin} }


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->users->get($self->login);
    $self->data($fresh->data);
    return $self;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::User - Gitea user entity

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $user = $gitea->users->get('getty');

    print $user->login,     "\n";
    print $user->full_name, "\n";
    print $user->email,     "\n";

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned for a Gitea user. The raw decoded
data is always available via L</data>.

=head2 data

Raw decoded JSON for the user. Writable so L</refresh> can update it in place.

=head2 id

Numeric user ID.

=head2 login

The user's login name.

=head2 full_name

The user's display name.

=head2 email

The user's email address (when visible).

=head2 avatar_url

URL of the user's avatar image.

=head2 is_admin

True if the user is a site administrator.

=head2 refresh

    $user->refresh;

Re-fetches the user from Gitea and updates L</data> in place.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::API::Users>

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
