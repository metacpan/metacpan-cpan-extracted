package Uniform::HTTP::Auth::Basic;

use strict;
use warnings;
use Carp qw(croak);
use Encode qw(encode);
use MIME::Base64 qw(encode_base64);
use Unicode::Normalize qw(NFC);

our $VERSION = '0.02';

sub validate_challenge {
    my ($class, $challenge) = @_;
    return 'Basic challenge must use authentication parameters'
        if defined $challenge->{token68};
    return 'Basic challenge requires realm'
        unless exists $challenge->{params}{realm};

    if (exists $challenge->{params}{charset}
        && lc($challenge->{params}{charset}) ne 'utf-8') {
        return 'Basic charset must be UTF-8';
    }

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

    for my $field (qw(username password challenge)) {
        croak "Basic authorization requires '$field'"
            unless exists $args{$field} && defined $args{$field};
    }
    croak "username must be a plain scalar" if ref $args{username};
    croak "password must be a plain scalar" if ref $args{password};
    croak "challenge must be a hash reference"
        unless ref($args{challenge}) eq 'HASH';

    my $error = $class->validate_challenge($args{challenge});
    croak $error if defined $error;

    croak "Basic username must not contain ':'"
        if $args{username} =~ /:/;
    croak "Basic username contains an HTTP control character"
        if $args{username} =~ /[\x00-\x1f\x7f]/;
    croak "Basic password contains an HTTP control character"
        if $args{password} =~ /[\x00-\x1f\x7f]/;

    my ($username, $password) = @args{qw(username password)};
    my $charset = $args{challenge}{params}{charset};
    my $bytes;

    if (defined $charset) {
        $username = NFC($username);
        $password = NFC($password);
        $bytes = encode('UTF-8', $username . ':' . $password, Encode::FB_CROAK());
    }
    else {
        croak 'non-ASCII Basic credentials require a charset="UTF-8" challenge'
            if $username =~ /[^\x00-\x7f]/ || $password =~ /[^\x00-\x7f]/;
        $bytes = $username . ':' . $password;
    }

    return 'Basic ' . encode_base64($bytes, '');
}

1;

__END__

=head1 NAME

Uniform::HTTP::Auth::Basic - HTTP Basic authentication construction

=head1 SYNOPSIS

    use Uniform::HTTP::Auth;
    use Uniform::HTTP::Auth::Basic;

    my $auth = Uniform::HTTP::Auth->new;
    my $challenge = $auth->parse_challenges(
        'Basic realm="Members", charset="UTF-8"'
    )->[0];

    my $value = Uniform::HTTP::Auth::Basic->authorization(
        username  => 'user',
        password  => 'secret',
        challenge => $challenge,
    );

    # Basic dXNlcjpzZWNyZXQ=

=head1 DESCRIPTION

C<Uniform::HTTP::Auth::Basic> validates Basic challenges and constructs Basic
authentication field values according to RFC 7617.  It contains no HTTP client,
server, retry, or framework behavior.

Most applications will use it through L<Uniform::HTTP::Auth>.  The direct API is
available when a caller only needs Basic mechanics.

=head1 METHODS

=head2 validate_challenge

    my $error = Uniform::HTTP::Auth::Basic->validate_challenge($challenge);

Returns undef for a structurally usable Basic challenge or a diagnostic string
otherwise.  A realm is required.  If C<charset> is present, the only supported
value is C<UTF-8>, matched case-insensitively.

Unknown Basic challenge parameters are preserved by the root parser and ignored
by the Basic calculation.

=head2 select_challenge

    my $challenge = Uniform::HTTP::Auth::Basic->select_challenge(\@basic);

Returns the first usable Basic challenge in wire order, or undef.

=head2 authorization

    my $value = Uniform::HTTP::Auth::Basic->authorization(
        username  => $username,
        password  => $password,
        challenge => $challenge,
    );

Returns the complete field value beginning with C<Basic >.

The username may not contain a colon, and neither username nor password may
contain HTTP control characters.

When the challenge contains C<charset="UTF-8">, username and password are
normalized to NFC and encoded as UTF-8 before Base64 encoding.

RFC 7617 leaves the default encoding undefined when C<charset> is absent.
Version 0.01 therefore accepts ASCII credentials only in that case rather than
silently guessing an encoding.

=head1 SECURITY NOTES

Basic authentication does not encrypt credentials; Base64 is only an encoding.
Use a secure transport such as TLS when the credentials are sensitive.

=head1 SEE ALSO

L<Uniform::HTTP::Auth>, RFC 7617.

=head1 AUTHOR

Joshua S. Day, E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is released under the MIT License.

=cut
