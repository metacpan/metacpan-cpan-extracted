package Uniform::HTTP::Auth::Bearer;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.02';

sub validate_challenge {
    my ($class, $challenge) = @_;
    return 'Bearer challenge must not contain token68 credentials'
        if defined $challenge->{token68};
    return;
}

sub select_challenge {
    my ($class, $challenges) = @_;
    for my $challenge (@$challenges) {
        next if $challenge->{malformed};
        next if defined $class->validate_challenge($challenge);
        return $challenge;
    }
    return;
}

sub authorization {
    my ($class, %args) = @_;
    croak "Bearer authorization requires 'token'"
        unless exists($args{token}) && defined($args{token});
    croak "Bearer token must be a plain scalar" if ref $args{token};
    croak "malformed Bearer token"
        unless $args{token} =~ /\A[A-Za-z0-9\-._~+\/]+={0,}\z/;

    return 'Bearer ' . $args{token};
}

1;

__END__

=head1 NAME

Uniform::HTTP::Auth::Bearer - HTTP Bearer authentication construction

=head1 SYNOPSIS

    use Uniform::HTTP::Auth::Bearer;

    my $value = Uniform::HTTP::Auth::Bearer->authorization(
        token => $token,
    );

    # Bearer eyJ...

=head1 DESCRIPTION

C<Uniform::HTTP::Auth::Bearer> validates Bearer challenges and constructs
Bearer authentication field values according to RFC 6750.

The token is opaque to this module.  It does not decode JWTs, acquire or refresh
OAuth tokens, validate token expiry, or determine authorization policy.

Most applications will use it through L<Uniform::HTTP::Auth>.  The direct API is
available when a caller only needs Bearer field construction.

=head1 METHODS

=head2 validate_challenge

    my $error = Uniform::HTTP::Auth::Bearer->validate_challenge($challenge);

Returns undef for a structurally usable Bearer challenge or a diagnostic string
otherwise.  Challenge parameters such as C<realm>, C<scope>, C<error>,
C<error_description>, and C<error_uri> remain available in the parsed challenge
for callers and credential providers.

=head2 select_challenge

    my $challenge = Uniform::HTTP::Auth::Bearer->select_challenge(\@bearer);

Returns the first usable Bearer challenge in wire order, or undef.

=head2 authorization

    my $value = Uniform::HTTP::Auth::Bearer->authorization(
        token => $token,
    );

Validates the token against the Bearer C<b64token> syntax and returns the
complete field value beginning with C<Bearer >.

=head1 SECURITY NOTES

Bearer tokens are credentials: possession is normally sufficient to use them.
Callers are responsible for obtaining, storing, transmitting, refreshing, and
retiring tokens appropriately for their application and transport.

=head1 SEE ALSO

L<Uniform::HTTP::Auth>, RFC 6750.

=head1 AUTHOR

Joshua S. Day, E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is released under the MIT License.

=cut
