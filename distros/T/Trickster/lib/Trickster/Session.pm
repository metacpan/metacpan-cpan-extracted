package Trickster::Session;

use strict;
use warnings;
use v5.14;

use JSON::PP qw(encode_json decode_json);
use Carp qw(croak);

sub new {
    my ($class, %opts) = @_;
    
    croak "cookie => Trickster::Cookie required" unless $opts{cookie};
    
    return bless {
        cookie     => $opts{cookie},
        name       => $opts{name}       || 'trick_session',
        max_age    => $opts{max_age},
        secure     => $opts{secure}     // 1,
        httponly   => $opts{httponly}   // 1,
        samesite   => $opts{samesite}   // 'Lax',
    }, $class;
}

sub get {
    my ($self, $req) = @_;
    
    my $raw = $self->{cookie}->get($req, $self->{name});
    return {} unless $raw;
    
    return eval { decode_json($raw) } || {};
}

sub set {
    my ($self, $res, $data) = @_;
    
    my $json = encode_json($data // {});
    
    $self->{cookie}->set(
        $res,
        $self->{name},
        $json,
        max_age  => $self->{max_age},
        secure   => $self->{secure},
        httponly => $self->{httponly},
        samesite => $self->{samesite},
    );
}

sub clear {
    my ($self, $res) = @_;
    
    $self->{cookie}->delete($res, $self->{name});
}

1;

__END__

=head1 NAME

Trickster::Session - Stateless signed-cookie sessions for Trickster

=head1 SYNOPSIS

    use Trickster::Session;
    use Trickster::Cookie;
    
    my $cookie = Trickster::Cookie->new(
        secret => $ENV{SESSION_SECRET} || die "SESSION_SECRET required",
    );
    
    my $session = Trickster::Session->new(
        cookie   => $cookie,
        name     => 'trick_session',
        max_age  => 3600,
        secure   => 1,
        httponly => 1,
        samesite => 'Lax',
    );
    
    # In your routes
    $app->get('/login', sub {
        my ($req, $res) = @_;
        
        # Authenticate user...
        
        $session->set($res, {
            user_id => 123,
            username => 'alice',
            role => 'admin',
        });
        
        return $res->json({ success => 1 });
    });
    
    $app->get('/profile', sub {
        my ($req, $res) = @_;
        
        my $data = $session->get($req);
        my $user_id = $data->{user_id};
        
        unless ($user_id) {
            return $res->json({ error => 'Not authenticated' }, 401);
        }
        
        return $res->json({ user_id => $user_id });
    });
    
    $app->post('/logout', sub {
        my ($req, $res) = @_;
        
        $session->clear($res);
        
        return $res->json({ success => 1 });
    });

=head1 DESCRIPTION

Trickster::Session provides stateless, signed-cookie based sessions that:

=over 4

=item * Work in production (prefork servers, load balancers)

=item * Survive server restarts

=item * Scale horizontally without shared storage

=item * Are cryptographically signed (tamper-proof)

=item * Store data client-side (no server memory)

=back

B<IMPORTANT:> This is NOT a middleware. Sessions are stateless and stored
in signed cookies. No server-side storage means no memory leaks, no
database queries, and perfect horizontal scaling.

=head1 WHY NOT MIDDLEWARE?

Traditional session middleware with in-memory storage (like the one we
almost shipped) has fatal flaws:

=over 4

=item * Breaks in prefork servers (Starman, uWSGI, Apache)

=item * Lost on server restart

=item * Doesn't scale horizontally

=item * Memory leaks with many sessions

=back

Stateless signed-cookie sessions solve all these problems.

=head1 METHODS

=head2 new(%options)

Creates a new session manager.

Required:

=over 4

=item * cookie - Trickster::Cookie instance with secret

=back

Optional:

=over 4

=item * name - Cookie name (default: 'trick_session')

=item * max_age - Session lifetime in seconds

=item * secure - Require HTTPS (default: 1)

=item * httponly - HttpOnly flag (default: 1)

=item * samesite - SameSite policy (default: 'Lax')

=back

=head2 get($req)

Retrieves session data from the request.

Returns a hash ref (empty if no session).

=head2 set($res, $data)

Stores session data in a signed cookie.

$data must be a hash ref that can be JSON-encoded.

=head2 clear($res)

Clears the session by deleting the cookie.

=head1 SECURITY

=over 4

=item * All session data is HMAC-signed

=item * Tampering is detected and rejected

=item * Use a strong random secret (32+ bytes)

=item * Rotate secrets periodically

=item * Enable secure flag in production (HTTPS)

=back

=head1 LIMITATIONS

=over 4

=item * Cookie size limit (~4KB)

=item * Session data is visible to client (base64-encoded)

=item * Don't store sensitive data (passwords, credit cards)

=item * Store only user ID and lookup details server-side

=back

=head1 BEST PRACTICES

    # Good: Store minimal data
    $session->set($res, {
        user_id => 123,
        role => 'admin',
    });
    
    # Bad: Store sensitive data
    $session->set($res, {
        password => 'secret',  # NEVER!
        credit_card => '...',  # NEVER!
    });
    
    # Good: Use environment variable for secret
    my $cookie = Trickster::Cookie->new(
        secret => $ENV{SESSION_SECRET} || die "SESSION_SECRET required",
    );
    
    # Bad: Hardcoded secret
    my $cookie = Trickster::Cookie->new(
        secret => 'my-secret',  # NEVER!
    );

=head1 SEE ALSO

L<Trickster::Cookie>, L<Trickster>

=cut
