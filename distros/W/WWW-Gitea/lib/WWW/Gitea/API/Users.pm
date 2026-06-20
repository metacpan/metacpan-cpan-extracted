package WWW::Gitea::API::Users;

# ABSTRACT: Gitea users API (lookup and search)

use Moo;
use Carp qw(croak);
use WWW::Gitea::User;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);


has openapi_operations => (
    is      => 'lazy',
    builder => sub {
        return {
            'users.get'    => { method => 'GET', path => '/users/{username}' },
            'users.search' => { method => 'GET', path => '/users/search' },
        };
    },
);


with 'WWW::Gitea::Role::OpenAPI';

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Gitea::User->new(client => $self->client, data => $data);
}

sub get {
    my ($self, $username) = @_;
    croak 'username required' unless defined $username;
    my $data = $self->call_operation('users.get',
        path => { username => $username });
    return $self->_wrap($data);
}


sub search {
    my ($self, %query) = @_;
    my $data = $self->call_operation('users.search', query => \%query);
    return [ map { $self->_wrap($_) } @{ $data->{data} || [] } ];
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::API::Users - Gitea users API (lookup and search)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $user  = $gitea->users->get('getty');
    my @found = @{ $gitea->users->search(q => 'tor') };

=head1 DESCRIPTION

Controller for the Gitea users API. Reached via C<< $gitea->users >>.

=head2 client

The parent L<WWW::Gitea> client providing HTTP transport.

=head2 openapi_operations

Pre-computed operation table (C<operationId> → C<{method, path}>).

=head2 get

    my $user = $gitea->users->get('getty');

Fetches a user by login name. Returns a L<WWW::Gitea::User>.

=head2 search

    my $users = $gitea->users->search(q => 'tor', limit => 10);

Searches users. Accepts the Gitea query parameters (C<q>, C<uid>, C<page>,
C<limit>). Returns an ArrayRef of L<WWW::Gitea::User> objects.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::User>

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
