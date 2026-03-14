package WWW::Zitadel;

# ABSTRACT: Perl client for Zitadel identity management (OIDC + Management API)

use Moo;
use WWW::Zitadel::OIDC;
use WWW::Zitadel::Management;
use WWW::Zitadel::Error;
use namespace::clean;

our $VERSION = '0.001';

has issuer => (
    is       => 'ro',
    required => 1,
);

sub BUILD {
    my $self = shift;
    die WWW::Zitadel::Error::Validation->new(
        message => 'issuer must not be empty',
    ) unless length $self->issuer;
}

has token => (
    is  => 'ro',
    doc => 'Personal Access Token for Management API',
);

has oidc => (
    is      => 'lazy',
    builder => sub {
        WWW::Zitadel::OIDC->new(issuer => $_[0]->issuer);
    },
);

has management => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        die WWW::Zitadel::Error::Validation->new(
            message => 'Management API requires a token',
        ) unless $self->token;
        WWW::Zitadel::Management->new(
            base_url => $self->issuer,
            token    => $self->token,
        );
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Zitadel - Perl client for Zitadel identity management (OIDC + Management API)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::Zitadel;

    my $z = WWW::Zitadel->new(
        issuer => 'https://zitadel.example.com',
        token  => $ENV{ZITADEL_PAT},  # Personal Access Token
    );

    # OIDC - verify tokens, fetch JWKS
    my $claims = $z->oidc->verify_token($access_token);
    my $jwks   = $z->oidc->jwks;

    # Management API - CRUD users, projects, apps
    my $users = $z->management->list_users(limit => 20);
    my $user  = $z->management->create_human_user(
        user_name  => 'alice',
        first_name => 'Alice',
        last_name  => 'Smith',
        email      => 'alice@example.com',
    );

=head1 DESCRIPTION

WWW::Zitadel is a Perl client for Zitadel, the open-source identity management
platform. It provides:

=over 4

=item * B<OIDC Client> - Token verification via JWKS, discovery endpoint,
userinfo. Uses L<Crypt::JWT> for JWT validation.

=item * B<Management API Client> - CRUD operations for users, projects,
applications, and organizations.

=back

Zitadel speaks standard OpenID Connect, so the OIDC client works with
any OIDC-compliant provider. The Management API client is Zitadel-specific.

=head2 issuer

Required issuer URL, for example C<https://zitadel.example.com>.

=head2 token

Optional Personal Access Token (PAT). Required only when using
L</management>.

=head2 oidc

Lazy-built L<WWW::Zitadel::OIDC> client, configured with C<issuer>.

=head2 management

Lazy-built L<WWW::Zitadel::Management> client, configured with C<issuer>
as C<base_url>. Dies if C<token> is missing.

=head1 SEE ALSO

L<WWW::Zitadel::OIDC>, L<WWW::Zitadel::Management>, L<Crypt::JWT>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-zitadel/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
